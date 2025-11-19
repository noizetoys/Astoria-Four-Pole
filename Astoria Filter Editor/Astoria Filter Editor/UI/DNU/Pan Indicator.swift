import SwiftUI

struct PanIndicator: View {
    @State private var panValue: Double = 64.0
    
        // Use 7 dots for cleaner visualization (you can change to 9)
    let dotCount = 7
    let minValue: Double = 0
    let maxValue: Double = 127
    
    var body: some View {
        VStack(spacing: 40) {
                // Dot indicator lights
            HStack(spacing: 12) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 20, height: 20)
                        .shadow(color: dotColor(for: index).opacity(0.8), radius: 8)
                }
            }
            .padding()
            
                // Rotary knob control
            VStack(spacing: 16) {
                RotaryKnob(value: $panValue, range: minValue...maxValue)
                    .frame(width: 120, height: 120)
                
                Text("Pan: \(Int(panValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
        /// Calculate the color/brightness for each dot based on pan value
    private func dotColor(for index: Int) -> Color {
        let centerIndex = Double(dotCount - 1) / 2.0
        
            // Normalize pan value to -1...1 range where 0 is center
        let normalizedPan = (panValue - maxValue / 2.0) / (maxValue / 2.0)
        
            // Calculate which "virtual" position the pan is at (in dot space)
        let virtualPosition = centerIndex + (normalizedPan * centerIndex)
        
            // Calculate distance from this dot to the virtual position
        let distance = abs(Double(index) - virtualPosition)
        
            // Only illuminate dots within 1 unit distance
        if distance > 1.0 {
            return Color.gray.opacity(0.2) // Dim/off state
        }
        
            // Calculate brightness (1.0 when distance is 0, fades to 0 at distance 1.0)
        let brightness = 1.0 - distance
        
        return Color.green.opacity(brightness)
    }
}

    // Rotary Knob Control
struct RotaryKnob: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
        // 7 o'clock = 210 degrees, 5 o'clock = 150 degrees (next day)
        // Total rotation: 300 degrees clockwise
    private let startAngle: Double = 210 // 7 o'clock position
    private let endAngle: Double = 510   // 5 o'clock (150 + 360)
    private let totalRotation: Double = 300
    
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                    // Knob body
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                    // Inner circle detail
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.7)
                
                    // Position indicator dot
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .offset(y: -geometry.size.width * 0.35)
                    .rotationEffect(angleForValue())
                    .shadow(color: .blue.opacity(0.6), radius: 4)
                
                    // Center cap
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 20, height: 20)
            }
            .rotationEffect(angleForValue())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        updateValue(for: gesture.location, in: geometry.size)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }
    
    private func angleForValue() -> Angle {
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        let degrees = startAngle + (normalizedValue * totalRotation)
        return .degrees(degrees)
    }
    
    private func updateValue(for location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        
            // Calculate angle from center (-180 to 180, where 0 is right/east)
        var angle = atan2(dy, dx) * 180 / .pi
        
            // Convert to 0-360 range
        if angle < 0 {
            angle += 360
        }
        
            // Adjust so that 0 degrees is at top (north)
        angle = angle + 90
        if angle >= 360 {
            angle -= 360
        }
        
            // Map the angle to our 7 o'clock to 5 o'clock range
            // 7 o'clock = 210°, 5 o'clock = 150° (but we treat it as 510° for clockwise motion)
        var adjustedAngle = angle
        
            // Handle the wrap-around: if angle is between 0-150, it's in the "next day" portion
        if angle <= 150 {
            adjustedAngle = angle + 360
        }
        
            // Clamp to our valid range
        adjustedAngle = max(startAngle, min(endAngle, adjustedAngle))
        
            // Convert angle to value
        let normalizedAngle = (adjustedAngle - startAngle) / totalRotation
        let newValue = range.lowerBound + (normalizedAngle * (range.upperBound - range.lowerBound))
        
        value = max(range.lowerBound, min(range.upperBound, newValue))
    }
}

    // Preview
struct PanIndicator_Previews: PreviewProvider {
    static var previews: some View {
        PanIndicator()
            .preferredColorScheme(.dark)
    }
}

