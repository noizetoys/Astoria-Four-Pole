//
//  MIDIError.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation


enum MIDIError: Error {
    case clientCreationFailed(OSStatus)
    case portCreationFailed(OSStatus)
    case connectionFailed(OSStatus)
    case sendFailed(OSStatus)
    case invalidMIDIData
    case deviceNotAvailable
    
    
    func printError() {
        switch self {
            case .clientCreationFailed(let status): debugPrint(message: "Failed to create MIDI client with status \(status)")
            case .portCreationFailed(let status): debugPrint(message: "Failed to create MIDI port with status \(status)")
            case .connectionFailed(let status): debugPrint(message: "Failed to connect MIDI port with status \(status)")
            case .sendFailed(let status): debugPrint(message: "Failed to send MIDI message with status \(status)")
            case .invalidMIDIData: debugPrint(message: "Invalid MIDI data")
            case .deviceNotAvailable: debugPrint(message: "MIDI device not available")
        }
    }
    
}
