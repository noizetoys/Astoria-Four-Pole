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
    
    
    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var outputPort: MIDIPortRef = 0
    
    /// Holds Connections (and thier Continuations)
    private var connections: [MIDIUniqueID: DeviceConnection] = [:]
    private var sysexBuffer: [UInt8] = []

    
    // MARK: - Lifecycle
    
    private init() {
        Task {
            do {
                try await initializeMIDI()
            }
            catch {
                fatalError("Failed to initialize MIDI: \(error)")
            }
        }
    }
    
    
    func initializeMIDI() throws {
        debugPrint(icon: "🆕🎹", message: "Initializing MIDI")
        
        try createMIDIClient()
        try createInputPort()
        try createOutputPort()
    }
    
    
    deinit {
        // Can't call 'disconnectAll()' from here
        // Have to duplicate the code
        for (_, connection) in connections {
            if let source = connection.source {
                MIDIPortDisconnectSource(inputPort, source.endpoint)
            }
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
        else {
            debugPrint(icon: "❌🎹", message: "Status Error: \(status.description)")
            throw MIDIError.clientCreationFailed(status)
        }
        
//        Task {
//            debugPrint(icon: "🎹👍🏻", message: "Client Created")
//        }
    }
    
    /**
     @enum        MIDINotificationMessageID
     @abstract    Signifies the type of a MIDINotification.
     
     @constant    kMIDIMsgSetupChanged
        Some aspect of the current MIDISetup has changed.  No data.  Should ignore this message if
        messages 2-6 are handled.
     @constant    kMIDIMsgObjectAdded
        A device, entity or endpoint was added. Structure is MIDIObjectAddRemoveNotification. New in
        Mac OS X 10.2.
     @constant    kMIDIMsgObjectRemoved
        A device, entity or endpoint was removed. Structure is MIDIObjectAddRemoveNotification. New
        in Mac OS X 10.2.
     @constant    kMIDIMsgPropertyChanged
        An object's property was changed. Structure is MIDIObjectPropertyChangeNotification. New in
        Mac OS X 10.2.
     @constant    kMIDIMsgThruConnectionsChanged
        A persistent MIDI Thru connection was created or destroyed.  No data.  New in Mac OS X 10.2.
     @constant    kMIDIMsgSerialPortOwnerChanged
        No data.  New in Mac OS X 10.2.
     @constant    kMIDIMsgIOError
        A driver I/O error occurred.
     */

    
    /// Called when MIDI System changes occur
    private func MIDINotificationHander(_ notification: UnsafePointer<MIDINotification>) {
        let id = notification.pointee.messageID
        var message: String = ""
        
        switch id {
            case .msgObjectAdded: message = "🎹 MIDI Device Added 🎹"
            case .msgObjectRemoved: message = "🎹 MIDI Device Removed 🎹"
            case .msgPropertyChanged: message = "🎹 MIDI Device Property Changed 🎹"
            case .msgSetupChanged: message = "🎹 MIDI System Setup Changed 🎹"
            default: message = "Some other MIDI System Notification: \(notification.pointee.messageID.rawValue)"
        }
        
//        debugPrint(icon: "📡", message: "MIDI Notifcation recieved!  \(id) --> \(message)")
    }
    
    
        // MARK: - Input Port
    
    private func createInputPort() throws {
        let status = MIDIInputPortCreateWithBlock(midiClient,
                                                  "MIDI Service Input" as CFString,
                                                  &inputPort) { [weak self] packetList, _ in
            // Pointers and Data must be copies, pointer will go out of scope at end of method
            let numPackets = packetList.pointee.numPackets
            var copiedPackets: [[UInt8]] = []
//            print("\n🎹 MIDI Callback fired! numPackets: \(numPackets)")

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
        }
        
        guard status == noErr
        else {
            debugPrint(icon: "❌🎹", message: "Status Error: \(status.description)")
            throw MIDIError.portCreationFailed(status)
        }
        
//        debugPrint(icon: "➡️👍🏻", message: "Input Port Created")
    }
    
    
    // MARK: - Output Port
    
    private func createOutputPort() throws {
        let status = MIDIOutputPortCreate(midiClient,
                                          "MIDI Service Output" as CFString,
                                          &outputPort)
        
        guard status == noErr
        else {
            debugPrint(icon: "❌🎹", message: "Status Error: \(status.description)")
            throw MIDIError.portCreationFailed(status)
        }
        
//        debugPrint(icon: "⬅️👍🏻", message: "Output Port Created")
    }
    

// MARK: - Connecting/Disconnecting Devices

    func availableSources() -> [MIDIDevice] {
        var devices: [MIDIDevice] = []
        
        let sourceCount = MIDIGetNumberOfSources()
//        debugPrint(icon: "📡" , message: "Discovered \(sourceCount) MIDI Sources")
        
        for i in 0..<sourceCount {
            let endpoint = MIDIGetSource(i)
            
            if let device = try? MIDIDevice(endpoint: endpoint, type: .source) {
                devices.append(device)
//                debugPrint(icon: "📩", message: "Source: \(device.name) by \(device.manufacturer)")
            }
        }
        
        return devices
    }
    
    
    func availableDestinations() -> [MIDIDevice] {
        var devices: [MIDIDevice] = []
        
        let destinationCount = MIDIGetNumberOfDestinations()
        
//        debugPrint(icon: "📥" , message: "Discovered \(destinationCount) MIDI Destinations")
        
        for i in 0..<destinationCount {
            let endpoint = MIDIGetDestination(i)
            
                // If not a valid endpoint, move on to next 'i'
            if endpoint == 0 { continue }
            
            if let device = try? MIDIDevice(endpoint: endpoint, type: .destination) {
                devices.append(device)
                debugPrint(icon: "📦", message: "Destination: \(device.name) by \(device.manufacturer)", type: .trace)
            }
        }
        
        return devices
    }
    
    
        // MARK: Connect/Disconnect
    
    func connect(source: MIDIDevice?, destination: MIDIDevice) throws {
//        debugPrint(icon: "🔌", message: "Connecting \(source.name) to \(destination.name)")
        
        let id: MIDIUniqueID = source?.id ?? destination.id
        
        connections[id] = DeviceConnection(source: source, destination: destination)

        guard
            let source
        else {
            Task { @MainActor in
                NotificationCenter.default.post(name: .midiSourceConnected, object: nil)
            }

            return
        }
        
        let status = MIDIPortConnectSource(inputPort, source.endpoint, nil)
        
        guard status == noErr
        else {
            connections.removeValue(forKey: source.id)
            debugPrint(icon: "❌🔌", message: "Status Error: \(status.text)")
            throw MIDIError.connectionFailed(status)
        }
        
//        Task { @MainActor in
//            NotificationCenter.default.post(name: .midiSourceConnected, object: nil)
//        }
        
        debugPrint(icon: "🔌👍🏻", message: "\(source.name) now connected to \(destination.name)\nconnections count: \(connections.count)")
    }
    
    
    func disconnect(from source: MIDIDevice) {
        debugPrint(icon: "🔌", message: "Disconnecting from \(source.name)")
        
        MIDIPortDisconnectSource(inputPort, source.endpoint)
        connections.removeValue(forKey: source.id)
        
        Task { @MainActor in
            NotificationCenter.default.post(name: .midiSourceDisconnected, object: nil)
        }
        
        debugPrint(icon: "🔌👍🏻", message: "Now disconnect from \(source.name)")
    }
    
    
    func disconnectAll() {
        debugPrint(icon: "🔌", message: "Disconnecting all devices")
        
        for (_, connection) in connections {
            if let source = connection.source {
            MIDIPortDisconnectSource(inputPort, source.endpoint)
            }
        }
        
        connections.removeAll()
        
        Task {
            NotificationCenter.default.post(name: .midiSourceDisconnected, object: nil)
        }
        debugPrint(icon: "🔌👍🏻", message: "All devices now Disconnected")
    }
    

    private func handleIncomingPacketData(_ packets: [[UInt8]]) {
        debugPrint(icon: "🔄", message: "Enumerating MIDI devices...")
        
        for (i, bytes) in packets.enumerated() {
            debugPrint(icon: "🔄", message: "Handling \(bytes.count) byte packet \(i + 1)")
            
            processPacketBytes(bytes)
        }
    }
    
    
    private func processPacketBytes(_ bytes: [UInt8]) {
        debugPrint(message: "Bytes: \(bytes.hexString)")
//        print("\(#function): Bytes: \(bytes.hexString)")

        
        var i = 0
        
        while i < bytes.count {
            let byte = bytes[i]
            
                // SysEx Start
            if byte == 0xF0 {
                debugPrint(message: "SysEx message detected")
                sysexBuffer = [0xF0]
                i += 1
                
                while i < bytes.count {
                    let dataByte = bytes[i]
                    sysexBuffer.append(dataByte)
                    i += 1
                    
                        // End of SysEx
                    if dataByte == 0xF7 {
                        debugPrint(message: "End of SysEx message")
                        notifySysEx(sysexBuffer)
                        sysexBuffer.removeAll()
                        break
                    }
                }
                continue
            }
            
                // Continue collecting SysEx if already in progress
            if !sysexBuffer.isEmpty {
                sysexBuffer.append(byte)
                i += 1
                
                if byte == 0xF7 {
                    debugPrint(message: "End of SysEx message")
                    notifySysEx(sysexBuffer)
                    sysexBuffer.removeAll()
                }
                continue
            }
            
                // Status byte detection (bit 7 = 1)
            if byte & 0x80 != 0 {
                let messageType = byte & 0xF0
                let channel = byte & 0x0F
                
                switch messageType {
                    case 0x80: // Note Off
                        guard i + 2 < bytes.count else {
                            debugPrint(icon: "⚠️", message: "Incomplete Note Off message")
                            i += 1
                            continue
                        }
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        debugPrint(icon: "♬🔇", message: "Note Off - Ch: \(channel + 1), Note: \(note), Vel: \(velocity)")
//                        print("♬🔇 - Note Off - Ch: \(channel + 1), Note: \(note), Vel: \(velocity)")
                        notifyNote(isNoteOn: false, channel: channel, note: note, velocity: velocity)
                        i += 3
                        
                    case 0x90: // Note On
                        guard i + 2 < bytes.count else {
                            debugPrint(icon: "⚠️", message: "Incomplete Note On message")
                            i += 1
                            continue
                        }
                        let note = bytes[i + 1]
                        let velocity = bytes[i + 2]
                        
                            // Note On with velocity 0 is actually Note Off
                        if velocity == 0 {
//                            print("♬🔇: Note Off (via velocity 0) - Ch: \(channel + 1), Note: \(note)")
                            debugPrint(icon: "♬🔇", message: "Note Off (via velocity 0) - Ch: \(channel + 1), Note: \(note)")
                            notifyNote(isNoteOn: false, channel: channel, note: note, velocity: 0)
                        } else {
//                            print("♬🔇: Note On - Ch: \(channel + 1), Note: \(note), vel: \(velocity)")
                            debugPrint(icon: "♬🔈", message: "Note On - Ch: \(channel + 1), Note: \(note), Vel: \(velocity)")
                            notifyNote(isNoteOn: true, channel: channel, note: note, velocity: velocity)
                        }
                        i += 3
                        
                    case 0xA0: // Polyphonic Aftertouch (Poly Pressure)
                        guard i + 2 < bytes.count else {
                            debugPrint(icon: "⚠️", message: "Incomplete Poly Aftertouch message")
                            i += 1
                            continue
                        }
                        let note = bytes[i + 1]
                        let pressure = bytes[i + 2]
                        debugPrint(icon: "👆", message: "Poly Aftertouch - Ch: \(channel + 1), Note: \(note), Pressure: \(pressure)")
//                        notifyPolyAftertouch(channel: channel, note: note, pressure: pressure)
                        i += 3
                        
                    case 0xB0: // Control Change
                        guard i + 2 < bytes.count else {
                            debugPrint(icon: "⚠️", message: "Incomplete Control Change message")
                            i += 1
                            continue
                        }
                        let control = bytes[i + 1]
                        let value = bytes[i + 2]
                        debugPrint(icon: "🎛️", message: "Control Change - Ch: \(channel + 1), CC: \(control), Value: \(value)")
//                        print("🎛️ - Control Change - Ch: \(channel + 1), CC: \(control), Value: \(value)")
                        notifyCC(channel: channel, cc: control, value: value)
                        i += 3
                        
                    case 0xC0: // Program Change
                        guard i + 1 < bytes.count else {
                            debugPrint(icon: "⚠️", message: "Incomplete Program Change message")
                            i += 1
                            continue
                        }
                        let program = bytes[i + 1]
                        debugPrint(icon: "🎹", message: "Program Change - Ch: \(channel + 1), Program: \(program)")
                        notifyProgramChange(channel: channel, program: program)
                        i += 2
                        
                    case 0xD0: // Channel Aftertouch (Channel Pressure)
                        guard i + 1 < bytes.count else {
                            debugPrint(icon: "⚠️", message: "Incomplete Channel Aftertouch message")
                            i += 1
                            continue
                        }
                        let pressure = bytes[i + 1]
                        debugPrint(icon: "👇", message: "Channel Aftertouch - Ch: \(channel + 1), Pressure: \(pressure)")
//                        notifyChannelAftertouch(channel: channel, pressure: pressure)
                        i += 2
                        
                    case 0xE0: // Pitch Bend
                        guard i + 2 < bytes.count else {
                            debugPrint(icon: "⚠️", message: "Incomplete Pitch Bend message")
                            i += 1
                            continue
                        }
                        let lsb = bytes[i + 1]
                        let msb = bytes[i + 2]
                            // Combine into 14-bit value (0-16383, center at 8192)
                        let pitchBendValue = Int(msb) << 7 | Int(lsb)
                        debugPrint(icon: "🎚️", message: "Pitch Bend - Ch: \(channel + 1), Value: \(pitchBendValue) (center: 8192)")
//                        notifyPitchBend(channel: channel, value: pitchBendValue)
                        i += 3
                        
                    case 0xF0: // System messages (already handled 0xF0 above, but handle others)
                        switch byte {
                            case 0xF1: // MIDI Time Code Quarter Frame
                                guard i + 1 < bytes.count else {
                                    debugPrint(icon: "⚠️", message: "Incomplete MTC Quarter Frame")
                                    i += 1
                                    continue
                                }
                                let data = bytes[i + 1]
                                debugPrint(icon: "🕐", message: "MTC Quarter Frame: \(data)")
//                                notifyMTCQuarterFrame(data: data)
                                i += 2
                                
                            case 0xF2: // Song Position Pointer
                                guard i + 2 < bytes.count else {
                                    debugPrint(icon: "⚠️", message: "Incomplete Song Position")
                                    i += 1
                                    continue
                                }
                                let lsb = bytes[i + 1]
                                let msb = bytes[i + 2]
                                let position = Int(msb) << 7 | Int(lsb)
                                debugPrint(icon: "📍", message: "Song Position: \(position)")
//                                notifySongPosition(position: position)
                                i += 3
                                
                            case 0xF3: // Song Select
                                guard i + 1 < bytes.count else {
                                    debugPrint(icon: "⚠️", message: "Incomplete Song Select")
                                    i += 1
                                    continue
                                }
                                let song = bytes[i + 1]
                                debugPrint(icon: "🎵", message: "Song Select: \(song)")
//                                notifySongSelect(song: song)
                                i += 2
                                
                            case 0xF6: // Tune Request
                                debugPrint(icon: "🎼", message: "Tune Request")
//                                notifyTuneRequest()
                                i += 1
                                
                            case 0xF8: // Timing Clock
                                debugPrint(icon: "⏱️", message: "Timing Clock")
//                                notifyTimingClock()
                                i += 1
                                
                            case 0xFA: // Start
                                debugPrint(icon: "▶️", message: "Start")
//                                notifyStart()
                                i += 1
                                
                            case 0xFB: // Continue
                                debugPrint(icon: "⏯️", message: "Continue")
//                                notifyContinue()
                                i += 1
                                
                            case 0xFC: // Stop
                                debugPrint(icon: "⏹️", message: "Stop")
//                                notifyStop()
                                i += 1
                                
                            case 0xFE: // Active Sensing
                                debugPrint(icon: "💓", message: "Active Sensing")
//                                notifyActiveSensing()
                                i += 1
                                
                            case 0xFF: // System Reset
                                debugPrint(icon: "🔄", message: "System Reset")
//                                notifySystemReset()
                                i += 1
                                
                            default:
                                debugPrint(icon: "❓", message: "Unknown system message: \(String(format: "0x%02X", byte))")
                                i += 1
                        }
                        
                    default:
                        debugPrint(icon: "❓", message: "Unknown message type: \(String(format: "0x%02X", messageType))")
                        i += 1
                }
            } else {
                    // Data byte without status (shouldn't happen in well-formed MIDI)
                debugPrint(icon: "⚠️", message: "Unexpected data byte: \(byte)")
                i += 1
            }
        }
    }
    

// MARK: - Sending MIDI
    
    func send(_ message: MIDIMessageType, to destination: MIDIDevice?) throws {
        debugPrint(message: "Attempting to send \(message) to \(destination?.name)", type: .info)
        
        guard
            let destination
        else {
            throw MIDIError.sendFailed("Invalid Destination")
        }
        
        let bytes = try encodeMessage(message)
        
        debugPrint(icon: "📤", message: "Sending \(bytes.count) to \(destination.name): \(bytes.hexString)", type: .info)
        
        var status: OSStatus = noErr
        
        do {
            status = try sendRawBytes(bytes, to: destination)
            
            if status != noErr {
                throw MIDIError.sendFailed(status.text)
            }
            else {
                debugPrint(icon: "📤", message: "\(bytes.count) bytes sent to \(destination.name), status: \(status.text)", type: .error)
            }
        }
        catch {
            debugPrint(icon: "❌📤", message: "Status Error: \(status.description)", type: .error)
            throw MIDIError.sendFailed(status.text)
        }
    }
    
    
    func sendSysEx(_ bytes: [UInt8], to destination: MIDIDevice?) throws {
        debugPrint(message: "Attempting to send \(bytes.hexString) to \(destination?.name)", type: .trace)
        
        guard
            let destination
        else {
            throw MIDIError.sendFailed("Invalid Destination")
        }
        
        var status: OSStatus = noErr
        
        do {
            status = try sendRawBytes(bytes, to: destination)
            
            if status != noErr {
                throw MIDIError.sendFailed(status.text)
            }
            else {
                debugPrint(icon: "📤", message: "\(bytes.count) bytes sent to \(destination.name), status: \(status.text)", type: .trace)
            }
        }
        catch {
            debugPrint(icon: "❌📤", message: "Status Error: \(status.description)", type: .error)
            throw MIDIError.sendFailed(status.text)
        }

    }
    
    
    func encodeMessage(_ message: MIDIMessageType) throws -> [UInt8] {
        debugPrint(icon: "⁉️", message: "Attempting to encode \(message)", type: .trace)
        switch message {
            case .sysex(let data):
                guard
                    data.first == 0xF0,
                    data.last == 0xF7
                else {
                    debugPrint(icon: "❌💾", message: "SysEx must start with 0xF0 and end with 0xF7", type: .error)
                    throw MIDIError.invalidSysEx("SysEx must start with 0xF0 and end with 0xF7")
                }
                
                return data
                
            case .noteOn(let channel, let note, let velocity):
                guard
                    channel < 16,
                    note < 128,
                    velocity < 128
                else {
                    debugPrint(icon: "❌♫🔈", message: "Invalid Note On parameters", type: .error)
                    throw MIDIError.invalidMIDIMessage("Invalid Note On parameters")
                }
                
                return [0x90 | channel, note, velocity]
                
            case .noteOff(let channel, let note, let velocity):
                guard channel < 16,
                      note < 128,
                      velocity < 128
                else {
                    debugPrint(icon: "❌♫🔇", message: "Invalid Note Off parameters", type: .error)
                    throw MIDIError.invalidMIDIMessage("Invalid Note Off parameters")
                }
                
                return [0x80 | channel, note, velocity]
                
            case .controlChange(let channel, let cc, let value):
                guard channel < 16,
                      cc < 128,
                      value < 128
                else {
                    debugPrint(icon: "❌🎛️", message: "Invalid CC parameters", type: .error)
                    throw MIDIError.invalidMIDIMessage("Invalid CC parameters")
                }
                
                return [0xB0 | channel, cc, value]
                
            case .programChange(let channel, let program):
                guard
                    channel < 16,
                    program < 128
                else {
                    debugPrint(icon: "❌🪙", message: "Invalid Program Change parameters")
                    throw MIDIError.invalidMIDIMessage("Invalid Program Change parameters")
                }
                
                return [0xC0 | channel, program]
                
            case .pitchBend(let channel, let value):
                guard
                    channel < 16,
                    value < 16384
                else {
                    debugPrint(icon: "❌🎛️", message: "Invalid Pitch Bend parameters")
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
                    debugPrint(icon: "❌🎛️", message: "Invalid Aftertouch parameters", type: .error)
                    throw MIDIError.invalidMIDIMessage("Invalid Aftertouch parameters")
                }
                
                return [0xD0 | channel, pressure]
                
            case .polyAftertouch(let channel, let note, let pressure):
                guard channel < 16,
                      note < 128,
                      pressure < 128
                else {
                    debugPrint(icon: "❌🎛️", message: "Invalid Poly Aftertouch parameters", type: .error)
                    throw MIDIError.invalidMIDIMessage("Invalid Poly Aftertouch parameters")
                }
                
                return [0xA0 | channel, note, pressure]
                
                /*
                 Start of SysEx
                 */
//            case .sysExProgramRequest(let channel, let program):
//                guard channel < 17,
//                      (0..<40).contains(program)
//                else {
//                    debugPrint(icon: "❌🎛️", message: "Invalid SysEx Message", type: .error)
//                    throw MIDIError.invalidSysEx("Invalid Channel \(channel) or program \(program)")
//                }
//                
//                return [SysExConstant.header, ]
//                
//            case .sysExAllDumpRequest(let channel):
                
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
            debugPrint(icon: "💾", message: "Creating SysEx Stream for \(source.name)")
            
            if var connection = self.connections[source.id] {
                connection.sysexContinuations.append(continuation)
                self.connections[source.id] = connection
                debugPrint(icon: "💾👍🏻", message: "SysEx Stream for \(source.name) was created")
            }
            else {
                debugPrint(icon: "💾❌", message: "Failed to create SysEx Stream for \(source.name)")
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
            debugPrint(icon: "🎛️", message: "Creating CC Stream for \(source.name)")
            
            if var connection = self.connections[source.id] {
                connection.ccContinuations.append(continuation)
//                connection.ccContinuation = continuation
                self.connections[source.id] = connection
                
                debugPrint(icon: "🎛️👍🏻", message: "CC Stream for \(source.name) was created")
            }
            else {
                debugPrint(icon: "🎛️❌", message: "Failed to create CC Stream for \(source.name)")
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
            debugPrint(icon: "♫", message: "Creating Note Stream for \(source.name)")
            
            if var connection = self.connections[source.id] {
                connection.noteContinuations.append(continuation)
//                connection.noteContinuation = continuation
                self.connections[source.id] = connection
                debugPrint(icon: "♫👍🏻", message: "Note Stream for \(source.name) was created")
            }
            else {
                debugPrint(icon: "♫❌", message: "Failed to create Note Stream for \(source.name)")
            }
            
                // Always remove continuations when no longer needed
            continuation.onTermination = { _ in
                Task {
                    await self.removeNoteContinuation(for: source.id)
                }
            }
        }
    }
    
    
    func programChangeStream(from source: MIDIDevice) -> AsyncStream<ProgramChangeEvent> {
        AsyncStream(bufferingPolicy: .bufferingNewest(3)) { continuation in
            debugPrint(icon: "🔃", message: "Creating Program Change Stream for \(source.name)")
            
            if var connection = self.connections[source.id] {
                connection.programChangeContinuations.append(continuation)
//                connection.programChangeContinuation = continuation
                self.connections[source.id] = connection
                
                debugPrint(icon: "🔃👍🏻", message: "Program Change Stream for \(source.name) was created")
            }
            else {
                debugPrint(icon: "🔃❌", message: "Failed to create Program Change Stream for \(source.name)")
            }
        }
    }
    
    
    // MARK: - Stream Cleanup

    private func removeSysExContinuation(for deviceID: MIDIUniqueID) {
//        connections[deviceID]?.sysexContinuation = nil
        connections[deviceID]?.sysexContinuations = []
        debugPrint(icon: "💾💦", message: "Removed SysEx Stream for \(deviceID)")
    }
    
    
    private func removeCCContinuation(for deviceID: MIDIUniqueID) {
//        connections[deviceID]?.ccContinuation = nil
        connections[deviceID]?.ccContinuations = []
        debugPrint(icon: "🎛️💦", message: "Removed CC Stream for \(deviceID)")
    }
    
    
    private func removeNoteContinuation(for deviceID: MIDIUniqueID) {
//        connections[deviceID]?.noteContinuation = nil
        connections[deviceID]?.noteContinuations = []
        debugPrint(icon: "♫💦", message: "Removed Note Stream for \(deviceID)")
    }
    
    
    private func removeProgramChangeContinuation(for deviceID: MIDIUniqueID) {
//        connections[deviceID]?.programChangeContinuation = nil
        connections[deviceID]?.programChangeContinuations = []
        debugPrint(icon: "🔃💦", message: "Removed Program Change Stream for \(deviceID)")
    }
    
    
    // MARK: - Stream Notificaiton
    
    private func notifySysEx(_ data: [UInt8]) {
        debugPrint(icon: "💾🚨", message: "Yielding SysEx data to \(connections.count) connections")
        
        // Only used for Debugging
        var yieldcount = 0
        
        for (deviceID, connection) in connections {
            for sysexCont in connection.sysexContinuations {
//                if let sysexCont = connection.sysexContinuation {
                    sysexCont.yield(data)
                    yieldcount += 1
                    debugPrint(icon: "💾🚨", message: "Yielding SysEx data to \(deviceID)")
//                }
//                else {
//                    debugPrint(icon: "💾❌", message: "No continuation for \(deviceID)")
//                }
            }
        }
        
        debugPrint(icon: "💾💦", message: "Yielding to \(yieldcount) streams")
    }
    
    
    private func notifyCC(channel: UInt8, cc: UInt8, value: UInt8) {
//        debugPrint(icon: "🎛️💦", message: "Yielding Continuous Controller data to \(connections.count) connections")
        
        for (deviceID, connection) in connections {
            for ccCont in connection.ccContinuations {
//            if let ccCont = connection.ccContinuation {
                ccCont.yield((channel, cc, value))
//            }
//            else {
//                debugPrint(icon: "🎛️💦", message: "Unable to get Continuous Controller continuation for \(deviceID)")
            }

        }
    }

    
    private func notifyNote(isNoteOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8) {
        debugPrint(icon: "♫💦", message: "Yielding Note (\(isNoteOn ? "On" : "Off")) to \(connections.count) connections")
        
        for (deviceID, connection) in connections {
            for noteCont in connection.noteContinuations {
//            if let ccCont = connection.noteContinuation {
                noteCont.yield((isNoteOn, channel, note, velocity))
//                ccCont.yield((isNoteOn: isNoteOn, channel: channel, note: note, velocity: velocity))
//            }
//            else {
//                debugPrint(icon: "♫💦", message: "Unable to get Note (\(isNoteOn ? "On" : "Off")) continuation for \(deviceID)")
            }
        }
    }
    
    
    private func notifyProgramChange(channel: UInt8, program: UInt8) {
        debugPrint(icon: "🔃💦", message: "Yielding ProgramChange (\(program)) to \(connections.count) connections")
        
        for (deviceID, connection) in connections {
            for pcCont in connection.programChangeContinuations {
//            if let pcCont = connetion.programChangeContinuation {
                pcCont.yield((channel, program))
//            }
//            else {
//                debugPrint(icon: "🔃💦", message: "Unable to get Program Change (\(program)) continuation for \(deviceID)")

            }
        }

        
    }

}

