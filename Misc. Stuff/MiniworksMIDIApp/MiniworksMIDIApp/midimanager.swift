//
//  MIDIManager.swift
//  MiniWorksMIDI
//
//  Complete CoreMIDI client with extensive educational comments explaining
//  how MIDI works at a fundamental level.
//
//  ═══════════════════════════════════════════════════════════════════════
//  WHAT IS MIDI?
//  ═══════════════════════════════════════════════════════════════════════
//
//  MIDI (Musical Instrument Digital Interface) is a protocol that lets
//  electronic musical instruments, computers, and other equipment communicate.
//  Think of it like a "language" that music devices use to talk to each other.
//
//  MIDI does NOT transmit audio/sound! Instead it transmits INSTRUCTIONS:
//  - "Play middle C with medium velocity"
//  - "Turn the filter cutoff knob to 50%"
//  - "Here's a complete synthesizer program with all settings"
//
//  Your computer then interprets these instructions and generates sound.
//
//  ═══════════════════════════════════════════════════════════════════════
//  MIDI MESSAGE TYPES
//  ═══════════════════════════════════════════════════════════════════════
//
//  1. CHANNEL MESSAGES (Real-time performance)
//     - Note On/Off: Play and release notes
//     - Control Change (CC): Adjust knobs/sliders (cutoff, volume, etc.)
//     - Program Change: Switch to a different preset/patch
//     - Pitch Bend: Bend notes up or down
//
//  2. SYSTEM EXCLUSIVE (SysEx) - Complete data dumps
//     - Transfer entire programs/patches
//     - Configure device settings
//     - Request/send bulk data
//     - Each manufacturer has their own format
//
//  3. SYSTEM COMMON/REAL-TIME
//     - Song position, timing clock, start/stop playback
//     - We don't use these for synthesizer control
//
//  ═══════════════════════════════════════════════════════════════════════
//  HOW SYSEX WORKS
//  ═══════════════════════════════════════════════════════════════════════
//
//  SysEx messages are like "letters" between devices. Structure:
//
//  F0                    - "Start of message" (like an envelope)
//  3E                    - Manufacturer ID (Waldorf = 0x3E)
//  04                    - Device ID (MiniWorks = 0x04)
//  00                    - Command (0x00 = Program Dump)
//  <program number>      - Which preset slot
//  <data bytes...>       - All the parameter values
//  <checksum>            - Error detection byte
//  F7                    - "End of message" (seal the envelope)
//
//  Why use SysEx instead of CC?
//  - Transfer entire programs in one message (faster than 30+ CC messages)
//  - Save programs to disk and reload them later
//  - Backup all synthesizer data
//  - Load factory presets
//
//  ═══════════════════════════════════════════════════════════════════════
//  COREMIDI ARCHITECTURE
//  ═══════════════════════════════════════════════════════════════════════
//
//  CoreMIDI is Apple's framework for MIDI communication. It uses a
//  connection-based model:
//
//  1. CLIENT - Your app (MiniWorksMIDI)
//     Creates ports for communication
//
//  2. PORTS - Connections for input/output
//     - Input Port: Receives messages FROM devices
//     - Output Port: Sends messages TO devices
//
//  3. ENDPOINTS - Physical or virtual MIDI devices
//     - Sources: Devices that send MIDI (keyboards, controllers)
//     - Destinations: Devices that receive MIDI (synthesizers, sound modules)
//
//  4. PACKETS - Individual messages
//     MIDI data is packaged into "packets" that contain:
//     - Timestamp (when to process the message)
//     - Data bytes (the actual MIDI message)
//
//  Flow: Device → Source Endpoint → Input Port → Your App → Output Port → Destination Endpoint → Device
//
//  ═══════════════════════════════════════════════════════════════════════
//  SYSEX FRAGMENTATION
//  ═══════════════════════════════════════════════════════════════════════
//
//  Sometimes a SysEx message is too large to fit in one MIDI packet.
//  CoreMIDI will "fragment" it across multiple packets:
//
//  Packet 1: F0 3E 04 00 05 10 20 30 40 50 60 70 ...
//  Packet 2: ... 80 90 A0 B0 C0 D0 E0 ...
//  Packet 3: ... F0 75 F7
//
//  This manager automatically buffers incoming bytes until it sees F7 (end),
//  then processes the complete message. This is called "reassembly".
//

import CoreMIDI
import Foundation
import Combine


@MainActor
class MIDIManager: ObservableObject {
    // MARK: - Published State
    
    /// All available MIDI sources (devices that send TO us)
    @Published var sources: [MIDIEndpointInfo] = []
    
    /// All available MIDI destinations (devices we send TO)
    @Published var destinations: [MIDIEndpointInfo] = []
    
    /// The currently selected input device
    @Published var selectedSource: MIDIEndpointInfo?
    
    /// The currently selected output device
    @Published var selectedDestination: MIDIEndpointInfo?
    
    /// Which checksum algorithm to use (see Utils.swift for explanation)
    @Published var checksumMode: ChecksumMode = .mask7
    
    /// Log of all MIDI traffic for debugging
    @Published var logMessages: [LogMessage] = []
    
    /// Whether we're actively receiving MIDI
    @Published var isConnected = false
    
    /// Current MIDI channel (1-16, though we mostly use SysEx which is channel-independent)
    @Published var midiChannel: UInt8 = 1
    
    // MARK: - CoreMIDI Objects
    
    /// Our MIDI client handle - represents this app in the MIDI system
    private var midiClient = MIDIClientRef()
    
    /// Port for receiving MIDI messages
    private var inputPort = MIDIPortRef()
    
    /// Port for sending MIDI messages
    private var outputPort = MIDIPortRef()
    
    // MARK: - SysEx Buffer
    
    /// Accumulates SysEx bytes until complete message received
    /// This handles fragmented SysEx across multiple packets
    private var sysexBuffer: [UInt8] = []
    
    /// Are we currently in the middle of receiving a SysEx message?
    private var isReceivingSysEx = false
    
    // MARK: - Types
    
    /// Information about a MIDI endpoint (source or destination)
    struct MIDIEndpointInfo: Identifiable, Hashable {
        let id: MIDIEndpointRef  // CoreMIDI's handle for this device
        let name: String          // Human-readable name
        let isInput: Bool         // Is this an input source or output destination?
    }
    
    /// A log entry for displaying MIDI traffic
    struct LogMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let direction: Direction
        let message: String
        
        enum Direction {
            case sent      // We sent this message
            case received  // We received this message
            case error     // Something went wrong
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupMIDI()
        refreshEndpoints()
    }
    
    deinit {
        // Clean up CoreMIDI resources when app closes
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }
    }
    
    // MARK: - Setup
    
    /// Create the MIDI client and ports
    ///
    /// This is called once when the app launches. It:
    /// 1. Creates a MIDI client (identifies us to the system)
    /// 2. Creates an input port (for receiving messages)
    /// 3. Creates an output port (for sending messages)
    private func setupMIDI() {
        let clientName = "MiniWorksMIDI" as CFString
        
        // Create the MIDI client
        // This registers our app with the MIDI system
        let status = MIDIClientCreate(clientName, nil, nil, &midiClient)
        
        guard status == noErr else {
            log("Failed to create MIDI client: \(status)", direction: .error)
            return
        }
        
        // Create INPUT port for RECEIVING messages
        // The closure is called whenever MIDI data arrives
        let inputPortName = "Input" as CFString
        MIDIInputPortCreateWithProtocol(
            midiClient,
            inputPortName,
            ._1_0,  // Use MIDI 1.0 protocol (standard, compatible with all hardware)
            &inputPort
        ) { [weak self] eventList, _ in
            // This closure runs on a background thread when MIDI arrives
            // We dispatch to main thread to update UI safely
            Task { @MainActor in
                self?.handleMIDIEvents(eventList)
            }
        }
        
        // Create OUTPUT port for SENDING messages
        let outputPortName = "Output" as CFString
        MIDIOutputPortCreate(midiClient, outputPortName, &outputPort)
        
        log("MIDI client initialized", direction: .received)
    }
    
    /// Scan the system for all available MIDI devices
    ///
    /// This discovers:
    /// - Hardware MIDI interfaces
    /// - Virtual MIDI devices (created by other apps)
    /// - Network MIDI sessions
    func refreshEndpoints() {
        // SOURCES: Devices that send MIDI TO us (keyboards, controllers)
        let sourceCount = MIDIGetNumberOfSources()
        sources = (0..<sourceCount).compactMap { i in
            let endpoint = MIDIGetSource(i)
            guard let name = getEndpointName(endpoint) else { return nil }
            return MIDIEndpointInfo(id: endpoint, name: name, isInput: true)
        }
        
        // DESTINATIONS: Devices that receive MIDI FROM us (synthesizers, sound modules)
        let destCount = MIDIGetNumberOfDestinations()
        destinations = (0..<destCount).compactMap { i in
            let endpoint = MIDIGetDestination(i)
            guard let name = getEndpointName(endpoint) else { return nil }
            return MIDIEndpointInfo(id: endpoint, name: name, isInput: false)
        }
        
        log("Found \(sources.count) sources, \(destinations.count) destinations", direction: .received)
    }
    
    /// Get the human-readable name of a MIDI endpoint
    private func getEndpointName(_ endpoint: MIDIEndpointRef) -> String? {
        var name: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
        guard status == noErr, let cfName = name?.takeRetainedValue() else {
            return nil
        }
        return cfName as String
    }
    
    // MARK: - Connection Management
    
    /// Connect to the selected MIDI source to start receiving messages
    func connect() {
        guard let source = selectedSource else {
            log("No source selected", direction: .error)
            return
        }
        
        // Tell CoreMIDI to route messages from this source to our input port
        let status = MIDIPortConnectSource(inputPort, source.id, nil)
        if status == noErr {
            isConnected = true
            log("Connected to \(source.name)", direction: .received)
        } else {
            log("Failed to connect to source: \(status)", direction: .error)
        }
    }
    
    /// Disconnect from the MIDI source
    func disconnect() {
        guard let source = selectedSource else { return }
        
        MIDIPortDisconnectSource(inputPort, source.id)
        isConnected = false
        log("Disconnected", direction: .received)
    }
    
    // MARK: - Sending MIDI Messages
    
    /// Send a SysEx message to the selected destination
    ///
    /// MIDI PACKET STRUCTURE:
    /// A packet is a container for MIDI data with timing information.
    /// We create a "packet list" (array of packets) and send it.
    ///
    /// For small messages (like MiniWorks SysEx ~40 bytes), everything
    /// fits in one packet. For larger dumps, CoreMIDI automatically
    /// fragments across multiple packets.
    ///
    /// - Parameter data: Complete SysEx message including F0...F7
    func sendSysEx(_ data: [UInt8]) {
        guard let destination = selectedDestination else {
            log("No destination selected", direction: .error)
            return
        }
        
        // Create a packet list structure
        // This is a C-style struct that CoreMIDI uses
        var packetList = MIDIPacketList()
        
        // Initialize the list and get a pointer to the first packet
        var packet = MIDIPacketListInit(&packetList)
        
        // Add our data to the packet
        // Parameters:
        //   - packetList: Container for packets
        //   - 1024: Size of buffer (must be large enough for data)
        //   - packet: Current packet pointer
        //   - 0: Timestamp (0 = send immediately)
        //   - data.count: Number of bytes
        //   - data: The actual MIDI bytes
        packet = MIDIPacketListAdd(
            &packetList,
            1024,
            packet,
            0,
            data.count,
            data
        )
        
        // Send the packet list to the destination
        let status = MIDISend(outputPort, destination.id, &packetList)
        
        if status == noErr {
            log("Sent: \(hexString(data))", direction: .sent)
        } else {
            log("Send failed: \(status)", direction: .error)
        }
    }
    
    /// Send a MIDI Control Change message
    ///
    /// CC MESSAGE FORMAT (3 bytes):
    /// Byte 1: 0xB0-0xBF (Status byte: "Control Change" on channels 1-16)
    /// Byte 2: 0-127 (Controller number - which parameter)
    /// Byte 3: 0-127 (Value - what to set it to)
    ///
    /// Example: B0 4A 40
    ///   - B0 = Control Change on channel 1
    ///   - 4A (74) = CC number (filter cutoff)
    ///   - 40 (64) = Value (half open)
    ///
    /// - Parameters:
    ///   - ccNumber: Controller number (0-127)
    ///   - value: Parameter value (0-127)
    ///   - channel: MIDI channel (1-16)
    func sendCC(ccNumber: Int, value: Int, channel: UInt8 = 1) {
        guard let destination = selectedDestination else {
            log("No destination selected", direction: .error)
            return
        }
        
        // Construct the 3-byte CC message
        // 0xB0 = CC status, channel-1 is added (channels are 0-indexed internally)
        let statusByte: UInt8 = 0xB0 + (channel - 1)
        let ccByte = UInt8(ccNumber & 0x7F)
        let valueByte = UInt8(value & 0x7F)
        
        let message: [UInt8] = [statusByte, ccByte, valueByte]
        
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, message.count, message)
        
        let status = MIDISend(outputPort, destination.id, &packetList)
        
        if status == noErr {
            log("Sent CC: #\(ccNumber) = \(value) on channel \(channel)", direction: .sent)
        } else {
            log("CC send failed: \(status)", direction: .error)
        }
    }
    
    // MARK: - SysEx Request Commands
    
    /// Request a program dump from the hardware
    ///
    /// PROGRAM DUMP REQUEST FORMAT:
    /// F0 3E 04 01 <program#> F7
    ///
    /// This asks the synthesizer: "Please send me the settings for program #X"
    /// The synth will respond with a full Program Dump containing all parameters
    ///
    /// - Parameter programNumber: Program slot to request (0-127)
    func requestProgramDump(programNumber: Int) {
        // Program Dump Request: F0 3E 04 01 <program#> F7
        let request: [UInt8] = [
            0xF0,                           // SysEx start
            0x3E,                           // Waldorf manufacturer ID
            0x04,                           // MiniWorks device ID
            0x01,                           // Request command (0x01 = "send me a program")
            UInt8(programNumber & 0x7F),   // Which program (0-127)
            0xF7                            // SysEx end
        ]
        sendSysEx(request)
    }
    
    /// Request an all dump from the hardware (all 128 programs)
    ///
    /// ALL DUMP REQUEST FORMAT:
    /// F0 3E 04 02 F7
    ///
    /// This asks: "Please send me ALL your programs"
    /// The synth will respond with 128 Program Dumps concatenated together
    /// This can take several seconds to transmit!
    func requestAllDump() {
        let request: [UInt8] = [
            0xF0,  // SysEx start
            0x3E,  // Waldorf manufacturer ID
            0x04,  // MiniWorks device ID
            0x02,  // All Dump request command
            0xF7   // SysEx end
        ]
        sendSysEx(request)
    }
    
    // MARK: - Receiving MIDI Messages
    
    /// Handle incoming MIDI events from the input port
    ///
    /// CoreMIDI delivers events as a linked list of packets.
    /// Each packet can contain multiple events (notes, CC, SysEx, etc.)
    /// We iterate through them and process each one.
    ///
    /// - Parameter eventList: Pointer to MIDI event list from CoreMIDI
    private func handleMIDIEvents(_ eventList: UnsafePointer<MIDIEventList>) {
        // Convert the C-style event list into a Swift-friendly iterator
        let events = MIDIEventListGenerator(eventList)
        
        for event in events {
            // Check what type of message this is
            switch event.type {
            case .sysEx, .sysEx7:
                // System Exclusive message
                processSysExEvent(event)
                
            case .controlChange:
                // Control Change (CC) message
                processCCEvent(event)
                
            case .noteOn, .noteOff:
                // Note messages (we don't use these for parameter control)
                log("Note event received (ignored)", direction: .received)
                
            default:
                // Other message types (we ignore them)
                break
            }
        }
    }
    
    /// Process a SysEx event
    ///
    /// FRAGMENTATION HANDLING:
    /// SysEx can arrive in fragments across multiple events:
    ///
    /// Event 1: F0 3E 04 00 05 10 20 30
    /// Event 2: 40 50 60 70 80 90 A0 B0
    /// Event 3: C0 D0 75 F7
    ///
    /// We buffer bytes until we see F7 (end marker), then process
    /// the complete message. This is called "reassembly".
    ///
    private func processSysExEvent(_ event: MIDIEvent) {
        // Extract raw bytes from the event structure
        var bytes: [UInt8] = []
        
        withUnsafeBytes(of: event.data) { buffer in
            bytes = Array(buffer)
        }
        
        // Handle SysEx buffering
        for byte in bytes {
            if byte == 0xF0 {
                // Start of SysEx - begin new buffer
                sysexBuffer = [byte]
                isReceivingSysEx = true
            } else if byte == 0xF7 && isReceivingSysEx {
                // End of SysEx - process complete message
                sysexBuffer.append(byte)
                processCompleteSysEx(sysexBuffer)
                sysexBuffer = []
                isReceivingSysEx = false
            } else if isReceivingSysEx {
                // Middle of SysEx - accumulate
                sysexBuffer.append(byte)
            }
        }
    }
    
    /// Process a Control Change event
    ///
    /// CC messages control parameters in real-time.
    /// Format: [Status][CC#][Value]
    ///
    /// We extract the CC number and value, then let the CC mapper
    /// route it to the correct synthesizer parameter.
    private func processCCEvent(_ event: MIDIEvent) {
        // Extract CC data from event
        // The data field contains both CC number and value packed together
        let ccNumber = Int((event.data >> 8) & 0x7F)
        let value = Int(event.data & 0x7F)
        
        log("Received CC: #\(ccNumber) = \(value)", direction: .received)
        
        // TODO: Route to CC mapper if needed
        // ccMapper.handleCC(ccNumber: ccNumber, value: value, program: program)
    }
    
    /// Process a complete SysEx message
    ///
    /// Now that we have the full message (F0...F7), we:
    /// 1. Verify it has the correct manufacturer ID (Waldorf = 0x3E)
    /// 2. Verify the checksum is valid
    /// 3. Parse the command type and data
    /// 4. Update the program model if it's a program dump
    ///
    private func processCompleteSysEx(_ data: [UInt8]) {
        log("Received: \(hexString(data))", direction: .received)
        
        // Verify this is a Waldorf MiniWorks message
        guard data.count > 4,
              data[0] == 0xF0,     // SysEx start
              data[1] == 0x3E,     // Waldorf manufacturer ID
              data[2] == 0x04,     // MiniWorks device ID
              data.last == 0xF7    // SysEx end
        else {
            log("Invalid SysEx format", direction: .error)
            return
        }
        
        // Verify checksum
        let isValid = verifyChecksum(data, mode: checksumMode)
        if !isValid {
            log("⚠️ Checksum verification failed!", direction: .error)
            log("This could mean:", direction: .error)
            log("- Wrong checksum mode selected (try switching)", direction: .error)
            log("- Corrupted data transmission", direction: .error)
            log("- Incompatible firmware version", direction: .error)
            return
        }
        
        // Check command type
        let command = data[3]
        
        switch command {
        case 0x00:
            // Program Dump (device sent us a program)
            if let programNumber = extractProgramNumber(data) {
                log("✓ Program #\(programNumber) dump received (checksum valid)", direction: .received)
            }
            
        case 0x01:
            // Program Dump Request (shouldn't receive this, we send it)
            log("Received program dump request (unusual)", direction: .received)
            
        case 0x02:
            // All Dump Request (shouldn't receive this, we send it)
            log("Received all dump request (unusual)", direction: .received)
            
        default:
            log("Unknown SysEx command: 0x\(String(format: "%02X", command))", direction: .received)
        }
    }
    
    // MARK: - Logging
    
    /// Add a message to the MIDI traffic log
    ///
    /// The log helps debug MIDI communication issues by showing:
    /// - Timestamps (when did this happen?)
    /// - Direction (sent or received?)
    /// - Message content (what data was transferred?)
    /// - Errors (what went wrong?)
    ///
    func log(_ message: String, direction: LogMessage.Direction) {
        let logMsg = LogMessage(timestamp: Date(), direction: direction, message: message)
        logMessages.append(logMsg)
        
        // Keep log size manageable (prevent memory growth)
        // Only keep the most recent 100 messages
        if logMessages.count > 100 {
            logMessages.removeFirst(logMessages.count - 100)
        }
    }
    
    func clearLog() {
        logMessages.removeAll()
    }
}

// MARK: - MIDIEventList Iterator

/// Helper to iterate over CoreMIDI event lists
///
/// CoreMIDI delivers events as a C-style linked list, which is awkward
/// to work with in Swift. This wrapper makes it iterable using a
/// standard Swift for-loop.
struct MIDIEventListGenerator: Sequence, IteratorProtocol {
    private var currentPacket: UnsafePointer<MIDIEventPacket>?
    private var remainingPackets: Int
    
    init(_ list: UnsafePointer<MIDIEventList>) {
        currentPacket = list.pointee.packet()
        remainingPackets = Int(list.pointee.numPackets)
    }
    
    mutating func next() -> MIDIEvent? {
        guard remainingPackets > 0, let packet = currentPacket else {
            return nil
        }
        
        remainingPackets -= 1
        
        // Get events from this packet
        var eventIterator = packet.pointee.words.makeIterator()
        if let wordPtr = eventIterator.next() {
            let event = MIDIEvent(wordPtr: wordPtr)
            currentPacket = packet.pointee.next()
            return event
        }
        
        return nil
    }
}

// MARK: - MIDIEvent Wrapper

/// Simplified wrapper for MIDI events
///
/// CoreMIDI represents events as packed UInt32 words. This wrapper
/// extracts the message type and data into a more usable format.
struct MIDIEvent {
    let type: MIDIMessageType
    let data: UInt64
    
    init(wordPtr: UnsafePointer<UInt32>) {
        let word = wordPtr.pointee
        
        // Extract message type from upper byte
        self.type = MIDIMessageType(rawValue: Int((word >> 24) & 0xFF)) ?? .other
        
        // Extract data words (simplified - real implementation would parse fully)
        var dataValue: UInt64 = 0
        let dataPtr = UnsafeRawPointer(wordPtr.advanced(by: 1))
        dataPtr.withMemoryRebound(to: UInt64.self, capacity: 1) { ptr in
            dataValue = ptr.pointee
        }
        self.data = dataValue
    }
}

/// MIDI message type identifiers
///
/// These hex codes identify different MIDI message types.
/// The full MIDI 2.0 specification has many more, but we only
/// need these for synthesizer control.
enum MIDIMessageType: Int {
    case sysEx = 0x30          // System Exclusive (MIDI 1.0)
    case sysEx7 = 0x50         // 7-bit SysEx (MIDI 2.0)
    case controlChange = 0xB0  // Control Change
    case noteOn = 0x90         // Note On
    case noteOff = 0x80        // Note Off
    case other = 0             // Anything else
}
