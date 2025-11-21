import SwiftUI
import CoreGraphics

/// A circular, physical-style knob:
/// - Pointer is a small filled circle inside the knob.
/// - Min marker "-" at ~7 o'clock (bottom-left).
/// - Max marker "+" at ~5 o'clock (bottom-right).
/// - Thin static outer ring.
/// - Progress arc starting at min, growing clockwise along the long 7→5 arc,
///   getting thicker and more colorful as it approaches max.
/// - Throw: 7 o'clock -> 5 o'clock, passing through the top (clockwise).
///
/// `value` is normalized 0...1; displayRange controls the numeric readout.
struct PhysicalCircularKnob: View {
    /// Normalized value [0, 1]
    @Binding var value: Double
    
    /// The logical range to display (e.g. 0...127 or -64...63).
    var displayRange: ClosedRange<Double> = 0...127
    
    /// Optional label below the knob.
    var label: String? = nil
    
    // Clock mapping:
    // 3 o'clock = 0°, 12 = 90°, 9 = 180°, 6 = 270°
    // 7 o'clock = 240° (min), 5 o'clock = 300° (max).
    // Long clockwise arc: 240° -> ... -> 0° -> ... -> 300° (span 300°).
    private let minAngleDeg = 240.0
    private let maxAngleDeg = 300.0
    private let throwSpan: Double = 300.0
    
    // Track last drag angle to do relative rotation
    @State private var lastDragAngle: Double?
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let knobRadius = size * 0.32
                let outerRingRadius = knobRadius * 1.15
                let arcRadius = outerRingRadius * 1.05
                let markerRadius = outerRingRadius * 1.15
                
                ZStack {
                    // Knob face
                    Circle()
                        .fill(Color(.black))
                        .shadow(color: .black.opacity(0.2),
                                radius: size * 0.03,
                                x: 0,
                                y: size * 0.02)
                    
                    // Inner edge
                    Circle()
                        .stroke(Color(.red), lineWidth: 1)
                    
                    // Thin static outer ring
                    Circle()
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                        .frame(width: outerRingRadius * 2,
                               height: outerRingRadius * 2)
                    
                    // Progress arc from min → current angle
                    KnobProgressArc(
                        minAngleDeg: minAngleDeg,
                        throwSpan: throwSpan,
                        t: value.clamped01
                    )
                    .stroke(
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: progressLineWidth(size: size),
                            lineCap: .round
                        )
                    )
                    .frame(width: arcRadius * 2,
                           height: arcRadius * 2)
                    
                    // Pointer inside the knob
                    pointerCircle(radius: knobRadius * 0.75)
                    
                    // Min "-" at ~7 o'clock
                    marker(at: minAngleDeg,
                           radius: markerRadius,
                           symbol: "-")
                    
                    // Max "+" at ~5 o'clock
                    marker(at: maxAngleDeg,
                           radius: markerRadius,
                           symbol: "+")
                }
                .frame(width: size, height: size)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            handleDragChange(gesture, in: geo.size)
                        }
                        .onEnded { _ in
                            lastDragAngle = nil
                        }
                )
            }
            .aspectRatio(1, contentMode: .fit)
            
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(formattedDisplayValue)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Colors / Progress
    
    private var accentColor: Color {
        .accentColor
    }
    
    /// Progress arc color becomes stronger as value increases.
    private var progressColor: Color {
        accentColor.opacity(0.3 + 0.7 * value.clamped01)
    }
    
    /// Progress arc line width grows with value.
    private func progressLineWidth(size: CGFloat) -> CGFloat {
        let base: CGFloat = max(2, size * 0.012)
        let extra: CGFloat = max(2, size * 0.025)
        return base + extra * CGFloat(value.clamped01)
    }
    
    // MARK: - Pointer
    
    /// Angle for the pointer along the long 7→5 clockwise throw.
    private var pointerAngleDeg: Double {
        angle(forNormalized: value.clamped01)
    }
    
    @ViewBuilder
    private func pointerCircle(radius: CGFloat) -> some View {
        let angleRad = pointerAngleDeg * .pi / 180
        let x = cos(angleRad) * radius
        let y = -sin(angleRad) * radius  // invert Y for screen coordinates
        
        Circle()
            .fill(accentColor)
            .frame(width: radius * 0.3, height: radius * 0.3)
            .shadow(color: accentColor.opacity(0.4),
                    radius: radius * 0.15)
            .offset(x: x, y: y)
    }
    
    // MARK: - Markers
    
    @ViewBuilder
    private func marker(at angleDeg: Double,
                        radius: CGFloat,
                        symbol: String) -> some View {
        let angleRad = angleDeg * .pi / 180
        let x = cos(angleRad) * radius
        let y = -sin(angleRad) * radius
        
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.9))
            Text(symbol)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: radius * 0.22, height: radius * 0.22)
        .offset(x: x, y: y)
    }
    
    // MARK: - Display value
    
    private var mappedDisplayValue: Double {
        let t = value.clamped01
        return displayRange.lowerBound
        + (displayRange.upperBound - displayRange.lowerBound) * t
    }
    
    private var formattedDisplayValue: String {
        String(Int(round(mappedDisplayValue)))
    }
    
    // MARK: - Angle mapping
    
    /// Map normalized [0,1] → angle along the long clockwise 7→5 arc:
    /// 0 → 240° (7 o'clock), 0.5 → ~90° (12 o'clock), 1 → 300° (5 o'clock).
    private func angle(forNormalized t: Double) -> Double {
        let tClamped = t.clamped01
        let unwrapped = minAngleDeg - throwSpan * tClamped
        var mod = unwrapped.truncatingRemainder(dividingBy: 360)
        if mod < 0 { mod += 360 }
        return mod
    }
    
    // MARK: - Drag handling (relative rotation)
    
    private func handleDragChange(_ gesture: DragGesture.Value, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = gesture.location.x - center.x
        let dy = center.y - gesture.location.y  // invert y for math coords
        
        var angleRad = atan2(dy, dx)            // 0 at +x, CCW positive
        var angleDeg = angleRad * 180 / .pi
        if angleDeg < 0 { angleDeg += 360 }
        
        // First event in this drag: just record angle, don't jump value.
        guard let lastAngle = lastDragAngle else {
            lastDragAngle = angleDeg
            return
        }
        
        let delta = signedAngleDifference(from: lastAngle, to: angleDeg)
        
        // Move value opposite to delta: clockwise drag (negative delta)
        // increases value, counterclockwise decreases.
        let deltaNormalized = -delta / throwSpan
        let newValue = (value + deltaNormalized).clamped01
        
        value = newValue
        lastDragAngle = angleDeg
    }
    
    /// Smallest signed angle difference in degrees (−180 ... 180).
    private func signedAngleDifference(from: Double, to: Double) -> Double {
        var diff = to - from
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }
}

// MARK: - Progress Arc Shape

/// Draws the progress arc from the min angle along the long 7→5 arc,
/// up to fraction `t` of the throw.
struct KnobProgressArc: Shape {
    var minAngleDeg: Double
    var throwSpan: Double
    var t: Double  // 0...1
    
    var animatableData: Double {
        get { t }
        set { t = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tClamped = max(0.0, min(1.0, t))
        guard tClamped > 0 else { return path }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Same mapping as the pointer uses
        func angle(forNormalized x: Double) -> Double {
            let unwrapped = minAngleDeg - throwSpan * x
            var mod = unwrapped.truncatingRemainder(dividingBy: 360)
            if mod < 0 { mod += 360 }
            return mod
        }
        
        let steps = max(2, Int(ceil(60 * tClamped)))
        
        let startAngle = angle(forNormalized: 0)
        let startRad = startAngle * .pi / 180
        let startPoint = CGPoint(
            x: center.x + cos(startRad) * radius,
            y: center.y - sin(startRad) * radius
        )
        path.move(to: startPoint)
        
        for i in 1...steps {
            let frac = tClamped * Double(i) / Double(steps)
            let a = angle(forNormalized: frac)
            let rad = a * .pi / 180
            let p = CGPoint(
                x: center.x + cos(rad) * radius,
                y: center.y - sin(rad) * radius
            )
            path.addLine(to: p)
        }
        
        return path
    }
}

// MARK: - Helpers & Preview

private extension Double {
    var clamped01: Double { max(0.0, min(1.0, self)) }
}

struct PhysicalCircularKnob_Previews: PreviewProvider {
    struct Wrapper: View {
        @State private var v: Double = 0.0
        
        var body: some View {
            VStack(spacing: 20) {
                PhysicalCircularKnob(
                    value: $v,
                    displayRange: 0...127,
                    label: "Cutoff"
                )
                .frame(width: 160, height: 160)
                
                Slider(value: $v, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
    
    static var previews: some View {
        VStack {
            Wrapper().preferredColorScheme(.dark)
            Wrapper().preferredColorScheme(.light)
        }
    }
}
