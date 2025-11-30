    //
    //  MIDIGraphView.swift
    //  Astoria Filter Editor
    //
    //  Self-contained CVDisplayLink implementation (like LFO)
    //  Created by James B. Majors on 11/29/25.
    //

import SwiftUI
import Combine


//
//  MIDIGraphView_WithControls.swift
//  Enhanced version with display on/off and note marker visibility controls
//
//  WHAT THIS ADDS:
//  ═══════════════════════════════════════════════════════════════════════════
//  1. Display on/off toggle - Start/stop CVDisplayLink
//  2. Show/hide note markers - Toggle note event visualization
//  3. Show/hide velocity markers - Toggle velocity dots separately
//  4. Show/hide position markers - Toggle position dots separately
//
//  IMPLEMENTATION STRATEGY:
//  ═══════════════════════════════════════════════════════════════════════════
//  - CVDisplayLink start/stop for display control
//  - Layer visibility flags for note/velocity/position
//  - SwiftUI bindings for reactive updates
//  - Maintains all performance optimizations
//
//  USAGE:
//  ═══════════════════════════════════════════════════════════════════════════
//  @State private var isDisplayActive = true
//  @State private var showNoteMarkers = true
//  @State private var showVelocity = true
//  @State private var showPosition = true
//
//  MIDIGraphView(
//      ccNumber: .breathControl,
//      channel: 0,
//      isDisplayActive: $isDisplayActive,
//      showNoteMarkers: $showNoteMarkers,
//      showVelocity: $showVelocity,
//      showPosition: $showPosition
//  )
//
//  ═══════════════════════════════════════════════════════════════════════════





    // MARK: - SwiftUI Wrapper

/**
 * MIDIGraphView - SwiftUI interface (simplified)
 *
 * No longer needs GraphViewModel!
 * Just passes configuration to self-contained view.
 */
struct MIDIGraphView: View {
    var ccNumber: UInt8
    var channel: UInt8
    
    @Binding var isOn: Bool
    @Binding var showVelocity: Bool
    @Binding var showNotes: Bool

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.9)
                
                    // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                    // Y-axis labels
                HStack {
                    VStack {
                        Text("127")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text("96")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("64")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text("32")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("0")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .frame(width: 30)
                    
                    Spacer()
                }
                .padding(.leading, 5)
                
                    // Self-contained graph view
                GraphLayerView(ccNumber: ccNumber,
                               channel: channel,
                               isDisplayActive: $isOn,
                               showVelocity: $showVelocity,
                               showPosition: $showNotes)
                    .padding(.trailing, 10)
            }
        }
    }
}

