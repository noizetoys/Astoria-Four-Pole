//
//  SysExMessages.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


class SysExMessageRequest {
    static func programDump(for program: Int) -> [UInt8] {
        SysExConstant.header
        + [SysExConstant.programDumpRequest,
           UInt8(program),
           SysExConstant.endOfMessage]
    }
    
    
    static func programBulkDump(for program: Int) -> [UInt8] {
        SysExConstant.header
        + [SysExConstant.programBulkDumpRequest,
           UInt8(program),
           SysExConstant.endOfMessage]
    }
    
    
    static func allDumpRequest() -> [UInt8] {
        SysExConstant.header
        + [SysExConstant.allDumpRequest,
           SysExConstant.endOfMessage]
    }
    
}

