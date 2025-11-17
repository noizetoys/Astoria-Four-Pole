//
//  MiniWorks Types.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum SysExMessageType: UInt8, Codable, Equatable {
    case programDumpMessage = 0x00
    case programBulkDumpMessage = 0x01
    case allDumpMessage = 0x08
    
    
    var isRequest: Bool {
        return self.rawValue.isMultiple(of: 0x40)
    }
    
    
    var isResponse: Bool {
        return !self.isRequest
    }
    
    
    var checksumStartIndex: Int {
        let isDump = self == .allDumpMessage
        return isDump ? 5 : 4
    }
    
    
    var checksumEndIndex: Int {
        let isDump = self == .allDumpMessage
        return isDump ? 590 : 34
    }
    
    
    var checksumIndex: Int {
        return self == .allDumpMessage ? 591 : 35
    }
}


enum SysExRequestMessageType: Codable {
    case programDumpRequest(Int)
    case programBulkDumpRequest(Int)
    case allDumpRequest
    
    var hexValue: [UInt8] {
        switch self {
            case .programDumpRequest(let num): [0x40, UInt8(num)]
            case .programBulkDumpRequest(let num): [0x41, UInt8(num)]
            case .allDumpRequest: [0x48]
        }
    }
}


enum SysExDataType: Equatable {
    case programDump(Data)
    case programBulkDump(Data)
    case allDump(Data)
}

