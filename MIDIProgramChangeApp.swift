import SwiftUI
import CoreMIDI

// MARK: - MIDI Event List Helper (Swift wrapper around MIDIEventListForEachEvent)

/// A Swift-friendly callback type that is invoked for every MIDI Universal Message
/// inside a `MIDIEventList`.
typealias MIDIForEachBlock = (MIDIUniversalMessage, MIDITimeStamp) -> Void

/// Internal context object so we can bridge a Swift closure through the C callback.
private final class MIDIForEachContext {
    let block: MIDIForEachBlock

    init(block: @escaping MIDIForEachBlock) {
        self.block = block
    }
}

/// Iterate all events in a `MIDIEventList` and invoke a Swift closure for each `MIDIUniversalMessage`.
func MIDIEventListForEachSwift(_ list: UnsafePointer<MIDIEventList>, _ block: @escaping MIDIForEachBlock) {
    withoutActuallyEscaping(block) { escaping in
        let context = MIDIForEachContext(block: escaping)
        withExtendedLifetime(context) {
            let contextPointer = Unmanaged.passUnretained(context).toOpaque()

            MIDIEventListForEachEvent(list, { rawContext, timeStamp, msgPtr in
                guard let rawContext, let msgPtr else { return }
                let context = Unmanaged<MIDIForEachContext>
                    .fromOpaque(rawContext)
                    .takeUnretainedValue()
                context.block(msgPtr.pointee, timeStamp)
            }, contextPointer)
        }
    }
}

// MARK: - MIDI Manager

/// Manages CoreMIDI setup and sending Program Change / Bank Select,
/// and parses incoming MIDI events into human‑readable log entries.
final class MIDIManager: ObservableObject {

    // MARK: Published properties (for SwiftUI)

    /// Available hardware MIDI destinations
    @Published var destinations: [MIDIEndpointRef] = []

    /// Currently selected destination
    @Published var selectedDestination: MIDIEndpointRef?

    /// User-facing channel number (1–16)
    @Published var channel: Int = 1

    /// Program number (0–127; devices may display 1–128)
    @Published var program: Int = 0

    /// Optional Bank Select MSB (0–127)
    @Published var bankMSB: Int = 0

    /// Optional Bank Select LSB (0–127)
    @Published var bankLSB: Int = 0

    /// Whether to send Bank Select (CC 0 / 32) before the Program Change
    @Published var sendBankSelect: Bool = false

    /// Status message for the UI
    @Published var statusMessage: String = "Ready."

    /// Log of received MIDI events as human-readable strings
    @Published var receivedLog: [String] = []

    private let maxLogEntries = 200

    // MARK: - CoreMIDI handles

    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var outputPort = MIDIPortRef()
    private var virtualDestination = MIDIEndpointRef()

    init() {
        setUpMIDI()
    }

    deinit {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if outputPort != 0 {
            MIDIPortDispose(outputPort)
        }
        if virtualDestination != 0 {
            MIDIEndpointDispose(virtualDestination)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }

    // MARK: - Setup

    private func setUpMIDI() {
        #if os(iOS)
        guard #available(iOS 15.0, *) else {
            statusMessage = "Requires iOS 15 or later."
            return
        }
        #elseif os(macOS)
        guard #available(macOS 12.0, *) else {
            statusMessage = "Requires macOS 12 or later."
            return
        }
        #endif

        // Create MIDI client (with notification block for hot-plug events)
        var newClient = MIDIClientRef()
        let clientStatus = MIDIClientCreateWithBlock("ProgramChangeClient" as CFString,
                                                     &newClient) { [weak self] _ in
            // Refresh destinations on any system change
            DispatchQueue.main.async {
                self?.refreshDestinations()
            }
        }

        guard clientStatus == noErr else {
            statusMessage = "Failed to create MIDI client: \(clientStatus)"
            return
        }

        client = newClient

        // Create input port with MIDI 1.0 protocol using modern API
        var newInputPort = MIDIPortRef()
        let inStatus = MIDIInputPortCreateWithProtocol(
            client,
            "InputPort" as CFString,
            ._1_0,
            &newInputPort
        ) { [weak self] eventListPtr, srcConnRefCon in
            guard let self, let eventListPtr else { return }
            let sourceLabel: String
            if let refCon = srcConnRefCon {
                sourceLabel = "Source \(refCon)"
            } else {
                sourceLabel = "Input"
            }
            self.handleIncomingEventList(eventListPtr, sourceLabel: sourceLabel)
        }

        guard inStatus == noErr else {
            statusMessage = "Failed to create MIDI input port: \(inStatus)"
            return
        }

        inputPort = newInputPort

        // Create a virtual MIDI destination with MIDI 1.0 protocol
        var newVirtualDestination = MIDIEndpointRef()
        let destStatus = MIDIDestinationCreateWithProtocol(
            client,
            "ProgramChangeApp In" as CFString,
            ._1_0,
            &newVirtualDestination
        ) { [weak self] eventListPtr, _ in
            guard let self, let eventListPtr else { return }
            self.handleIncomingEventList(eventListPtr, sourceLabel: "Virtual In")
        }

        guard destStatus == noErr else {
            statusMessage = "Failed to create virtual destination: \(destStatus)"
            return
        }

        virtualDestination = newVirtualDestination

        // Connect input port to all current sources (for monitoring)
        connectInputPortToAllSources()

        // Create output port (modern, non-deprecated)
        var newOutputPort = MIDIPortRef()
        let outStatus = MIDIOutputPortCreate(
            client,
            "OutputPort" as CFString,
            &newOutputPort
        )

        guard outStatus == noErr else {
            statusMessage = "Failed to create MIDI output port: \(outStatus)"
            return
        }

        outputPort = newOutputPort

        // Discover initial destinations
        refreshDestinations()
    }

    private func connectInputPortToAllSources() {
        let sourceCount = MIDIGetNumberOfSources()
        for index in 0..<sourceCount {
            let src = MIDIGetSource(index)
            if src != 0 {
                MIDIPortConnectSource(inputPort, src, nil)
            }
        }
    }

    // MARK: - Destination management

    func refreshDestinations() {
        var newDestinations: [MIDIEndpointRef] = []
        let count = MIDIGetNumberOfDestinations()
        for index in 0..<count {
            let dest = MIDIGetDestination(index)
            if dest != 0 {
                newDestinations.append(dest)
            }
        }

        DispatchQueue.main.async {
            self.destinations = newDestinations
            if !newDestinations.contains(where: { $0 == self.selectedDestination }) {
                self.selectedDestination = newDestinations.first
            }

            self.statusMessage = newDestinations.isEmpty
                ? "No MIDI destinations available."
                : "Found \(newDestinations.count) MIDI destination(s)."
        }
    }

    func name(for endpoint: MIDIEndpointRef) -> String {
        var property: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &property)
        if status == noErr,
           let cfStr = property?.takeRetainedValue() {
            return cfStr as String
        } else {
            return "Destination \(endpoint)"
        }
    }

    // MARK: - Sending UMP helpers

    /// Build a single 32-bit Universal MIDI Packet word for a **MIDI 1.0 Program Change**
    ///
    /// UMP 1-word format for MIDI 1.0 Channel Voice messages:
    /// - bits 31–28: Message Type (0x2 = MIDI 1.0 Channel Voice)
    /// - bits 27–24: Group (0–15)
    /// - bits 23–20: Status upper nibble (0xC for Program Change)
    /// - bits 19–16: Channel (0–15)
    /// - bits 15–8: Data1 (program number 0–127)
    /// - bits 7–0: Data2 (unused for Program Change)
    private func makeProgramChangeUMP(group: UInt8 = 0,
                                      channel: UInt8,
                                      program: UInt8) -> UInt32 {
        let messageType: UInt32 = 0x2 << 28
        let groupBits = UInt32(group & 0x0F) << 24
        let statusNibble: UInt32 = 0xC << 20
        let channelBits = UInt32(channel & 0x0F) << 16
        let data1 = UInt32(program & 0x7F) << 8
        let data2: UInt32 = 0

        return messageType | groupBits | statusNibble | channelBits | data1 | data2
    }

    /// Build a single 32-bit Universal MIDI Packet word for a **MIDI 1.0 Control Change**
    ///
    /// - bits 31–28: 0x2 (MIDI 1.0 Channel Voice)
    /// - bits 27–24: Group
    /// - bits 23–20: 0xB (Control Change)
    /// - bits 19–16: Channel
    /// - bits 15–8: Data1 (controller number)
    /// - bits 7–0: Data2 (controller value)
    private func makeControlChangeUMP(group: UInt8 = 0,
                                      channel: UInt8,
                                      controller: UInt8,
                                      value: UInt8) -> UInt32 {
        let messageType: UInt32 = 0x2 << 28
        let groupBits = UInt32(group & 0x0F) << 24
        let statusNibble: UInt32 = 0xB << 20
        let channelBits = UInt32(channel & 0x0F) << 16
        let data1 = UInt32(controller & 0x7F) << 8
        let data2 = UInt32(value & 0x7F)

        return messageType | groupBits | statusNibble | channelBits | data1 | data2
    }

    // MARK: - Sending Program Change (+ optional Bank Select)

    /// Sends a MIDI 1.0 Program Change (and optional Bank Select MSB/LSB)
    /// to the selected destination using MIDIEventList + MIDISendEventList.
    func sendProgramChange() {
        guard let destination = selectedDestination else {
            statusMessage = "No destination selected."
            return
        }

        // Clamp values for safety
        let chan = UInt8(max(1, min(channel, 16)) - 1)     // 0–15
        let prog = UInt8(max(0, min(program, 127)))        // 0–127
        let msb = UInt8(max(0, min(bankMSB, 127)))
        let lsb = UInt8(max(0, min(bankLSB, 127)))

        // Build UMP words: optional Bank Select (CC 0 / CC 32) then Program Change
        var words: [UInt32] = []

        if sendBankSelect {
            let cc0 = makeControlChangeUMP(channel: chan, controller: 0, value: msb)
            let cc32 = makeControlChangeUMP(channel: chan, controller: 32, value: lsb)
            words.append(cc0)
            words.append(cc32)
        }

        let pc = makeProgramChangeUMP(channel: chan, program: prog)
        words.append(pc)

        // Prepare a MIDIEventList on the stack
        var eventList = MIDIEventList()

        // Initialize list for MIDI 1.0 protocol and add all words as one packet
        words.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            var firstPacket: UnsafeMutablePointer<MIDIEventPacket>?

            firstPacket = withUnsafeMutablePointer(to: &eventList) { listPtr in
                MIDIEventListInit(listPtr, ._1_0)
            }

            guard let packetPtr = firstPacket else { return }

            _ = withUnsafeMutablePointer(to: &eventList) { listPtr in
                MIDIEventListAdd(
                    listPtr,
                    MemoryLayout.size(ofValue: eventList),
                    packetPtr,
                    0, // timestamp: 0 = send immediately
                    buffer.count,
                    baseAddress
                )
            }
        }

        // Send the event list out the output port to the selected destination
        let sendStatus = MIDISendEventList(outputPort, destination, &eventList)

        if sendStatus == noErr {
            if sendBankSelect {
                statusMessage = "Sent Bank MSB \(msb), LSB \(lsb), Program \(prog) on channel \(chan + 1)."
            } else {
                statusMessage = "Sent Program \(prog) on channel \(chan + 1)."
            }
        } else {
            statusMessage = "Error sending MIDI: \(sendStatus)"
        }
    }

    // MARK: - Incoming MIDI parsing and logging

    /// Handle a pointer to a `MIDIEventList` by decoding each UMP into
    /// a human‑readable string and adding it to the log.
    private func handleIncomingEventList(_ list: UnsafePointer<MIDIEventList>, sourceLabel: String) {
        var newLines: [String] = []

        MIDIEventListForEachSwift(list) { [weak self] message, timeStamp in
            guard let self else { return }
            let description = self.describeUMP(message)
            let line = "[\(sourceLabel)] t=\(timeStamp): \(description)"
            newLines.append(line)
        }

        if !newLines.isEmpty {
            DispatchQueue.main.async {
                self.appendToLog(newLines)
            }
        }
    }

    /// Append new entries to the log, trimming to a maximum size.
    private func appendToLog(_ lines: [String]) {
        receivedLog.append(contentsOf: lines)
        if receivedLog.count > maxLogEntries {
            receivedLog.removeFirst(receivedLog.count - maxLogEntries)
        }
    }

    /// Decode a 128‑bit UMP (`MIDIUniversalMessage`) into a human‑oriented description.
    /// We do this generically by treating the message as four 32‑bit words and
    /// decoding the first word using the MIDI 1.0 Channel Voice UMP layout when applicable.
    private func describeUMP(_ message: MIDIUniversalMessage) -> String {
        var copy = message
        var w0: UInt32 = 0
        var w1: UInt32 = 0
        var w2: UInt32 = 0
        var w3: UInt32 = 0

        withUnsafePointer(to: &copy) { ptr in
            ptr.withMemoryRebound(to: UInt32.self, capacity: 4) { words in
                w0 = words[0]
                w1 = words[1]
                w2 = words[2]
                w3 = words[3]
            }
        }

        let msgType = (w0 >> 28) & 0xF
        let group = (w0 >> 24) & 0xF

        // Only decode MIDI 1.0 Channel Voice messages (type 0x2) in detail
        if msgType == 0x2 {
            let status = (w0 >> 20) & 0xF
            let channel = (w0 >> 16) & 0xF
            let data1 = (w0 >> 8) & 0xFF
            let data2 = w0 & 0xFF

            switch status {
            case 0x8:
                return String(format: "Note Off ch %d note %d vel %d (grp %d)",
                              channel + 1, data1, data2, group)
            case 0x9:
                return String(format: "Note On ch %d note %d vel %d (grp %d)",
                              channel + 1, data1, data2, group)
            case 0xB:
                return String(format: "Control Change ch %d CC %d = %d (grp %d)",
                              channel + 1, data1, data2, group)
            case 0xC:
                return String(format: "Program Change ch %d program %d (grp %d)",
                              channel + 1, data1, group)
            case 0xE:
                // Pitch bend: 14‑bit value across data1/data2
                let value = Int((data2 << 7) | (data1 & 0x7F))
                return String(format: "Pitch Bend ch %d value %d (grp %d)",
                              channel + 1, value, group)
            default:
                return String(format: "MIDI 1.0 CV msgType=0x%X status=0x%X ch=%d data1=%d data2=%d (grp %d)",
                              msgType, status, channel + 1, data1, data2, group)
            }
        } else {
            // Generic hex dump for other message types (MIDI 2.0 etc.)
            return String(format: "UMP type=0x%X group=%d w0=%08X w1=%08X w2=%08X w3=%08X",
                          msgType, group, w0, w1, w2, w3)
        }
    }
}

// MARK: - SwiftUI UI

struct ContentView: View {
    @EnvironmentObject var midiManager: MIDIManager

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("MIDI Destination")) {
                    if midiManager.destinations.isEmpty {
                        Text("No MIDI destinations found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Destination", selection: $midiManager.selectedDestination) {
                            ForEach(midiManager.destinations, id: \.self) { endpoint in
                                Text(midiManager.name(for: endpoint))
                                    .tag(Optional(endpoint))
                            }
                        }
                    }

                    Button("Rescan Destinations") {
                        midiManager.refreshDestinations()
                    }
                }

                Section(header: Text("Channel & Program")) {
                    Stepper(
                        value: $midiManager.channel,
                        in: 1...16
                    ) {
                        Text("Channel: \(midiManager.channel)")
                    }

                    Stepper(
                        value: $midiManager.program,
                        in: 0...127
                    ) {
                        Text("Program: \(midiManager.program)")
                    }
                }

                Section(header: Text("Bank Select (optional)")) {
                    Toggle("Send Bank Select (CC 0 / 32)", isOn: $midiManager.sendBankSelect)

                    Stepper(
                        value: $midiManager.bankMSB,
                        in: 0...127
                    ) {
                        Text("Bank MSB (CC 0): \(midiManager.bankMSB)")
                    }
                    .disabled(!midiManager.sendBankSelect)

                    Stepper(
                        value: $midiManager.bankLSB,
                        in: 0...127
                    ) {
                        Text("Bank LSB (CC 32): \(midiManager.bankLSB)")
                    }
                    .disabled(!midiManager.sendBankSelect)
                }

                Section {
                    Button(action: midiManager.sendProgramChange) {
                        Text("Send Program Change")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(midiManager.selectedDestination == nil)
                }

                Section(header: Text("Status")) {
                    Text(midiManager.statusMessage)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                }

                Section(header: Text("Received Events Log")) {
                    if midiManager.receivedLog.isEmpty {
                        Text("No MIDI events received yet.")
                            .foregroundColor(.secondary)
                    } else {
                        // Show most recent first
                        ForEach(midiManager.receivedLog.reversed(), id: \.self) { line in
                            Text(line)
                                .font(.footnote)
                                .lineLimit(nil)
                        }
                    }
                }
            }
            .navigationTitle("MIDI Program Change")
        }
    }
}

// MARK: - App Entry Point

@main
struct ProgramChangeApp: App {
    @StateObject private var midiManager = MIDIManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(midiManager)
        }
    }
}
