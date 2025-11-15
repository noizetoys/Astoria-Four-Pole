//
//  SysExConstants.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation


enum SysExConstant {
    static let appName: String = "4 Pole for the Win"
    
    static let messageStart: UInt8 = 0xF0   // [0]
    static let manufacturerID: UInt8 = 0x3E // [1]
    static let machineID: UInt8 = 0x04      // [2]
    
    static var DEV: UInt8 {                 // [3]
        MiniWorksUserDefaults.shared.deviceID
    }

    // Type of Response
    static let programDumpMessage: UInt8 = 0x00    // [4]
    static let programBulkDumpMessage: UInt8 = 0x01// [4]
    static let allDumpMessage: UInt8 = 0x08        // [4]

    // Type of Request
    static let programDumpRequest: UInt8 = 0x40
    static let programBulkDumpRequest: UInt8 = 0x41
    static let allDumpRequest: UInt8 = 0x48
    
    static let endOfMessage: UInt8 = 0xF7   // [36 or 592]
    
    
    static let header : [UInt8] = [messageStart, manufacturerID, machineID, DEV]
}
