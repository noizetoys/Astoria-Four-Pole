//
//  SysEx Error.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/14/25.
//

import Foundation


enum SysExError: Error, LocalizedError {
    case invalidLength(length: Int)
    case invalidData([UInt8])
    case sysExStartInvalid(byte: UInt8?)
    case sysExEndInvalid(byte: UInt8?)
    
    case invalidManufacturerID(byte: UInt8)
    case invalidDeviceID(byte: UInt8)
    case invalidMachineID(byte: UInt8)
    case invalidChecksum(byte: UInt8)
    case invalidDataFormat(String)
    case encodingFailed(String)
    
    case invalidCommand(byte: UInt8)
    case invalidParameterCount(count: Int8)
    case invalidParameterValue(byte: UInt8)
    
    case invalideProgramNumber(number: UInt8)
}
