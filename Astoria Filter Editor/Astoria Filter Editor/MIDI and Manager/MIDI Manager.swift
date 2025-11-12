//
//  MIDI Manager.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import CoreMIDI



final class MIDIManager {
    static let shared = MIDIManager()
    private init() {}
    
    
        /// Represents the Application
    private var midiClient: MIDIClientRef = 0
    
        /// 'Input' into client
    private var inputPort: MIDIPortRef = 0
    
        /// 'Output' from client
    private var outputPort: MIDIPortRef = 0
    
    
    func initializeMIDI() throws {
        debugPrint(icon: "🆕", message: "Initializing MIDI")
        try createMIDIClient()
        try createInputPort()
        try createOutputPort()
    }
    
    
    // MARK: - Client
    
    /// Create App's MIDI Client
    private func createMIDIClient() throws {
        let status = MIDIClientCreate("Astoria Filter Editor" as CFString, // Name of app
                                      notificationCallback, // callback for MIDI System Notifications
                                      nil,                  // Context of notification -> Not currently used
                                      &midiClient)         // The app's client
        
        guard status == noErr
        else { throw MIDIError.clientCreationFailed(status) }
        
        debugPrint(icon: "🎹", message: "Client Created")
    }
    
    
    /// Called when MIDI System changes occur
    private var notificationCallback: MIDINotifyProc = { notification, refCon in
        switch notification.pointee.messageID {
            case .msgObjectAdded: print("MIDI Device Added")
            case .msgObjectRemoved: print("MIDI Device Removed")
            case .msgPropertyChanged: print("MIDI Device Property Changed")
            case .msgSetupChanged: print("MIDI System Setup Changed")
            default: print("Some other MIDI System Notification: \(notification.pointee.messageID.rawValue)")
        }
    }
    
    
        // MARK: - Input Port
    
    /// Create App's Input Port
    private func createInputPort() throws {
        let readCallback: MIDIReceiveBlock = { eventList, srcRefCon in
            guard let srcRefCon else { return }
            
            let manager = Unmanaged<MIDIManager>
                .fromOpaque(srcRefCon)
                .takeUnretainedValue()
            
            manager.receiveMIDIData(eventList)
        }
        
        
        // Create input port with MIDI 1.0 protocol
        let status: OSStatus = MIDIInputPortCreateWithProtocol(
            midiClient,
            "SysEx Input" as CFString,
            ._1_0,
            &inputPort,
            readCallback
        )
        
        guard status == noErr
        else { throw MIDIError.portCreationFailed(status) }
        
        debugPrint(icon: "➡️", message: "Input Port Created")
    }
    
    
    
    private func createOutputPort() throws {
        MIDIDestinationCreateWithProtocol(midiClient, "SysEx Output" as CFString, ._1_0, &outputPort) { [weak self] evtList, srcConnRef in
            
        }
//        let status = MIDIOutputPortCreate(midiClient,
//                                          "SysEx Output" as CFString,
//                                          &outputPort)
        
//        guard status == noErr
//        else { throw MIDIError.portCreationFailed(status) }
//        
        debugPrint(icon: "⬅️", message: "Output Port Created")
    }
    
    
    // MARK: Callbacks
    
    private func receiveMIDIData(_ eventListPtr: UnsafePointer<MIDIEventList>) {
        let list = eventListPtr.pointee
        var packetPtr: UnsafePointer<MIDIEventPacket> = withUnsafePointer(to: list.packet) { $0 }
        
        for _ in 0..<list.numPackets {
            let packet = packetPtr.pointee
            let wordCount = Int(packet.wordCount)
            
            var words: [UInt32] = []
            words.reserveCapacity(wordCount)
            
            for j in 0..<wordCount {
//                words.append(packet.words.advanced(by: j).pointee)
            }
            
            print(words)
            
        }
    }
}


extension MIDIManager {
    func discoverSources() -> [MIDIDeviceInfo] {
        var devices: [MIDIDeviceInfo] = []
        
        let sourceCount = MIDIGetNumberOfSources()
        debugPrint(icon: "📡" , message: "Discovered \(sourceCount) MIDI Sources")
        
        for i in 0..<sourceCount {
            let endpoint = MIDIGetSource(i)
            
            if let info = getDeviceInfo(for: endpoint, isSource: true) {
                devices.append(info)
                debugPrint(icon: "📩", message: "Source: \(info.name) by \(info.manufacturer)")
            }
        }
        
        return devices
    }
    
    
    func discoverDestinations() -> [MIDIDeviceInfo] {
        var devices: [MIDIDeviceInfo] = []
        
        let destinationCount = MIDIGetNumberOfDestinations()
        
        debugPrint(icon: "📥" , message: "Discovered \(destinationCount) MIDI Destinations")
        
        for i in 0..<destinationCount {
            let endpoint = MIDIGetDestination(i)
            
            if let info = getDeviceInfo(for: endpoint, isSource: false) {
                devices.append(info)
                debugPrint(icon: "📦", message: "Destination: \(info.name) by \(info.manufacturer)")
            }
        }
        
        return devices
    }
   
    
    func connectToSource(_ endpoint: MIDIEndpointRef) throws {
        let status = MIDIPortConnectSource(inputPort,
                                           endpoint,
                                           nil)
        
        guard status == noErr else {
            throw MIDIError.connectionFailed(status)
        }
        
        debugPrint(icon: "🔌", message: "Successfully connected to source")
    }
    
    
    // MARK: - Private
    
    private func getDeviceInfo(for endpoint: MIDIEndpointRef, isSource: Bool) -> MIDIDeviceInfo? {
        var name: Unmanaged<CFString>?
        var manufacturer: Unmanaged<CFString>?
        var uniqueID: Int32 = 0
        
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyManufacturer, &manufacturer)
        MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
        
        let deviceName = name?.takeRetainedValue() as String?  ?? "Unknown Device"
        let mfr = manufacturer?.takeRetainedValue() as String?  ?? "Unknown"
        
        return MIDIDeviceInfo(endpoint: endpoint,
                              name: deviceName,
                              manufacturer: mfr,
                              uniqueID: uniqueID,
                              isSource: isSource)
    }
    
    
//    private func handleIncomingPackets(_ eventList: UnsafePointer<MIDIEventList>) {
//        let numPackets = eventList.pointee.numPackets
//        debugPrint(message: "Received \(numPackets) packet(s)")
//        
//        var currentEventPacket = eventList.pointee.packet
//        var packetPtr = withUnsafeMutablePointer(to: &currentEventPacket) { $0 }
//        
//        for i in 0..<numPackets {
//            let packet = packetPtr.pointee
//            
//            processPacket(packet)
//            
//            if i < numPackets - 1 {
//                packetPtr = MIDIEventPacketNext(packetPtr)
//            }
//        }
//        
//        MIDIEventListForEachEvent(eventList, <#T##visitor: MIDIEventVisitor!##MIDIEventVisitor!##(UnsafeMutableRawPointer?, MIDITimeStamp, MIDIUniversalMessage) -> Void#>, <#T##visitorContext: UnsafeMutableRawPointer!##UnsafeMutableRawPointer!#>)
//    }
//    
//    
//    private func processPacket(_ packet: MIDIEventPacket) {
//        let length = Int(packet.wordCount)
//        
//        guard length > 0
//        else { return }
//        
//        var bytes: []
//    }
}

