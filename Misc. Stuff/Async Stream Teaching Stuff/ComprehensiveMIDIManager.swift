// MIDIManager.swift
// Comprehensive MIDI I/O using CoreMIDI with MIDI 1.0
//
// ARCHITECTURE:
// MIDIManager (Actor) ←→ SysExCodec ←→ UI (MainActor)
//
// DATA FLOW:
// Outgoing: UI → SysExCodec.encode() → [UInt8] → MIDIManager.send() → CoreMIDI
// Incoming: CoreMIDI → MIDIManager streams → [UInt8] → SysExCodec.decode() → UI

import CoreMIDI
import Foundation

// MARK: - MIDI Device Model

/// Represents a MIDI device endpoint
/// Sendable ensures thread-safe passing between actors and main thread
public struct MIDIDevice: Identifiable, Hashable, Sendable {
    public let id: MIDIUniqueID
    public let endpoint: MIDIEndpointRef
    public let name: String
    public let manufacturer: String
    public let model: String
    
    public enum DeviceType: Sendable {
        case source      // Can receive MIDI from this device
        case destination // Can send MIDI to this device
    }
    
    public let type: DeviceType
    
    /// Initialize from CoreMIDI endpoint
    init?(endpoint: MIDIEndpointRef, type: DeviceType) {
        var name: Unmanaged<CFString>?
        var manufacturer: Unmanaged<CFString>?
        var model: Unmanaged<CFString>?
        var uniqueID: Int32 = 0
        
        // Query CoreMIDI properties
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyManufacturer, &manufacturer)
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyModel, &model)
        MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
        
        guard let name = name?.takeRetainedValue() as String? else {
            return nil
        }
        
        self.id = MIDIUniqueID(uniqueID)
        self.endpoint = endpoint
        self.name = name
        self.manufacturer = manufacturer?.takeRetainedValue() as String? ?? "Unknown"
        self.model = model?.takeRetainedValue() as String? ?? "Unknown"
        self.type = type
    }
}

// MARK: - MIDI Errors

public enum MIDIError: Error, LocalizedError {
    case initializationFailed(OSStatus)
    case deviceNotFound
    case connectionFailed(OSStatus)
    case sendFailed(OSStatus)
    case invalidSysEx(String)
    case invalidMIDIMessage(String)
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let status):
            return "MIDI initialization failed with status: \(status)"
        case .deviceNotFound:
            return "MIDI device not found or no longer available"
        case .connectionFailed(let status):
            return "Failed to connect to device (status: \(status))"
        case .sendFailed(let status):
            return "Failed to send MIDI message (status: \(status))"
        case .invalidSysEx(let reason):
            return "Invalid SysEx message: \(reason)"
        case .invalidMIDIMessage(let reason):
            return "Invalid MIDI message: \(reason)"
        }
    }
}

// MARK: - MIDI Message Types

/// All supported MIDI message types
public enum MIDIMessageType: Sendable {
    case sysex([UInt8])                              // System Exclusive
    case noteOn(channel: UInt8, note: UInt8, velocity: UInt8)
    case noteOff(channel: UInt8, note: UInt8, velocity: UInt8)
    case controlChange(channel: UInt8, cc: UInt8, value: UInt8)
    case programChange(channel: UInt8, program: UInt8)
    case pitchBend(channel: UInt8, value: UInt16)     // 14-bit value
    case aftertouch(channel: UInt8, pressure: UInt8)
    case polyAftertouch(channel: UInt8, note: UInt8, pressure: UInt8)
}

// MARK: - MIDI Manager Actor

/// Thread-safe MIDI Manager using Swift Concurrency
/// Handles all MIDI I/O operations using CoreMIDI with MIDI 1.0
public actor MIDIManager {
    
    // MARK: - Properties
    
    /// CoreMIDI client reference
    private var client: MIDIClientRef = 0
    
    /// Input port for receiving MIDI
    private var inputPort: MIDIPortRef = 0
    
    /// Output port for sending MIDI
    private var outputPort: MIDIPortRef = 0
    
    /// Active connections to devices
    private var connections: [MIDIUniqueID: DeviceConnection] = [:]
    
    /// Singleton instance
    public static let shared = MIDIManager()
    
    // MARK: - Initialization
    
    private init() {
        setupMIDI()
    }
    
    /// Initialize CoreMIDI client and ports
    private func setupMIDI() {
        var client: MIDIClientRef = 0
        
        // Create MIDI client with notification callback
        var status = MIDIClientCreateWithBlock("MIDIManager" as CFString, &client) { notification in
            Task {
                await MIDIManager.shared.handleNotification(notification)
            }
        }
        
        guard status == noErr else {
            print("❌ Failed to create MIDI client: \(status)")
            return
        }
        
        self.client = client
        
        // Create input port with MIDI 1.0
        var inPort: MIDIPortRef = 0
        status = MIDIInputPortCreateWithBlock(
            client,
            "MIDIManager Input" as CFString,
            &inPort
        ) { packetList, srcConnRefCon in
            Task {
                await MIDIManager.shared.handleIncomingPackets(packetList)
            }
        }
        
        guard status == noErr else {
            print("❌ Failed to create input port: \(status)")
            return
        }
        
        self.inputPort = inPort
        
        // Create output port
        var outPort: MIDIPortRef = 0
        status = MIDIOutputPortCreate(
            client,
            "MIDIManager Output" as CFString,
            &outPort
        )
        
        guard status == noErr else {
            print("❌ Failed to create output port: \(status)")
            return
        }
        
        self.outputPort = outPort
        
        print("✅ MIDI Manager initialized successfully")
    }
    
    // MARK: - Device Discovery
    
    /// Get all available MIDI source devices (for receiving)
    public func availableSources() -> [MIDIDevice] {
        var devices: [MIDIDevice] = []
        
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let endpoint = MIDIGetSource(i)
            if let device = MIDIDevice(endpoint: endpoint, type: .source) {
                devices.append(device)
            }
        }
        
        return devices
    }
    
    /// Get all available MIDI destination devices (for sending)
    public func availableDestinations() -> [MIDIDevice] {
        var devices: [MIDIDevice] = []
        
        let destCount = MIDIGetNumberOfDestinations()
        for i in 0..<destCount {
            let endpoint = MIDIGetDestination(i)
            if let device = MIDIDevice(endpoint: endpoint, type: .destination) {
                devices.append(device)
            }
        }
        
        return devices
    }
    
    // MARK: - Connection Management
    
    /// Connect to a MIDI device for bidirectional communication
    /// - Parameters:
    ///   - source: Source device to receive MIDI from
    ///   - destination: Destination device to send MIDI to
    /// - Returns: Connection identifier
    public func connect(source: MIDIDevice, destination: MIDIDevice) throws {
        // Connect input (source)
        let status = MIDIPortConnectSource(inputPort, source.endpoint, nil)
        guard status == noErr else {
            throw MIDIError.connectionFailed(status)
        }
        
        // Store connection info
        let connection = DeviceConnection(
            source: source,
            destination: destination,
            sysexContinuation: nil,
            ccContinuation: nil,
            noteContinuation: nil
        )
        
        connections[source.id] = connection
        
        print("✅ Connected to \(source.name) ← → \(destination.name)")
    }
    
    /// Disconnect from a specific device
    public func disconnect(from source: MIDIDevice) {
        MIDIPortDisconnectSource(inputPort, source.endpoint)
        connections.removeValue(forKey: source.id)
        print("🔌 Disconnected from \(source.name)")
    }
    
    /// Disconnect from all devices
    public func disconnectAll() {
        for (_, connection) in connections {
            MIDIPortDisconnectSource(inputPort, connection.source.endpoint)
        }
        connections.removeAll()
        print("🔌 Disconnected from all devices")
    }
    
    // MARK: - Sending MIDI
    
    /// Send a MIDI message to a destination device
    /// - Parameters:
    ///   - message: The MIDI message to send
    ///   - destination: The destination device
    public func send(_ message: MIDIMessageType, to destination: MIDIDevice) throws {
        let bytes = try encodeMessage(message)
        try sendRawBytes(bytes, to: destination)
    }
    
    /// Encode a MIDI message to raw bytes
    private func encodeMessage(_ message: MIDIMessageType) throws -> [UInt8] {
        switch message {
        case .sysex(let data):
            guard data.first == 0xF0, data.last == 0xF7 else {
                throw MIDIError.invalidSysEx("SysEx must start with 0xF0 and end with 0xF7")
            }
            return data
            
        case .noteOn(let channel, let note, let velocity):
            guard channel < 16, note < 128, velocity < 128 else {
                throw MIDIError.invalidMIDIMessage("Invalid Note On parameters")
            }
            return [0x90 | channel, note, velocity]
            
        case .noteOff(let channel, let note, let velocity):
            guard channel < 16, note < 128, velocity < 128 else {
                throw MIDIError.invalidMIDIMessage("Invalid Note Off parameters")
            }
            return [0x80 | channel, note, velocity]
            
        case .controlChange(let channel, let cc, let value):
            guard channel < 16, cc < 128, value < 128 else {
                throw MIDIError.invalidMIDIMessage("Invalid CC parameters")
            }
            return [0xB0 | channel, cc, value]
            
        case .programChange(let channel, let program):
            guard channel < 16, program < 128 else {
                throw MIDIError.invalidMIDIMessage("Invalid Program Change parameters")
            }
            return [0xC0 | channel, program]
            
        case .pitchBend(let channel, let value):
            guard channel < 16, value < 16384 else {
                throw MIDIError.invalidMIDIMessage("Invalid Pitch Bend parameters")
            }
            let lsb = UInt8(value & 0x7F)
            let msb = UInt8((value >> 7) & 0x7F)
            return [0xE0 | channel, lsb, msb]
            
        case .aftertouch(let channel, let pressure):
            guard channel < 16, pressure < 128 else {
                throw MIDIError.invalidMIDIMessage("Invalid Aftertouch parameters")
            }
            return [0xD0 | channel, pressure]
            
        case .polyAftertouch(let channel, let note, let pressure):
            guard channel < 16, note < 128, pressure < 128 else {
                throw MIDIError.invalidMIDIMessage("Invalid Poly Aftertouch parameters")
            }
            return [0xA0 | channel, note, pressure]
        }
    }
    
    /// Send raw MIDI bytes to destination
    private func sendRawBytes(_ bytes: [UInt8], to destination: MIDIDevice) throws {
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        
        packet = MIDIPacketListAdd(
            &packetList,
            1024,
            packet,
            0,
            bytes.count,
            bytes
        )
        
        guard packet != nil else {
            throw MIDIError.sendFailed(-1)
        }
        
        let status = MIDISend(outputPort, destination.endpoint, &packetList)
        guard status == noErr else {
            throw MIDIError.sendFailed(status)
        }
    }
    
    // MARK: - Receiving MIDI Streams
    
    /// Get stream of incoming SysEx messages
    public func sysexStream(from source: MIDIDevice) -> AsyncStream<[UInt8]> {
        AsyncStream { continuation in
            guard var connection = connections[source.id] else {
                continuation.finish()
                return
            }
            
            connection.sysexContinuation = continuation
            connections[source.id] = connection
            
            continuation.onTermination = { @Sendable _ in
                Task {
                    await MIDIManager.shared.removeSysExContinuation(for: source.id)
                }
            }
        }
    }
    
    /// Get stream of incoming Control Change messages
    public func ccStream(from source: MIDIDevice) -> AsyncStream<(channel: UInt8, cc: UInt8, value: UInt8)> {
        AsyncStream { continuation in
            guard var connection = connections[source.id] else {
                continuation.finish()
                return
            }
            
            connection.ccContinuation = continuation
            connections[source.id] = connection
            
            continuation.onTermination = { @Sendable _ in
                Task {
                    await MIDIManager.shared.removeCCContinuation(for: source.id)
                }
            }
        }
    }
    
    /// Get stream of incoming Note messages (On and Off)
    public func noteStream(from source: MIDIDevice) -> AsyncStream<(isNoteOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8)> {
        AsyncStream { continuation in
            guard var connection = connections[source.id] else {
                continuation.finish()
                return
            }
            
            connection.noteContinuation = continuation
            connections[source.id] = connection
            
            continuation.onTermination = { @Sendable _ in
                Task {
                    await MIDIManager.shared.removeNoteContinuation(for: source.id)
                }
            }
        }
    }
    
    // MARK: - Incoming Packet Handling
    
    /// Handle incoming MIDI packets from CoreMIDI
    private func handleIncomingPackets(_ packetList: UnsafePointer<MIDIPacketList>) {
        var packet = packetList.pointee.packet
        
        for _ in 0..<packetList.pointee.numPackets {
            let bytes = withUnsafeBytes(of: &packet.data) { pointer in
                Array(pointer.prefix(Int(packet.length)))
            }
            
            processPacketBytes(bytes)
            
            packet = MIDIPacketNext(&packet).pointee
        }
    }
    
    /// Buffer for assembling multi-packet SysEx messages
    private var sysexBuffer: [UInt8] = []
    
    /// Process MIDI bytes from a packet
    private func processPacketBytes(_ bytes: [UInt8]) {
        var i = 0
        
        while i < bytes.count {
            let byte = bytes[i]
            
            // SysEx handling
            if byte == 0xF0 {
                // Start of SysEx
                sysexBuffer = [0xF0]
                i += 1
                
                // Collect until 0xF7 or end of packet
                while i < bytes.count {
                    let dataByte = bytes[i]
                    sysexBuffer.append(dataByte)
                    i += 1
                    
                    if dataByte == 0xF7 {
                        // Complete SysEx message
                        notifySysEx(sysexBuffer)
                        sysexBuffer = []
                        break
                    }
                }
                continue
            }
            
            // If we're in the middle of a SysEx
            if !sysexBuffer.isEmpty {
                sysexBuffer.append(byte)
                i += 1
                
                if byte == 0xF7 {
                    // Complete SysEx message
                    notifySysEx(sysexBuffer)
                    sysexBuffer = []
                }
                continue
            }
            
            // Regular MIDI messages
            if byte & 0x80 != 0 {
                // Status byte
                let messageType = byte & 0xF0
                let channel = byte & 0x0F
                
                switch messageType {
                case 0x80:  // Note Off
                    if i + 2 < bytes.count {
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        notifyNote(isOn: false, channel: channel, note: note, velocity: velocity)
                        i += 3
                    } else {
                        i += 1
                    }
                    
                case 0x90:  // Note On
                    if i + 2 < bytes.count {
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        notifyNote(isOn: velocity > 0, channel: channel, note: note, velocity: velocity)
                        i += 3
                    } else {
                        i += 1
                    }
                    
                case 0xB0:  // Control Change
                    if i + 2 < bytes.count {
                        let cc = bytes[i + 1]
                        let value = bytes[i + 2]
                        notifyCC(channel: channel, cc: cc, value: value)
                        i += 3
                    } else {
                        i += 1
                    }
                    
                default:
                    i += 1
                }
            } else {
                i += 1
            }
        }
    }
    
    // MARK: - Stream Notifications
    
    private func notifySysEx(_ data: [UInt8]) {
        for (_, connection) in connections {
            connection.sysexContinuation?.yield(data)
        }
    }
    
    private func notifyCC(channel: UInt8, cc: UInt8, value: UInt8) {
        for (_, connection) in connections {
            connection.ccContinuation?.yield((channel, cc, value))
        }
    }
    
    private func notifyNote(isOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8) {
        for (_, connection) in connections {
            connection.noteContinuation?.yield((isOn, channel, note, velocity))
        }
    }
    
    // MARK: - Cleanup
    
    private func removeSysExContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.sysexContinuation = nil
    }
    
    private func removeCCContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.ccContinuation = nil
    }
    
    private func removeNoteContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.noteContinuation = nil
    }
    
    // MARK: - Notifications
    
    private func handleNotification(_ notification: UnsafePointer<MIDINotification>) {
        // Handle MIDI system notifications (device added/removed, etc.)
        let messageID = notification.pointee.messageID
        
        switch messageID {
        case .msgObjectAdded:
            print("📱 MIDI device added")
            
        case .msgObjectRemoved:
            print("📱 MIDI device removed")
            
        default:
            break
        }
    }
    
    deinit {
        disconnectAll()
        
        if client != 0 {
            MIDIClientDispose(client)
        }
    }
}

// MARK: - Device Connection

/// Internal structure tracking device connection state
private struct DeviceConnection {
    let source: MIDIDevice
    let destination: MIDIDevice
    var sysexContinuation: AsyncStream<[UInt8]>.Continuation?
    var ccContinuation: AsyncStream<(UInt8, UInt8, UInt8)>.Continuation?
    var noteContinuation: AsyncStream<(Bool, UInt8, UInt8, UInt8)>.Continuation?
}

// MARK: - Usage Example

/*
 EXAMPLE USAGE:
 
 // 1. Get MIDIManager instance
 let midi = MIDIManager.shared
 
 // 2. Discover devices
 let sources = await midi.availableSources()
 let destinations = await midi.availableDestinations()
 
 guard let waldorf = sources.first(where: { $0.name.contains("Waldorf") }),
       let waldorfOut = destinations.first(where: { $0.name.contains("Waldorf") }) else {
     return
 }
 
 // 3. Connect
 try await midi.connect(source: waldorf, destination: waldorfOut)
 
 // 4. Send SysEx
 let patchData: [UInt8] = [0xF0, 0x3E, 0x04, 0x01, 0x00, 0x1F, /* ... */, 0xF7]
 try await midi.send(.sysex(patchData), to: waldorfOut)
 
 // 5. Send CC
 try await midi.send(.controlChange(channel: 0, cc: 16, value: 64), to: waldorfOut)
 
 // 6. Listen for incoming SysEx
 Task {
     for await sysex in await midi.sysexStream(from: waldorf) {
         print("Received SysEx: \(sysex.count) bytes")
         // Pass to SysExCodec for parsing
     }
 }
 
 // 7. Listen for incoming CCs
 Task {
     for await (channel, cc, value) in await midi.ccStream(from: waldorf) {
         print("CC \(cc) = \(value) on channel \(channel)")
     }
 }
 */
