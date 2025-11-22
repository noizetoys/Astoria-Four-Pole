//
//  Helpers.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation


nonisolated
func debugPrint(_ file: StaticString = #file,
                _ function: StaticString = #function,
                _ line: Int = #line,
                _ column: Int = #column,
                icon: String = "‼️",
                message: String) {
    return
    
#if DEBUG
    let fileName = file.description.components(separatedBy: "/").last ?? "Unknown"
    print("\n\(String(repeating: icon, count: 10))")
    print("[\(fileName)] --->  \(function) [line: \(line), column: \(column)]")
    if !message.isEmpty {
        print("\n\"\(message)\"\n")
    }
    print("\(String(repeating: icon, count: 10))")
#endif
}


