    //
    //  LFOAnimationView.swift
    //  High-performance LFO visualization using CALayer
    //
    //  Created for use in SwiftUI via UIViewRepresentable/NSViewRepresentable
    //

import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformView = UIView
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformView = NSView
typealias PlatformColor = NSColor
#endif

    // MARK: - SwiftUI Wrapper


    // MARK: - Platform-Specific Representable

#if os(iOS)
struct LFOLayerViewRepresentable: UIViewRepresentable {
    var lfoSpeed: ProgramParameter
    var lfoShape: ProgramParameter
    var isRunning: Bool
    
    func makeUIView(context: Context) -> LFOLayerView {
        return LFOLayerView()
    }
    
    func updateUIView(_ uiView: LFOLayerView, context: Context) {
        uiView.update(speed: lfoSpeed.value, shape: lfoShape.containedParameter, isRunning: isRunning)
    }
}
#elseif os(macOS)
struct LFOLayerViewRepresentable: NSViewRepresentable {
    var lfoSpeed: ProgramParameter
    var lfoShape: ProgramParameter
    var isRunning: Bool
    
    func makeNSView(context: Context) -> LFOLayerView {
        return LFOLayerView()
    }
    
    func updateNSView(_ nsView: LFOLayerView, context: Context) {
        nsView.update(speed: lfoSpeed.value, shape: lfoShape.containedParameter, isRunning: isRunning)
    }
}
#endif




#Preview {
    @Previewable @State var program = MiniWorksProgram()
    
    LFOAnimationView(lfoSpeed: program.lfoSpeed, lfoShape: program.lfoShape, lfoModulationSource: program.lfoSpeedModulationSource, lfoModulationAmount: program.lfoSpeedModulationAmount)
        .frame(width: 800, height: 260)
}
