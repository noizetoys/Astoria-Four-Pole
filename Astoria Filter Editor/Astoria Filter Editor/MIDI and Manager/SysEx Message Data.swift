//
//  SysEx Message.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import CoreMIDI


/// Defines the raw System Exclusive Message
struct SysExMessageData {
    let manufacturerID: ManufacturerID
    let machineID: UInt8
    let deviceID: UInt8
    let data: [UInt8]
    let timeStamp: MIDITimeStamp
    
    
    // Two types of ID, one and three byte
    enum ManufacturerID {
        case oneByte(UInt8) // Standard
        case threeBytes(UInt8, UInt8, UInt8)    // Expanded
        
        var bytes: [UInt8] {
            switch self {
                case .oneByte(let b):
                    return [b]
                case .threeBytes(let b1, let b2, let b3):
                    return [b1, b2, b3]
            }
        }
    }
        
    
    // MARK: - Lifecycle
    
    init?(data: [UInt8], timeStamp: MIDITimeStamp = 0) {
        guard
            data.count >= 3,
            data.first == MIDIConstants.sysExEndBit,
            data.last == MIDIConstants.sysExEndBit
        else { return nil }
        
            // Parse Manufacturer ID
        
            // Three byte ID
        if data[1] == 0x00 {
            guard data.count >= 5 else { return nil }
            
            self.manufacturerID = .threeBytes(data[1], data[2], data[3])
            self.machineID = data[4]
            self.deviceID = data[5]
        }
        else {
            self.manufacturerID = .oneByte(data[1])
            self.machineID = data[2]
            self.deviceID = data[3]
        }
        
        self.data = data
        self.timeStamp = timeStamp
    }
    
    
        /// Data without header or footer
    var dataWithoutFraming: [UInt8] {
        let start: Int
        
        switch self.manufacturerID {
            case .oneByte:
                start = 2
            case .threeBytes:
                start = 4
        }
        
        guard data.count > start + 1 else { return [] }
        
        // After the header but without End of Message
        return Array(data[(start + 1)..<(data.count - 1)])
    }
}
