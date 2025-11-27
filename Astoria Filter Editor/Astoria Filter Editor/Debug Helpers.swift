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


struct DimensionBoxView: View {
    let name: String
    let color: Color
    let geometry: GeometryProxy
    var width: CGFloat?
    var height: CGFloat?
    
    
    private var newWidth: CGFloat {
        width != nil
        ? geometry.size.width * width!
        : .infinity
    }

    
    private var newHeight: CGFloat {
        height != nil
        ? geometry.size.height * height!
        : .infinity
    }
    
    
    private var textString: String {
        let widthValue = width ?? geometry.size.width
        let heightValue = height ?? geometry.size.height
        
        let proxyWidth = String(format: "%.0f", geometry.size.width)
        let proxyHeight = String(format: "%.0f", geometry.size.height)
        
        var adjustedWidth: String {
            var newWidth: CGFloat = widthValue
            
            if let width {
                newWidth = geometry.size.width * width
            }
            return String(format: "%.0f", newWidth)
        }
        
        var adjustedHeight : String {
            var newHeight: CGFloat = heightValue
            
            if let height {
                newHeight = geometry.size.height * height
            }
            
            return String(format: "%.0f", newHeight)
        }

        return "\(name):\n(\(proxyWidth),\(proxyHeight))->  (\(adjustedWidth), \(adjustedHeight))"
    }
    
    var body: some View {
        color
            .cornerRadius(10)
            .overlay {
                Text(textString)
//                    .font(.title)
                    .multilineTextAlignment(.center)
            }
            .frame(width: newWidth, height: newHeight)
    }
}


#Preview {
    GeometryReader { geo in
        VStack {
            DimensionBoxView(name: "Test",
                             color: .orange,
                             geometry: geo)
            
            HStack {
                DimensionBoxView(name: "Second",
                                 color: .blue,
                                 geometry: geo,
                                 width: 1/2)
                
                DimensionBoxView(name: "Third",
                                 color: .red,
                                 geometry: geo,
                                 width: 1/2)
            }
        }
        
    }
}


    // For Debugging
func cut(_ proxy: GeometryProxy, by div: CGFloat, isWidth: Bool = true) -> CGFloat {
    let value = isWidth ? proxy.size.width : proxy.size.height
    return value * div
}

