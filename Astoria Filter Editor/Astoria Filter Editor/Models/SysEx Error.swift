//
//  SysEx Error.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/14/25.
//

import Foundation


enum SysExError: Error, LocalizedError {
    case invalidLength(expected: Int, actual: Int)
    case invalidData([UInt8])
    case sysExStartInvalid(expected: UInt8, actual: UInt8)
    case sysExEndInvalid(expected: UInt8, actual: UInt8)
    
    case invalidManufacturerID(expected: [UInt8], actual: [UInt8])
    case invalidDevideID(expected: [UInt8], actual: [UInt8])
    case invalidChecksum(expected: [UInt8], actual: [UInt8])
    case invalidDataFormat(String)
    case encodingFailed(String)
    
    case invalidCommand(expected: UInt8, actual: UInt8)
    case invalidParameterCount(expected: Int, actual: Int)
    case invalidParameterValue(expected: Int, actual: Int)
}
