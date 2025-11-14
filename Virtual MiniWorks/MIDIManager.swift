//
//  MIDIManager.swift
//  Virtual Waldorf 4 Pole Filter
//

import Foundation
import CoreMIDI

class MIDIManager: ObservableObject {
    static let shared = MIDIManager()
    
    @Published var availableSources: [MIDIEndpointRef] = []
    @Published var availableDestinations: [MIDIEndpointRef] = []
    @Published var selectedSource: MIDIEndpointRef?
    @Published var selectedDestination: MIDIEndpointRef?
    @Published var isConnected = false
    @Published var receivedMessages: [MIDIMessage] = []
    @Published var sentMessages: [MIDIMessage] = []
    
    private var midiClient = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var outputPort = MIDIPortRef()
    
    private init() {
        setupMIDI()
        refreshPorts()
    }
    
    private func setupMIDI() {
        var status = MIDIClientCreate("VirtualMiniWorks" as CFString, nil, nil, &midiClient)
        
        if status == noErr {
            status = MIDIInputPortCreate(midiClient, "Input" as CFString, midiReadProc, 
                                        Unmanaged.passUnretained(self).toOpaque(), &inputPort)
        }
        
        if status == noErr {
            status = MIDIOutputPortCreate(midiClient, "Output" as CFString, &outputPort)
        }
        
        if status != noErr {
            print("Failed to create MIDI client: \(status)")
        }
    }
    
    func refreshPorts() {
        // Get sources
        let sourceCount = MIDIGetNumberOfSources()
        availableSources = (0..<sourceCount).compactMap { MIDIGetSource($0) }
        
        // Get destinations
        let destCount = MIDIGetNumberOfDestinations()
        availableDestinations = (0..<destCount).compactMap { MIDIGetDestination($0) }
    }
    
    func connectToSource(_ source: MIDIEndpointRef) {
        if let oldSource = selectedSource {
            MIDIPortDisconnectSource(inputPort, oldSource)
        }
        
        let status = MIDIPortConnectSource(inputPort, source, nil)
        if status == noErr {
            selectedSource = source
            updateConnectionStatus()
        }
    }
    
    func selectDestination(_ destination: MIDIEndpointRef) {
        selectedDestination = destination
        updateConnectionStatus()
    }
    
    func sendSysEx(_ data: Data) {
        guard let destination = selectedDestination else {
            print("No destination selected")
            return
        }
        
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            let ptr = bytes.bindMemory(to: UInt8.self)
            packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, data.count, ptr.baseAddress!)
        }
        
        let status = MIDISend(outputPort, destination, &packetList)
        
        DispatchQueue.main.async {
            let message = MIDIMessage(
                timestamp: Date(),
                direction: .sent,
                data: data,
                description: self.describeSysExMessage(data)
            )
            self.sentMessages.insert(message, at: 0)
            if self.sentMessages.count > 100 {
                self.sentMessages.removeLast()
            }
        }
        
        if status != noErr {
            print("Failed to send MIDI: \(status)")
        }
    }
    
    func getName(for endpoint: MIDIEndpointRef) -> String {
        var name: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
        
        if status == noErr, let name = name {
            return name.takeRetainedValue() as String
        }
        return "Unknown Device"
    }
    
    private func updateConnectionStatus() {
        isConnected = selectedSource != nil && selectedDestination != nil
    }
    
    private func describeSysExMessage(_ data: Data) -> String {
        guard data.count >= 5 else { return "Invalid SysEx" }
        
        let bytes = [UInt8](data)
        
        guard bytes[0] == 0xF0 && bytes.last == 0xF7 else {
            return "Invalid SysEx (missing F0/F7)"
        }
        
        guard bytes[1] == 0x3E && bytes[2] == 0x04 else {
            return "SysEx (not MiniWorks)"
        }
        
        let commandByte = bytes[4]
        
        switch commandByte {
        case 0x00:
            let program = bytes.count > 5 ? bytes[5] : 0
            return "Program Dump (Program \(program + 1))"
        case 0x01:
            let program = bytes.count > 5 ? bytes[5] : 0
            return "Program Bulk Dump (Program \(program + 1))"
        case 0x08:
            return "All Dump (Programs 1-20 + Globals)"
        case 0x40:
            let program = bytes.count > 5 ? bytes[5] : 0
            return "Program Dump Request (Program \(program + 1))"
        case 0x41:
            let program = bytes.count > 5 ? bytes[5] : 0
            return "Program Bulk Dump Request (Program \(program + 1))"
        case 0x48:
            return "All Dump Request"
        default:
            return "Unknown SysEx Command: 0x\(String(format: "%02X", commandByte))"
        }
    }
}

// MIDI Read Callback
private func midiReadProc(packetList: UnsafePointer<MIDIPacketList>, 
                         readProcRefCon: UnsafeMutableRawPointer?,
                         srcConnRefCon: UnsafeMutableRawPointer?) {
    guard let refCon = readProcRefCon else { return }
    let manager = Unmanaged<MIDIManager>.fromOpaque(refCon).takeUnretainedValue()
    
    var packet = packetList.pointee.packet
    
    for _ in 0..<packetList.pointee.numPackets {
        let data = Data(bytes: &packet.data, count: Int(packet.length))
        
        DispatchQueue.main.async {
            let message = MIDIMessage(
                timestamp: Date(),
                direction: .received,
                data: data,
                description: manager.describeSysExMessage(data)
            )
            manager.receivedMessages.insert(message, at: 0)
            if manager.receivedMessages.count > 100 {
                manager.receivedMessages.removeLast()
            }
            
            // Handle requests
            manager.handleReceivedMessage(data)
        }
        
        packet = MIDIPacketNext(&packet).pointee
    }
}

extension MIDIManager {
    func handleReceivedMessage(_ data: Data) {
        guard data.count >= 5 else { return }
        
        let bytes = [UInt8](data)
        
        guard bytes[0] == 0xF0 && bytes[1] == 0x3E && bytes[2] == 0x04 else {
            return // Not a MiniWorks message
        }
        
        let commandByte = bytes[4]
        
        switch commandByte {
        case 0x40: // Program Dump Request
            if bytes.count > 5 {
                let programNumber = bytes[5]
                NotificationCenter.default.post(
                    name: .programDumpRequested,
                    object: nil,
                    userInfo: ["programNumber": programNumber]
                )
            }
            
        case 0x41: // Program Bulk Dump Request
            if bytes.count > 5 {
                let programNumber = bytes[5]
                NotificationCenter.default.post(
                    name: .programBulkDumpRequested,
                    object: nil,
                    userInfo: ["programNumber": programNumber]
                )
            }
            
        case 0x48: // All Dump Request
            NotificationCenter.default.post(
                name: .allDumpRequested,
                object: nil
            )
            
        default:
            break
        }
    }
}

struct MIDIMessage: Identifiable {
    let id = UUID()
    let timestamp: Date
    let direction: Direction
    let data: Data
    let description: String
    
    enum Direction {
        case sent, received
    }
    
    var hexString: String {
        data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    
    var byteCount: Int {
        data.count
    }
}

extension Notification.Name {
    static let programDumpRequested = Notification.Name("programDumpRequested")
    static let programBulkDumpRequested = Notification.Name("programBulkDumpRequested")
    static let allDumpRequested = Notification.Name("allDumpRequested")
}
