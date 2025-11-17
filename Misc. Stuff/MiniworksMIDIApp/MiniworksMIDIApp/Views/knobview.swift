//
//  KnobView.swift
//  MiniWorksMIDI
//
//  A rotary knob control that mimics hardware synthesizer knobs.
//  Range: 8:30 position (225°) to 5:00 position (315°) = 270° total range
//  Uses drag gesture for control, with visual feedback and value display.
//
//  Design rationale:
//  - 270° is standard for synth knobs (full rotation with stops)
//  - Drag distance sensitivity is tuned for precision control
//  - Visual indicator clearly shows current value position
//

import SwiftUI

struct KnobView: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var onChange: ((Int) -> Void)?
    
    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var valueAtDragStart: Int = 0
    
    private let knobSize: CGFloat = 60
    private let startAngle: Angle = .degrees(225)  // 8:30 position
    private let endAngle: Angle = .degrees(495)    // 5:00 position (225 + 270)
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Knob body
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: knobSize, height: knobSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                
                // Value indicator line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: knobSize * 0.35)
                    .offset(y: -knobSize * 0.25)
                    .rotationEffect(currentAngle)
                
                // Center dot
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            dragStart = gesture.startLocation
                            valueAtDragStart = value
                        }
                        
                        // Calculate value change based on vertical drag
                        // Negative drag (up) increases value, positive (down) decreases
                        let dragDistance = dragStart.y - gesture.location.y
                        let sensitivity: CGFloat = 0.5  // Pixels per value unit
                        let change = Int(dragDistance * sensitivity)
                        
                        let newValue = (valueAtDragStart + change).clamped(to: range)
                        if newValue != value {
                            value = newValue
                            onChange?(newValue)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Value display
            Text("\(value)")
                .font(.caption2)
                .foregroundColor(isDragging ? .blue : .secondary)
                .monospacedDigit()
        }
    }
    
    /// Calculate the current rotation angle based on value
    private var currentAngle: Angle {
        let normalizedValue = Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        let angleDegrees = 225.0 + (normalizedValue * 270.0)
        return .degrees(angleDegrees)
    }
}

// Helper extension to clamp values to a range
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
