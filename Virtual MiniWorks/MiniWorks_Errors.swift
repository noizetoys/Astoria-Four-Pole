//
//  MiniWorks Errors.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum MiniWorksError: Error, Equatable {
    case malformedMessage(Data)
    case incompleteMessage(Data)
    
    case wrongManufacturerID(UInt8)
    case wrongMachineID(UInt8)
    case wrongDeviceID(UInt8)
    
    case unknownCommandByte(UInt8)

    case invalidProgramNumber(UInt8)

    case invalidChecksum(UInt8)
}
