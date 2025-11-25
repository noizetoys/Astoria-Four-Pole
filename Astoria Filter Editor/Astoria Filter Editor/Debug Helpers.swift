//
//  Helpers.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import SwiftUI


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


func dimensionBox(name: String,
                  color: Color,
                  geometry: GeometryProxy,
                  width: CGFloat,
                  height: CGFloat) -> some View {
    let newWidth = geometry.size.width * width
    let newHeight = geometry.size.height * height
    
    return color
        .cornerRadius(10)
        .overlay {
            Text("\(name):\n\(describeSize(geometry, width: width, height: height))")
                .font(.title)
                .multilineTextAlignment(.center)
        }
        .frame(width: newWidth, height: newHeight)
}


    // For Debugging
func describeSize(_ proxy: GeometryProxy, width wD: CGFloat, height hD: CGFloat) -> String {
    let proxyWidth = String(format: "%.0f", proxy.size.width)
    let proxyHeight = String(format: "%.0f", proxy.size.height)
    let adjustedWidth = String(format: "%.0f", proxy.size.width * wD)
    let adjustedHeight = String(format: "%.0f", proxy.size.height * hD)
    return "Size for (\(proxyWidth),\(proxyHeight)):\n  width: \(adjustedWidth),  height: \(adjustedHeight)"
}


func cut(_ proxy: GeometryProxy, by div: CGFloat, isWidth: Bool = true) -> CGFloat {
    let value = isWidth ? proxy.size.width : proxy.size.height
    return value * div
}

