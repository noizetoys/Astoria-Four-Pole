//
//  MiniWorks Errors.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum MiniWorksError: Error {
    case invalidChecksum(Data)
    case invalidProgramNumber(Data)
    
    case malformedMessage(Data)
    case incompleteMessage(Data)
    
    case unknownCommandByte(Data)
    
    case wrongManufacturerID(Data)
    case wrongMachineID(Data)
    
}
