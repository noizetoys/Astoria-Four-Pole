//
//  MiniWorks Types.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum SysExMessageType: Codable, Equatable {
    case programDumpMessage([UInt8])
    case programDumpRequest(UInt8)
    
    case programBulkDumpMessage([UInt8])
    case programBulkDumpRequest(UInt8)
    
    case allDumpRequest
    case allDumpMessage([UInt8])

    var rawValue: UInt8 {
        switch self {
            case .programDumpMessage(_): SysExConstant.programDumpMessage
            case .programDumpRequest(_): SysExConstant.programDumpRequest
                
            case .programBulkDumpMessage(_): SysExConstant.programBulkDumpMessage
            case .programBulkDumpRequest(_): SysExConstant.programBulkDumpRequest

            case .allDumpMessage: SysExConstant.allDumpMessage
            case .allDumpRequest: SysExConstant.allDumpRequest
        }
    }
    
    var isRequest: Bool { self.rawValue.isMultiple(of: 0x40) }
    var isResponse: Bool { !self.isRequest }
    
    var checksumStartIndex: Int {
        if case .allDumpMessage(_) = self { return 5 }
        else { return 4 }
    }
    
    var checksumEndIndex: Int {
        if case .allDumpMessage(_) = self { return 590 }
        else { return 34 }
    }
    
    var checksumIndex: Int {
        if case .allDumpMessage(_) = self { return 591 }
        else { return 35 }
    }
    
    static func type(from num: UInt8, bytes: [UInt8]) -> Self {
        switch num {
            case SysExConstant.programDumpMessage: return .programDumpMessage(bytes)
            case SysExConstant.programDumpRequest: return .programDumpRequest(bytes.first ?? 00)
            case SysExConstant.programBulkDumpMessage: return .programBulkDumpMessage(bytes)
            case SysExConstant.programBulkDumpRequest: return .programBulkDumpRequest(bytes.first ?? 00)
            case SysExConstant.allDumpMessage: return .allDumpMessage(bytes)
            case SysExConstant.allDumpRequest: return .allDumpRequest
            default: fatalError("Unhandled SysExMessageType raw value: \(num)")
        }
    }
}


//enum SysExRequestMessageType: Codable {
//    case programDumpRequest(UInt8)
//    case programBulkDumpRequest(UInt8)
//    case allDumpRequest
//    
//    var hexValue: [UInt8] {
//        switch self {
//            case .programDumpRequest(let num): [SysExConstant.programDumpRequest, num]
//            case .programBulkDumpRequest(let num): [SysExConstant.programBulkDumpRequest, num]
//            case .allDumpRequest: [SysExConstant.allDumpRequest]
//        }
//    }
//}


