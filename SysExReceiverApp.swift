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

// MARK: - SysEx Parsing Helpers

/// Extract raw 7-bit SysEx data bytes from a MIDI 1.0 SysEx7 Universal MIDI Packet sequence.
/// This example is intentionally simple and focuses on "SysEx 7" messages (message type 0x3).
/// Each 32-bit word has:
/// - bits 31–28: Message Type (0x3 = SysEx 7)
/// - bits 27–24: Group
/// - bits 23–20: Status/flags (including start/continue/end bits)
/// - bits 19–16: Byte count (0–6 bytes in this word)
/// - bits 15–0 : Up to 6 data bytes, 7-bit each, packed as 6 x 7 bits.
/// For clarity, we just hex-dump the raw 7-bit values that appear in the payload.
func extractSysEx7Bytes(from message: MIDIUniversalMessage) -> [UInt8]? {
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
    // Only handle SysEx7 (message type 0x3)
    guard msgType == 0x3 else {
        return nil
    }

    // For a real implementation you would assemble full SysEx across multiple packets
    // using the status/flags in the first word. For simplicity, this sample assumes
    // each UMP represents a self-contained chunk and just hex-dumps the data bytes
    // in this 128-bit message.

    // Decode a single 32-bit word into data bytes.
    func decodeWord(_ word: UInt32) -> [UInt8] {
        let numBytes = Int((word >> 16) & 0xF) // number of valid 7-bit bytes (0–6)
        var bytes: [UInt8] = []
        var shift = 0
        for _ in 0..<numBytes {
            let b = UInt8((word >> shift) & 0x7F)
            bytes.append(b)
            shift += 8 // In practice SysEx7 packs 7-bit bytes; we keep it simple here.
        }
        return bytes
    }

    var allBytes: [UInt8] = []
    allBytes.append(contentsOf: decodeWord(w0))
    allBytes.append(contentsOf: decodeWord(w1))
    allBytes.append(contentsOf: decodeWord(w2))
    allBytes.append(contentsOf: decodeWord(w3))

    return allBytes
}

// MARK: - MIDI Manager for SysEx Receiver

/// Manages CoreMIDI setup for receiving MIDI SysEx and logging the data payloads.
final class SysExMIDIManager: ObservableObject {

    // MARK: Published UI-facing properties

    /// Log of raw SysEx payloads as hex strings
    @Published var sysExLog: [String] = []

    /// Status text (errors, setup status, etc.)
    @Published var statusMessage: String = "Waiting for SysEx..."

    private let maxLogEntries = 200

    // MARK: CoreMIDI handles

    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var virtualDestination = MIDIEndpointRef()

    init() {
        setUpMIDI()
    }

    deinit {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
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

        // Create MIDI client with notification callback (for hot-plug)
        var newClient = MIDIClientRef()
        let clientStatus = MIDIClientCreateWithBlock("SysExReceiverClient" as CFString,
                                                     &newClient) { [weak self] _ in
            // You could update UI based on device changes here
            DispatchQueue.main.async {
                self?.statusMessage = "MIDI system changed – still listening for SysEx."
            }
        }

        guard clientStatus == noErr else {
            statusMessage = "Failed to create MIDI client: \(clientStatus)"
            return
        }

        client = newClient

        // Create input port with MIDI 1.0 protocol (modern API)
        var newInputPort = MIDIPortRef()
        let inStatus = MIDIInputPortCreateWithProtocol(
            client,
            "SysExInputPort" as CFString,
            ._1_0,
            &newInputPort
        ) { [weak self] eventListPtr, srcConnRefCon in
            guard let self, let eventListPtr else { return }
            let label: String
            if let refCon = srcConnRefCon {
                label = "Source \(refCon)"
            } else {
                label = "Input"
            }
            self.handleIncomingEventList(eventListPtr, sourceLabel: label)
        }

        guard inStatus == noErr else {
            statusMessage = "Failed to create MIDI input port: \(inStatus)"
            return
        }

        inputPort = newInputPort

        // Connect input port to all current sources (physical MIDI inputs, virtual sources, etc.)
        connectInputPortToAllSources()

        // Create a virtual MIDI destination so other apps can send SysEx directly to this app
        var newVirtualDestination = MIDIEndpointRef()
        let destStatus = MIDIDestinationCreateWithProtocol(
            client,
            "SysExReceiver In" as CFString,
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

        statusMessage = "Listening for SysEx on all MIDI sources and virtual destination."
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

    // MARK: - Handling incoming MIDI

    private func handleIncomingEventList(_ list: UnsafePointer<MIDIEventList>, sourceLabel: String) {
        var newLines: [String] = []

        MIDIEventListForEachSwift(list) { [weak self] message, timeStamp in
            guard let self else { return }

            if let bytes = extractSysEx7Bytes(from: message), !bytes.isEmpty {
                let hexString = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                let line = "[\(sourceLabel)] t=\(timeStamp) SysEx: \(hexString)"
                newLines.append(line)
            } else {
                // For non-SysEx messages, you could log or ignore.
                // We ignore them here to keep the view focused on SysEx only.
            }
        }

        if !newLines.isEmpty {
            DispatchQueue.main.async {
                self.appendToLog(newLines)
            }
        }
    }

    /// Append lines to the SysEx log and trim to a maximum count.
    private func appendToLog(_ lines: [String]) {
        sysExLog.append(contentsOf: lines)
        if sysExLog.count > maxLogEntries {
            sysExLog.removeFirst(sysExLog.count - maxLogEntries)
        }
    }

    /// Clear the current log.
    func clearLog() {
        sysExLog.removeAll()
    }
}

// MARK: - SwiftUI UI

struct SysExContentView: View {
    @EnvironmentObject var midiManager: SysExMIDIManager

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                Text(midiManager.statusMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if midiManager.sysExLog.isEmpty {
                            Text("No SysEx messages received yet.\n\nSend a SysEx dump from a connected device or another app that targets this app's virtual MIDI destination \"SysExReceiver In\".")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                                .padding()
                        } else {
                            ForEach(midiManager.sysExLog.reversed(), id: \.self) { line in
                                Text(line)
                                    .font(.system(.footnote, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Clear Log") {
                        midiManager.clearLog()
                    }
                    .padding()
                }
            }
            .navigationTitle("SysEx Receiver")
        }
    }
}

// MARK: - App Entry Point

@main
struct SysExReceiverApp: App {
    @StateObject private var midiManager = SysExMIDIManager()

    var body: some Scene {
        WindowGroup {
            SysExContentView()
                .environmentObject(midiManager)
        }
    }
}
