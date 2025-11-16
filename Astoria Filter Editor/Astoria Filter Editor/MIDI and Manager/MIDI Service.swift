//
//  MIDI Manager.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import CoreMIDI


final actor MIDIService {

    static let shared = MIDIService()
    private init() {}
    
    
    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var outputPort: MIDIPortRef = 0
    
    /// Holds Connections (and thier Continuations)
    private var connections: [MIDIUniqueID: DeviceConnection] = [:]
    private var sysexBuffer: [UInt8] = []

    
    // MARK: - Lifecycle
    
    func initializeMIDI() throws {
        debugPrint(icon: "🆕", message: "Initializing MIDI")
        
        try createMIDIClient()
        try createInputPort()
        try createOutputPort()
    }
    
    
    deinit {
        // Can't call 'disconnectAll()' from here
        // Have to duplicate the code
        for (_, connection) in connections {
            MIDIPortDisconnectSource(inputPort, connection.source.endpoint)
        }
        
        connections.removeAll()

        if midiClient != 0 { MIDIClientDispose(midiClient) }
    }
    
    
    // MARK: - Client
    
    /// Create App's MIDI Client
    private func createMIDIClient() throws {
        let status = MIDIClientCreateWithBlock("Astoria Filter Editor" as CFString, &midiClient) { [weak self] notification in
            Task {
                await self?.MIDINotificationHander(notification)
            }
        }
        
        guard status == noErr
        else { throw MIDIError.clientCreationFailed(status) }
        
        Task {
            debugPrint(icon: "🎹", message: "Client Created")
        }
    }
    
    
    /// Called when MIDI System changes occur
    private func MIDINotificationHander(_ notification: UnsafePointer<MIDINotification>) {
        switch notification.pointee.messageID {
            case .msgObjectAdded: print("🎹 MIDI Device Added 🎹")
            case .msgObjectRemoved: print("🎹 MIDI Device Removed 🎹")
            case .msgPropertyChanged: print("🎹 MIDI Device Property Changed 🎹")
            case .msgSetupChanged: print("🎹 MIDI System Setup Changed 🎹")
            default: print("Some other MIDI System Notification: \(notification.pointee.messageID.rawValue)")
        }
    }
    
    
        // MARK: - Input Port
    
    private func createInputPort() throws {
        let status = MIDIInputPortCreateWithBlock(midiClient, "MIDI Service Input" as CFString, &inputPort, { [weak self] packetList, _ in
            // Pointers and Data must be copies, pointer will go out of scope at end of method
            let numPackets = packetList.pointee.numPackets
            var copiedPackets: [[UInt8]] = []
            print("\n🎹 MIDI Callback fired! numPackets: \(numPackets)")

            var packet = packetList.pointee.packet
            
            for _ in 0..<numPackets {
                let bytes = withUnsafeBytes(of: &packet.data) { pointer in
                    Array(pointer.prefix(Int(packet.length)))
                }
                
                copiedPackets.append(bytes)
                packet = MIDIPacketNext(&packet).pointee
            }
            
            Task {
                await self?.handleIncomingPacketData(copiedPackets)
            }
        })
        
        guard status == noErr
        else { throw MIDIError.portCreationFailed(status) }
        
        debugPrint(icon: "➡️", message: "Input Port Created")
    }
    
    
    // MARK: - Output Port
    
    private func createOutputPort() throws {
        let status = MIDIOutputPortCreate(midiClient, "MIDI Service Output" as CFString, &outputPort)
        
        guard status == noErr
        else { throw MIDIError.portCreationFailed(status) }
        
        debugPrint(icon: "⬅️", message: "Output Port Created")
    }
    

// MARK: - Connecting/Disconnecting Devices

    func availableSources() -> [MIDIDevice] {
        var devices: [MIDIDevice] = []
        
        let sourceCount = MIDIGetNumberOfSources()
        debugPrint(icon: "📡" , message: "Discovered \(sourceCount) MIDI Sources")
        
        for i in 0..<sourceCount {
            let endpoint = MIDIGetSource(i)
            
            if let device = try? MIDIDevice(endpoint: endpoint, type: .source) {
                devices.append(device)
                debugPrint(icon: "📩", message: "Source: \(device.name) by \(device.manufacturer)")
            }
        }
        
        return devices
    }
    
    
    func availableDestinations() -> [MIDIDevice] {
        var devices: [MIDIDevice] = []
        
        let destinationCount = MIDIGetNumberOfDestinations()
        
        debugPrint(icon: "📥" , message: "Discovered \(destinationCount) MIDI Destinations")
        
        for i in 0..<destinationCount {
            let endpoint = MIDIGetDestination(i)
            
            if let device = try? MIDIDevice(endpoint: endpoint, type: .destination) {
                devices.append(device)
                debugPrint(icon: "📦", message: "Destination: \(device.name) by \(device.manufacturer)")
            }
        }
        
        return devices
    }
    
    
        // MARK: Connect/Disconnect
    
    func connect(source: MIDIDevice, destination: MIDIDevice) throws {
        debugPrint(icon: "🔌", message: "Connecting \(source.name) to \(destination.name)")
        
        connections[source.id] = DeviceConnection(source: source, destination: destination)
        
        let status = MIDIPortConnectSource(inputPort, source.endpoint, nil)
        
        guard status == noErr
        else {
            connections.removeValue(forKey: source.id)
            throw MIDIError.connectionFailed(status)
        }
        
        debugPrint(icon: "🔌", message: "\(source.name) now connected to \(destination.name)\nconnections count: \(connections.count)")
    }
    
    
    func disconnect(from source: MIDIDevice) {
        debugPrint(icon: "🔌", message: "Disconnecting from \(source.name)")
        
        MIDIPortDisconnectSource(inputPort, source.endpoint)
        connections.removeValue(forKey: source.id)
        
        debugPrint(icon: "🔌", message: "Now disconnect from \(source.name)")
    }
    
    
    func disconnectAll() {
        debugPrint(icon: "🔌", message: "Disconnecting all devices")
        
        for (_, connection) in connections {
            MIDIPortDisconnectSource(inputPort, connection.source.endpoint)
        }
        
        connections.removeAll()
        
        debugPrint(icon: "🔌", message: "All devices now Disconnected")
    }
    

    private func handleIncomingPacketData(_ packets: [[UInt8]]) {
        debugPrint(icon: "🔄", message: "Enumerating MIDI devices...")
        
        for (i, bytes) in packets.enumerated() {
            debugPrint(icon: "🔄", message: "Handling \(bytes.count) byte packet \(i + 1)")
            
            processPacketBytes(bytes)
        }
    }
    
    
    private func processPacketBytes(_ bytes: [UInt8]) {
        debugPrint(icon: "🔍", message: "Processing \(bytes.count) byte packet (no further processing done yet)")
        var i = 0
        
        while i < bytes.count {
            let byte = bytes[i]
            
            // SysEx Start
            if byte == 0xF0 {
                debugPrint(message: "Sysex message detected")
                sysexBuffer = [0xF0]
                i += 1
                
                while i < bytes.count {
                    let dataByte = bytes[i]
                    sysexBuffer.append(dataByte)
                    i += 1
                    
                    // End of SysEx
                    if dataByte == 0xF7 {
                        debugPrint(message: "End of Sysex message")
                        notifySysEx(sysexBuffer)
                        sysexBuffer.removeAll()
                        break
                    }
                    
                } // while
                continue
            } // If Sysex start
            
            
            if !sysexBuffer.isEmpty {
                sysexBuffer.append(byte)
                i += 1
                
                // End of SysEx
                if byte == 0xF7 {
                    debugPrint(message: "End of Sysex message")
                    notifySysEx(sysexBuffer)
                    sysexBuffer.removeAll()
                }
                continue
            }
            
            
            // Regular MIDI Message
            // If byte & 0x80 ≠ 0 → bit 7 is 1 → it's a status byte
            if byte & 0x80 != 0 {
                // byte & 11110000
                let messageType = byte & 0xF0
                    // byte & 00001111
                let channel = byte & 0x0F
                
                switch messageType {
                    case 0x80:
                        if i + 2 < bytes.count {
                            let note = bytes[i + 1]
                            let velocity = bytes[i + 2]
                            debugPrint(icon: "♬", message: "Note Off - Note: \(note), Velocity: \(velocity)")
                            notifyNote(isNoteOn: false, channel: channel, note: note, velocity: velocity)
                            i += 3
                        }
                        else {
                            i += 1
                        }
                        
                        
                    case 0x90: // Note On
                        if i + 2 < bytes.count {
                            let note = bytes[i + 1]
                            let velocity = bytes[i + 2]
                            debugPrint(icon: "♬", message: "Note On - Note: \(note), Velocity: \(velocity)")
                            notifyNote(isNoteOn: true, channel: channel, note: note, velocity: velocity)
                            i += 3
                        }
                        else {
                            i += 1
                        }
                        
                        
                    case 0xB0: // Control Change
                        if i + 2 < bytes.count {
                            let control = bytes[i + 1]
                            let value = bytes[i + 2]
                            debugPrint(icon: "🎛️", message: "Control Change - Control: \(control), Value: \(value)")
                            notifyCC(channel: channel, cc: control, value: value)
                            i += 3
                        }
                        else {
                            i += 1
                        }
                        
                        
                    default: i += 1
                }
            }
            else {
                i += 1
            }
            
        } // while
        
    }
    

// MARK: - Sending MIDI

    func send(_ message: MIDIMessageType, to destination: MIDIDevice) throws {
        let bytes = try encodeMessage(message)
        
        debugPrint(icon: "📤", message: "Sending \(bytes.count) to \(destination.name): \(bytes.hexString)")
        
        var status: OSStatus = noErr
        
        do {
            status = try sendRawBytes(bytes, to: destination)
            debugPrint(icon: "📤", message: "\(bytes.count) bytes sent to \(destination.name)")
        }
        catch {
            throw MIDIError.sendFailed(status)
        }
    }
    
    
    func encodeMessage(_ message: MIDIMessageType) throws -> [UInt8] {
        switch message {
            case .sysex(let data):
                guard
                    data.first == 0xF0,
                    data.last == 0xF7
                else {
                    throw MIDIError.invalidSysEx("SysEx must start with 0xF0 and end with 0xF7")
                }
                
                return data
                
            case .noteOn(let channel, let note, let velocity):
                guard
                    channel < 16,
                    note < 128,
                    velocity < 128
                else {
                    throw MIDIError.invalidMIDIMessage("Invalid Note On parameters")
                }
                
                return [0x90 | channel, note, velocity]
                
            case .noteOff(let channel, let note, let velocity):
                guard channel < 16,
                      note < 128,
                      velocity < 128
                else {
                    throw MIDIError.invalidMIDIMessage("Invalid Note Off parameters")
                }
                
                return [0x80 | channel, note, velocity]
                
            case .controlChange(let channel, let cc, let value):
                guard channel < 16,
                      cc < 128,
                      value < 128
                else {
                    throw MIDIError.invalidMIDIMessage("Invalid CC parameters")
                }
                
                return [0xB0 | channel, cc, value]
                
            case .programChange(let channel, let program):
                guard
                    channel < 16,
                    program < 128
                else {
                    throw MIDIError.invalidMIDIMessage("Invalid Program Change parameters")
                }
                
                return [0xC0 | channel, program]
                
            case .pitchBend(let channel, let value):
                guard
                    channel < 16,
                    value < 16384
                else {
                    throw MIDIError.invalidMIDIMessage("Invalid Pitch Bend parameters")
                }
                
                let lsb = UInt8(value & 0x7F)
                let msb = UInt8((value >> 7) & 0x7F)
                return [0xE0 | channel, lsb, msb]
                
            case .aftertouch(let channel, let pressure):
                guard
                    channel < 16,
                    pressure < 128
                else {
                    throw MIDIError.invalidMIDIMessage("Invalid Aftertouch parameters")
                }
                
                return [0xD0 | channel, pressure]
                
            case .polyAftertouch(let channel, let note, let pressure):
                guard channel < 16,
                      note < 128,
                      pressure < 128
                else {
                    throw MIDIError.invalidMIDIMessage("Invalid Poly Aftertouch parameters")
                }
                
                return [0xA0 | channel, note, pressure]
        }
    }
    
    
    private func sendRawBytes(_ bytes: [UInt8], to destination: MIDIDevice) throws -> OSStatus {
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        
        packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, bytes.count, bytes)
        
        let status = MIDISend(outputPort, destination.endpoint, &packetList)
        
        return status
    }


    // MARK: - Receiving MIDI Streams

        /// Create and hold on to the AsyncStream for receiveing SysEx data
    func sysexStream(from source: MIDIDevice) -> AsyncStream<[UInt8]> {
        AsyncStream(bufferingPolicy: .bufferingOldest(5)) { continuation in
            debugPrint(icon: "💦", message: "Creating SysEx Stream for \(source.name)")
            
            if var connection = self.connections[source.id] {
                connection.sysexContinuation = continuation
                self.connections[source.id] = connection
                debugPrint(icon: "💦", message: "SysEx Stream for \(source.name) was created")
            }
            else {
                debugPrint(icon: "💦", message: "Failed to create SysEx Stream for \(source.name)")
            }
            
                // Always remove continuations when no longer needed
            continuation.onTermination = { _ in
                Task {
                    await self.removeSysExContinuation(for: source.id)
                }
            }
        }
    }
    
    
    func ccStream(from source: MIDIDevice) -> AsyncStream<ContinuousControllerEvent> {
        AsyncStream(bufferingPolicy: .bufferingOldest(5)) { continuation in
            debugPrint(icon: "💦", message: "Creating SysEx Stream for \(source.name)")
            
            if var connection = self.connections[source.id] {
                connection.ccContinuation = continuation
                self.connections[source.id] = connection
                debugPrint(icon: "💦", message: "SysEx Stream for \(source.name) was created")
            }
            else {
                debugPrint(icon: "💦", message: "Failed to create SysEx Stream for \(source.name)")
            }
            
                // Always remove continuations when no longer needed
            continuation.onTermination = { _ in
                Task {
                    await self.removeCCContinuation(for: source.id)
                }
            }
        }
    }
    
    
    func noteStream(from source: MIDIDevice) -> AsyncStream<NoteEvent> {
            return AsyncStream(bufferingPolicy: .bufferingOldest(5)) { continuation in
            debugPrint(icon: "💦", message: "Creating Note Stream for \(source.name)")
            
            if var connection = self.connections[source.id] {
                connection.noteContinuation = continuation
                self.connections[source.id] = connection
                debugPrint(icon: "💦", message: "Note Stream for \(source.name) was created")
            }
            else {
                debugPrint(icon: "💦", message: "Failed to create Note Stream for \(source.name)")
            }
            
                // Always remove continuations when no longer needed
            continuation.onTermination = { _ in
                Task {
                    await self.removeNoteContinuation(for: source.id)
                }
            }
        }
    }
    
    
    // MARK: Stream Cleanup

    private func removeSysExContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.sysexContinuation = nil
        debugPrint(icon: "💦", message: "Removed SysEx Stream for \(deviceID)")
    }
    
    
    private func removeCCContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.ccContinuation = nil
        debugPrint(icon: "💦", message: "Removed CC Stream for \(deviceID)")
    }
    
    
    private func removeNoteContinuation(for deviceID: MIDIUniqueID) {
        connections[deviceID]?.noteContinuation = nil
        debugPrint(icon: "💦", message: "Removed Note Stream for \(deviceID)")
    }
    
    
    // MARK: - Stream Notificaiton
    
    private func notifySysEx(_ data: [UInt8]) {
        debugPrint(icon: "🚨", message: "Yielding SysEx data to \(connections.count) connections")
        
        // Only used for Debugging
        var yieldcount = 0
        
        for (deviceID, connection) in connections {
            if let sysexCont = connection.sysexContinuation {
                sysexCont.yield(data)
                yieldcount += 1
                debugPrint(icon: "🚨", message: "Yielding SysEx data to \(deviceID)")
            }
            else {
                debugPrint(icon: "💥", message: "No continuation for \(deviceID)")
            }
        }
        
        debugPrint(icon: "📊", message: "Yielding to \(yieldcount) streams")
    }
    
    
    private func notifyCC(channel: UInt8, cc: UInt8, value: UInt8) {
        debugPrint(icon: "🎛️", message: "Yielding Continuous Controller data to \(connections.count) connections")
        
        for (deviceID, connection) in connections {
            if let ccCont = connection.ccContinuation {
                ccCont.yield((channel, cc, value))
            }
            else {
                debugPrint(icon: "🎛️", message: "Unable to get Continuous Controller continuation for \(deviceID)")
            }

        }
    }

    
    private func notifyNote(isNoteOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8) {
        debugPrint(icon: "🎛️", message: "Yielding Note (\(isNoteOn ? "On" : "Off")) to \(connections.count) connections")
        
        for (deviceID, connection) in connections {
            if let ccCont = connection.noteContinuation {
                ccCont.yield((isNoteOn: isNoteOn, channel: channel, note: note, velocity: velocity))
            }
            else {
                debugPrint(icon: "🎛️", message: "Unable to get Note (\(isNoteOn ? "On" : "Off")) continuation for \(deviceID)")
            }
        }
    }

}

