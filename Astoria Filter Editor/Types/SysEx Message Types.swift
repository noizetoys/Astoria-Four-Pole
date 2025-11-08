//
//  MiniWorks Types.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum SysExMessageType: UInt8, Codable {
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


enum SysExRequestMessageType: UInt8, Codable {
    case programDumpRequest = 0x40
    case programBulkDumpRequest = 0x41
    case allDumpRequest = 0x48
}


enum SysExDataType {
    case programDump(Data)
    case programBulkDump(Data)
    case allDump(Data)
    
    
}

