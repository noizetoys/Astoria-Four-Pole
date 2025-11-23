//
//  Helpers.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation


nonisolated
let currentLogLevel = DebugPrintLevel.trace


nonisolated
func debugPrint(_ file: StaticString = #file,
                _ function: StaticString = #function,
                _ line: Int = #line,
                _ column: Int = #column,
                icon: String = "‼️",
                message: String,
                type: DebugPrintLevel = .info) {
    
#if DEBUG
    guard
        type == .error || currentLogLevel == type
    else { return }
    
    let fileName = file.description.components(separatedBy: "/").last ?? "Unknown"
    print("\n\(String(repeating: icon, count: 10))\t\t[\(fileName)] --->  \(function) [line: \(line), column: \(column)]")
    if !message.isEmpty {
        print("\"\(message)\"")
    }
    print("\(String(repeating: icon, count: 10))")
#endif
}


nonisolated
enum DebugPrintLevel: Equatable {
    case info
    case trace
    case error
}


