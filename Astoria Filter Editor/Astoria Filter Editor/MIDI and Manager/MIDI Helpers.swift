//
//  MIDI Helpers.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import CoreMIDI


/*
 From: https://furnacecreek.org/blog/2024-04-06-modern-coremidi-event-handling-with-swift
 
 
 Usage:
        MIDIEventListForEach(list) { message, timestamp in
            switch message.type {
                case .channelVoice1:
 
                    switch message.channelVoice1.status {
                        case .noteOn:
 
                            self.handleNoteOn(message.channelVoice1.note.number,
                                              velocity: message.channelVoice1.note.velocity,
                                              timestamp: timestamp)
                            ...
                            
 */


typealias MIDIForEachBlock = (MIDIUniversalMessage, MIDITimeStamp) -> Void


final class MIDIForEachContext {
    var block: MIDIForEachBlock
    
    init(block: @escaping MIDIForEachBlock) {
        self.block = block
    }
}



func MIDIEventListForEach(_ list: UnsafePointer<MIDIEventList>, _ block: MIDIForEachBlock) {
    withoutActuallyEscaping(block) { escapingClosure in
        let context = MIDIForEachContext(block: escapingClosure)
        
        withExtendedLifetime(context) {
            let contextPointer = Unmanaged.passUnretained(context).toOpaque()
            MIDIEventListForEachEvent(list, { contextPointer, timestamp, message in
                guard let contextPointer
                else { return }
                
                let localContext = Unmanaged<MIDIForEachContext>
                    .fromOpaque(contextPointer)
                    .takeUnretainedValue()
                localContext.block(message, timestamp)
            }, contextPointer)
        }
        
    }
    
}

extension OSStatus {
    var text: String {
        switch self {
            case noErr: "Success (noErr)"
            case kMIDIInvalidClient: "Invalid MIDI Client (kMIDIInvalidClient)"
            case kMIDIInvalidPort: "Invalid MIDI Port (kMIDIInvalidPort)"
            case kMIDIWrongEndpointType: "Wrong Endpoint Type (kMIDIWrongEndpointType)"
            case kMIDINoConnection: "No Connection (kMIDINoConnection)"
            case kMIDIUnknownEndpoint: "Unknown Endpoint (kMIDIUnknownEndpoint)"
            case kMIDIUnknownProperty: "Unknown Property (kMIDIUnknownProperty)"
            case kMIDIWrongPropertyType: "Wrong Property Type (kMIDIWrongPropertyType)"
            case kMIDINoCurrentSetup: "No Current Setup (kMIDINoCurrentSetup)"
            case kMIDIMessageSendErr: "Message Send Error (kMIDIMessageSendErr)"
            case kMIDIServerStartErr: "Server Start Error (kMIDIServerStartErr)"
            case kMIDISetupFormatErr: "Setup Format Error (kMIDISetupFormatErr)"
            case kMIDIWrongThread: "Wrong Thread (kMIDIWrongThread)"
            case kMIDIObjectNotFound: "Object Not Found (kMIDIObjectNotFound)"
            case kMIDIIDNotUnique: "ID Not Unique (kMIDIIDNotUnique)"
            case kMIDINotPermitted: "Not Permitted (kMIDINotPermitted)"
            case kMIDIUnknownError: "Unknown Error (kMIDIUnknownError)"
            default: "Unknown OSStatus: \(self)"
        }
    }
}


extension Notification.Name {
    static let midiSetupChanged = Notification.Name("MIDI.SetupChanged")
    static let midiObjectAdded = Notification.Name("MIDI.ObjectAdded")
    static let midiObjectRemoved = Notification.Name("MIDI.ObjectRemoved")
    static let midiPropertyChanged = Notification.Name("MIDI.PropertyChanged")
    static let midiThruConnectionsChanged = Notification.Name("MIDI.ThruConnectionsChanged")
    static let midiSerialPortOwnerChanged = Notification.Name("MIDI.SerialPortOwnerChanged")
    static let midiIOError = Notification.Name("MIDI.IOError")
}


nonisolated
extension [UInt8] {
    var hexString: String {
        self.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}


nonisolated
extension UInt8 {
    var hexString: String {
        let hex = String(format: "%02x", self)
        return "\(Int(self)) or (hex) \(hex)"
    }
}

