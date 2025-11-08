//
//  SysExConstants.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation


enum SysExConstant {
    static let appName: String = "4 Pole for the Win"
    
    static let messageStart: UInt8 = 0xF0
    static let manufacturerID: UInt8 = 0x3E
    static let machineID: UInt8 = 0x04
    
    static var DEV: UInt8 { MiniWorksUserDefaults.shared.deviceID }
    
    static let endOfMessage: UInt8 = 0xF7
    
    
    static let header : [UInt8] = [messageStart, manufacturerID, machineID, DEV]
}
