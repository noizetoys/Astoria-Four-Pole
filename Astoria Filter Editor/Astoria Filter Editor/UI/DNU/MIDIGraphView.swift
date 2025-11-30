//
//  MIDIGraphView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//
import SwiftUI


    // MARK: - Graph View

/**
 * MIDIGraphView - Renders the scrolling MIDI data visualization
 *
 * This view uses SwiftUI Canvas for high-performance rendering of:
 * 1. CC values as a connected cyan line
 * 2. Note velocities as red dots (at the velocity Y position)
 * 3. Note event positions as orange dots (on the CC line)
 *
 * Coordinate System:
 * - X-axis: Time (left = older, right = newer)
 * - Y-axis: MIDI value (bottom = 0, top = 127)
 *
 * Graph Layout:
 * - xOffset: 40px from left (space for Y-axis labels)
 * - yOffset: 10px from top
 * - graphWidth: Available width - 50px
 * - graphHeight: Available height - 20px
 *
 * Rendering Order (back to front):
 * 1. Background (black)
 * 2. Grid lines (gray)
 * 3. Y-axis labels (white)
 * 4. CC line (cyan, connected)
 * 5. CC data points (cyan dots)
 * 6. Note velocity markers (red dots with glow)
 * 7. Note position markers (orange dots with glow)
 *
 * Performance:
 * - Canvas is used for efficient rendering of many shapes
 * - Only redraws when viewModel.dataPoints changes
 * - Renders ~200 points per frame at 60 FPS
 */



struct MIDIGraphView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    init(viewModel: GraphViewModel) {
        debugPrint(message: "Created....")
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                    // LAYER 1: Background
                Color.black.opacity(0.9)
                
                    // LAYER 2: Grid lines (horizontal)
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
                
                    // LAYER 3: Y-axis labels
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
                
                    // LAYER 4-7: Graph content (Canvas for performance)
                Canvas { context, size in
                        // Calculate graph dimensions
                    let graphWidth = size.width - 50    // Leave space for Y-axis labels
                    let graphHeight = size.height - 20   // Leave space for padding
                    let xOffset: CGFloat = 40            // Start position (after Y-axis)
                    let yOffset: CGFloat = 10            // Top padding
                    
                        // Need at least 2 points to draw a line
                    guard viewModel.dataPoints.count > 1 else {
                        print("⚠️  Not enough data points to render graph")
                        return
                    }
                    
                        // Calculate horizontal spacing between points
                        // Divide available width by number of gaps between points
                    let xStep = graphWidth / CGFloat(viewModel.dataPoints.count - 1)
                    
//                    print("🎨 Rendering graph: \(viewModel.dataPoints.count) points, xStep=\(xStep)")
                    
                        // DRAW CC LINE: Connected cyan line through all points
                    var path = Path()
                    for (index, point) in viewModel.dataPoints.enumerated() {
                            // Calculate X position (time axis)
                        let x = xOffset + CGFloat(index) * xStep
                        
                            // Calculate Y position (value axis)
                            // Normalize value to 0.0-1.0 range, then map to screen coordinates
                        let normalizedValue = point.value / 127.0
                        let y = yOffset + graphHeight - (normalizedValue * graphHeight)
                        
                        if index == 0 {
                                // First point: move to position
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                                // Subsequent points: draw line from previous point
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                        // Stroke the path with cyan color
                    context.stroke(
                        path,
                        with: .color(.cyan),
                        lineWidth: 2
                    )
                    
                        // DRAW CC DATA POINTS: Small cyan dots on the line
                    for (index, point) in viewModel.dataPoints.enumerated() {
                        let x = xOffset + CGFloat(index) * xStep
                        let normalizedValue = point.value / 127.0
                        let y = yOffset + graphHeight - (normalizedValue * graphHeight)
                        
                            // Create a small circle at this point
                        let pointPath = Circle()
                            .path(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
                        
                        context.fill(pointPath, with: .color(.cyan))
                    }
                    
                        // DRAW NOTE MARKERS: Red velocity dots and orange position dots
                    var noteMarkersDrawn = 0
                    for (index, point) in viewModel.dataPoints.enumerated() {
                            // Only draw markers if this point has a note event
                        if let noteValue = point.noteValue {
                            let x = xOffset + CGFloat(index) * xStep
                            
                                // RED DOT: Draw velocity value marker
                                // This shows the actual note velocity on the Y-axis
                            let normalizedVelocity = noteValue / 127.0
                            let velocityY = yOffset + graphHeight - (normalizedVelocity * graphHeight)
                            
                            let velocityPath = Circle()
//                                .path(in: CGRect(x: x - 4, y: velocityY - 4, width: 8, height: 8))
                                .path(in: CGRect(x: x - 4, y: velocityY - 4, width: 4, height: 4))

                            context.fill(velocityPath, with: .color(.red))
                            
                                // Add subtle glow to velocity marker
                            context.fill(
//                                Circle().path(in: CGRect(x: x - 6, y: velocityY - 6, width: 12, height: 12)),
                                Circle().path(in: CGRect(x: x - 6, y: velocityY - 6, width: 6, height: 6)),
                                with: .color(.red.opacity(0.3))
                            )
                            
                                // ORANGE DOT: Draw position marker on CC line
                                // This shows where the note event occurred relative to the CC value
                            let ccValue = point.value
                            let normalizedCC = ccValue / 127.0
                            let ccY = yOffset + graphHeight - (normalizedCC * graphHeight)
                            
                            let positionPath = Circle()
                                .path(in: CGRect(x: x - 3, y: ccY - 3, width: 6, height: 6))
                            
                            context.fill(positionPath, with: .color(.orange))
                            
                                // Add subtle glow to position marker
                            context.fill(
                                Circle().path(in: CGRect(x: x - 5, y: ccY - 5, width: 10, height: 10)),
                                with: .color(.orange.opacity(0.3))
                            )
                            
                            noteMarkersDrawn += 1
                        }
                    }
                    
//                    if noteMarkersDrawn > 0 {
//                        print("  🔴 Drew \(noteMarkersDrawn) note markers")
//                    }
                }
                .padding(.trailing, 10)
            }
        }
    }
}
