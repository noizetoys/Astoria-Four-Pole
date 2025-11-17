//
//  MIDIError.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation


enum MIDIError: Error, LocalizedError {
    case clientCreationFailed(OSStatus)
    case portCreationFailed(OSStatus)
    
    case deviceNotAvailable
    case connectionFailed(OSStatus)
    
//    case sendFailed(OSStatus)
    case sendFailed(String)
    
    case invalidSysEx(String)
    case invalidMIDIMessage(String)
    
    
    func printError() {
        switch self {
            case .clientCreationFailed(let status): debugPrint(message: "Failed to create MIDI client with status \(status)")
            case .portCreationFailed(let status): debugPrint(message: "Failed to create MIDI port with status \(status)")
                
            case .deviceNotAvailable: debugPrint(message: "MIDI device not available")
            case .connectionFailed(let status): debugPrint(message: "Failed to connect MIDI port with status \(status)")
                
            case .sendFailed(let message): debugPrint(message: "Failed to send MIDI message: \(message)")
                
            case .invalidSysEx(let string): debugPrint(message: "Invalid Sys Ex Message: \(string)")
            case .invalidMIDIMessage(let string): debugPrint(message: "Invalid MIDI Message: \(string)")
        }
    }
    
}
