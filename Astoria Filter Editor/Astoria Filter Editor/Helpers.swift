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
                icon: String = "‼️",
                message: String) {
#if DEBUG
    let fileName = file.description.components(separatedBy: "/").last ?? "Unknown"
    print("\n\(String(repeating: icon, count: 10))")
    print("[\(fileName)] --->  \(function):\(line)\n - \(message)")
    print("\(String(repeating: icon, count: 10))\n")
#endif
}


