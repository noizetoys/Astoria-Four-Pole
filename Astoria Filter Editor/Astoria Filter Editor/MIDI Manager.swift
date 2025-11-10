//
//  MIDI Manager.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/9/25.
//

import Foundation
import CoreMIDI

// MARK: - MIDIManagerDelegate
public protocol MIDIManagerDelegate: AnyObject {
    /// Called when a complete SysEx message is received on any input source.
    func midiManager(_ manager: MIDIManager, didReceiveSysEx data: Data, from sourceName: String)
    /// Called when the available MIDI destinations change (e.g., devices connected/disconnected).
    func midiManagerDestinationsDidChange(_ manager: MIDIManager)
    /// Called when the available MIDI sources change.
    func midiManagerSourcesDidChange(_ manager: MIDIManager)
}

// MARK: - MIDIManager
public final class MIDIManager {
    public weak var delegate: MIDIManagerDelegate?

    // Public model of endpoints for UI binding
    public private(set) var destinations: [MIDIEndpointRef] = []
    public private(set) var destinationNames: [String] = []
    public private(set) var sources: [MIDIEndpointRef] = []
    public private(set) var sourceNames: [String] = []

    // Core MIDI objects
    private var client: MIDIClientRef = 0
    private var inPort: MIDIPortRef = 0
    private var outPort: MIDIPortRef = 0

    // Buffer for assembling incoming SysEx
    private var sysexAssembler = Data()
    private let accessQueue = DispatchQueue(label: "MIDIManager.access.queue", attributes: .concurrent)

    public init() {
        setupClient()
        refreshEndpoints()
    }

    deinit {
        if inPort != 0 { MIDIPortDispose(inPort) }
        if outPort != 0 { MIDIPortDispose(outPort) }
        if client != 0 { MIDIClientDispose(client) }
    }

    // MARK: Setup
    private func setupClient() {
        var notifyBlock: MIDINotifyBlock? = { [weak self] messagePtr in
            guard let self = self
            else { return }
            
            let messageID = messagePtr.pointee.messageID
            switch messageID {
            case .msgObjectAdded, .msgObjectRemoved, .msgPropertyChanged, .msgThruConnectionsChanged, .msgSerialPortOwnerChanged, .msgIOError:
                self.refreshEndpoints()
                case .msgSetupChanged: self.refreshEndpoints()
                @unknown default:
                break
            }
        }

        var readBlock: MIDIReadBlock? = { [weak self] packetListPtr, _ in
            guard let self = self
            else { return }
            
            let packetList = packetListPtr.pointee
            var packet = packetList.packet
            for _ in 0..<packetList.numPackets {
                let bytes = withUnsafeBytes(of: packet.data) { rawPtr -> [UInt8] in
                    let count = Int(packet.length)
                    return Array(rawPtr.prefix(count))
                }
                self.handleIncoming(bytes: bytes)
                packet = MIDIPacketNext(&packet).pointee
            }
        }

        // Create client
        let statusClient = MIDIClientCreateWithBlock("Astoria MIDI Client" as CFString, &client, notifyBlock)
        if statusClient != noErr {
            print("MIDIClientCreateWithBlock error: \(statusClient)")
        }

        // Create input and output ports
        guard let readBlock else { return }
        
        let statusIn = MIDIInputPortCreateWithBlock(client, "Astoria Input" as CFString, &inPort, readBlock)
        if statusIn != noErr { print("MIDIInputPortCreateWithBlock error: \(statusIn)") }
        let statusOut = MIDIOutputPortCreate(client, "Astoria Output" as CFString, &outPort)
        if statusOut != noErr { print("MIDIOutputPortCreate error: \(statusOut)") }

        // Connect to all sources by default
        connectAllSources()
    }

    // MARK: Endpoint management
    public func refreshEndpoints() {
        accessQueue.async(flags: .barrier) {
            self.destinations.removeAll()
            self.destinationNames.removeAll()
            self.sources.removeAll()
            self.sourceNames.removeAll()

            let destCount = MIDIGetNumberOfDestinations()
            for i in 0..<destCount {
                let dest = MIDIGetDestination(i)
                self.destinations.append(dest)
                self.destinationNames.append(self.name(of: dest) ?? "Destination #\(i)")
            }

            let srcCount = MIDIGetNumberOfSources()
            for i in 0..<srcCount {
                let src = MIDIGetSource(i)
                self.sources.append(src)
                self.sourceNames.append(self.name(of: src) ?? "Source #\(i)")
                if self.inPort != 0 {
                    MIDIPortConnectSource(self.inPort, src, nil)
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.midiManagerDestinationsDidChange(self)
            self.delegate?.midiManagerSourcesDidChange(self)
        }
    }

    private func connectAllSources() {
        let srcCount = MIDIGetNumberOfSources()
        for i in 0..<srcCount {
            let src = MIDIGetSource(i)
            MIDIPortConnectSource(inPort, src, nil)
        }
    }

    private func name(of endpoint: MIDIObjectRef) -> String? {
        var cfName: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &cfName)
        if status == noErr, let name = cfName?.takeRetainedValue() as String? {
            return name
        }
        return nil
    }

    // MARK: Sending SysEx
    public func sendSysEx(_ data: Data, toDestinationAt index: Int) {
        accessQueue.async {
            guard index >= 0 && index < self.destinations.count else {
                print("Invalid destination index")
                return
            }
            guard self.outPort != 0 else { return }

            // Create an immutable copy to ensure stable storage during the send
            let buffer = data
            let count = buffer.count
            
            buffer.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                guard let base = ptr.baseAddress else { return }
                var list = MIDISysexSendRequest(
                    destination: self.destinations[index],
                    data: base.assumingMemoryBound(to: UInt8.self),
                    bytesToSend: UInt32(count),
                    complete: false,
                    reserved: (0, 0, 0),
                    completionProc: { _ in
                        // request memory is owned by caller; nothing to free here
                    },
                    completionRefCon: nil
                )
                let status = MIDISendSysex(&list)
                if status != noErr {
                    print("MIDISendSysex error: \(status)")
                }
            }
        }
    }

    /// Convenience to send SysEx from hex string like "F0 00 01 02 F7"
    public func sendSysEx(hexString: String, toDestinationAt index: Int) {
        let filtered = hexString.replacingOccurrences(of: "0x", with: "").replacingOccurrences(of: ",", with: " ")
        let parts = filtered.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
        var bytes: [UInt8] = []
        bytes.reserveCapacity(parts.count)
        for p in parts {
            if let b = UInt8(p, radix: 16) {
                bytes.append(b)
            }
        }
        sendSysEx(Data(bytes), toDestinationAt: index)
    }

    // MARK: Receiving SysEx
    private func handleIncoming(bytes: [UInt8]) {
        // Assemble SysEx messages (F0 ... F7). There may be multiple in one packet.
        var idx = 0
        
        while idx < bytes.count {
            let byte = bytes[idx]
            
            if byte == 0xF0 { // start of SysEx
                sysexAssembler.removeAll(keepingCapacity: true)
                sysexAssembler.append(byte)
            }
            else if !sysexAssembler.isEmpty {
                sysexAssembler.append(byte)
                
                if byte == 0xF7 { // end of SysEx
                    let message = sysexAssembler
                    sysexAssembler.removeAll(keepingCapacity: true)
                    
                    let sourceName = "Unknown Source"
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.midiManager(self, didReceiveSysEx: message, from: sourceName)
                    }
                }
            }
            
            idx += 1
        }   // while
        
    }
}


extension Data {
    /// Returns space-separated uppercase hex string, e.g., "F0 00 20 33 F7"
    public var hexString: String {
        self.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
