import SwiftUI

struct CircularFader: View {
    @Binding var value: Double   // 0...1 (internal representation)
    
        // Knob sizing
    var size: CGFloat
    
        // NEW: Bidirectional configuration
    var mode: FaderMode = .unidirectional(color: .blue)
    var isActive: Bool = true
    
    private var ringWidth: CGFloat { size / 8 }
    private var dotDiameter: CGFloat { size / 6 }
    var dotInsetInside: CGFloat { dotDiameter * 2 }
    
        // Outside line (the tracking indicator line)
    var outsideLineWidth: CGFloat { size / 10 }
    var outsideLineGap: CGFloat { 0 }
    
        // Arc definition (CLOCKWISE; 3 o'clock = 0°)
        // For bidirectional: 12 o'clock = 270° (center detent)
        // CW sweep to 150° (9 o'clock-ish), CCW sweep to 30° (1 o'clock-ish)
    private let centerDetent: Double = 270  // 12 o'clock
    private let maxCWSweep: Double = 120    // How far clockwise from center (positive)
    private let maxCCWSweep: Double = 120   // How far counter-clockwise from center (negative)
    
        // For unidirectional mode (original behavior)
    private let startCW: Double = 120
    private let sweepCW: Double = 300
    
        // Gesture state with axis lock and linear delta mapping
    @State private var dragStartPoint: CGPoint?
    @State private var axisLock: AxisLock?
    @State private var startValue: Double = 0
    @State private var longPressTimer: Timer?
    enum AxisLock { case horizontal, vertical }
    
    var body: some View {
        let diameter = size
        let radius = diameter / 2
        
        ZStack {
                // Knob body with center→edge gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(white: 0.95),
                            Color(white: 0.28)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
            
                // Rim
            Circle()
                .stroke(Color.black.opacity(0.35), lineWidth: 1)
                .frame(width: diameter, height: diameter)
            
                // Render based on mode
            switch mode {
                case .unidirectional(let color):
                    unidirectionalRing(color: color, diameter: diameter)
                case .bidirectional(let positiveColor, let negativeColor, let center, let positiveRange, let negativeRange):
                    bidirectionalRing(
                        positiveColor: positiveColor,
                        negativeColor: negativeColor,
                        center: center,
                        positiveRange: positiveRange,
                        negativeRange: negativeRange,
                        diameter: diameter
                    )
            }
        }
        .contentShape(Circle())
        .simultaneousGesture(longPressGesture())
        .gesture(dragGesture(in: CGSize(width: size, height: size)))
        .frame(width: size, height: size)
        .accessibilityLabel("Circular Fader")
        .accessibilityValue(accessibilityString())
    }
    
        // MARK: - Unidirectional Ring (Original)
    @ViewBuilder
    private func unidirectionalRing(color: Color, diameter: CGFloat) -> some View {
            // OUTSIDE LINE (Background)
        ArcCW_Polyline(startCW: startCW, sweepCW: sweepCW)
            .stroke(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
            .modifier(OutsideArcFrameModifier(
                knobSize: diameter,
                lineWidth: outsideLineWidth,
                gap: outsideLineGap
            ))
        
            // OUTSIDE LINE (Active) — tracks value clockwise
            // Lower values = dimmer (0.3 at minimum), higher values = brighter (1.0 at maximum)
        let brightness = 0.3 + (value.clamped01() * 0.7)
        ArcCW_Polyline(startCW: startCW, sweepCW: sweepCW * value.clamped01())
            .stroke(color.opacity(brightness), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
            .shadow(color: color.opacity(0.35), radius: 3)
            .modifier(OutsideArcFrameModifier(
                knobSize: diameter,
                lineWidth: outsideLineWidth,
                gap: outsideLineGap
            ))
        
            // INDICATOR DOT (INSIDE)
        IndicatorDotInside(
            angleCW: angleForValue(value.clamped01()),
            diameter: dotDiameter,
            insetFromOuterEdge: dotDiameter
        )
        .frame(width: diameter, height: diameter)
    }
    
        // MARK: - Bidirectional Ring (New)
    @ViewBuilder
    private func bidirectionalRing(
        positiveColor: Color,
        negativeColor: Color,
        center: UInt8,
        positiveRange: Range<UInt8>,
        negativeRange: Range<UInt8>,
        diameter: CGFloat
    ) -> some View {
        let displayValue = valueToDisplay(
            internalValue: value,
            center: center,
            positiveRange: positiveRange,
            negativeRange: negativeRange
        )
        
            // Background arc (full range) - show both sides subtly
            // Positive side (CW from center)
        ArcCW_Polyline(startCW: centerDetent, sweepCW: maxCWSweep)
            .stroke(positiveColor.opacity(0.15), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
            .modifier(OutsideArcFrameModifier(
                knobSize: diameter,
                lineWidth: outsideLineWidth,
                gap: outsideLineGap
            ))
        
            // Negative side (CCW from center)
        ArcCW_Polyline(startCW: centerDetent - maxCCWSweep, sweepCW: maxCCWSweep)
            .stroke(negativeColor.opacity(0.15), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
            .modifier(OutsideArcFrameModifier(
                knobSize: diameter,
                lineWidth: outsideLineWidth,
                gap: outsideLineGap
            ))
        
            // Active arc based on current value
        let posRange = Double(positiveRange.upperBound - positiveRange.lowerBound)
        let negRange = Double(negativeRange.upperBound - negativeRange.lowerBound)
        
            // Determine color and brightness
        let (activeColor, brightness): (Color, Double) = {
            if abs(displayValue) < 0.5 {
                    // At center - show white with dim brightness
                return (.white, 0.3)
            } else if displayValue > 0 {
                    // Positive: green, brightness increases with value
                let fraction = abs(displayValue) / posRange
                let bright = 0.3 + (fraction * 0.7)  // 0.3 to 1.0
                return (positiveColor, bright)
            } else {
                    // Negative: red, brightness increases with absolute value
                let fraction = abs(displayValue) / negRange
                let bright = 0.3 + (fraction * 0.7)  // 0.3 to 1.0
                return (negativeColor, bright)
            }
        }()
        
        if displayValue >= 0 {
                // Positive: sweep CW from center
            let fraction = displayValue / posRange
            ArcCW_Polyline(startCW: centerDetent, sweepCW: maxCWSweep * fraction)
                .stroke(activeColor.opacity(brightness), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
                .shadow(color: activeColor.opacity(0.35), radius: 3)
                .modifier(OutsideArcFrameModifier(
                    knobSize: diameter,
                    lineWidth: outsideLineWidth,
                    gap: outsideLineGap
                ))
        } else {
                // Negative: sweep CCW from center (draw from center backwards)
            let fraction = abs(displayValue) / negRange
            let startAngle = centerDetent - (maxCCWSweep * fraction)
            ArcCW_Polyline(startCW: startAngle, sweepCW: maxCCWSweep * fraction)
                .stroke(activeColor.opacity(brightness), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
                .shadow(color: activeColor.opacity(0.35), radius: 3)
                .modifier(OutsideArcFrameModifier(
                    knobSize: diameter,
                    lineWidth: outsideLineWidth,
                    gap: outsideLineGap
                ))
        }
        
            // INDICATOR DOT
        IndicatorDotInside(
            angleCW: angleForBidirectionalValue(
                internalValue: value,
                center: center,
                positiveRange: positiveRange,
                negativeRange: negativeRange
            ),
            diameter: dotDiameter,
            insetFromOuterEdge: dotDiameter
        )
        .frame(width: diameter, height: diameter)
    }
}

    // MARK: - Fader Mode
enum FaderMode {
    case unidirectional(color: Color)
    case bidirectional(
        positiveColor: Color,
        negativeColor: Color,
        center: UInt8 = 64,                // The raw value that represents "center" (typically 64 for 0-127)
        positiveRange: Range<UInt8> = 0..<63,    // Display range above center (e.g., 0..<63 means 0 to 62)
        negativeRange: Range<UInt8> = 0..<64     // Display range below center (e.g., 0..<64 means 0 to 63)
    )
}

    // MARK: - Value conversion for bidirectional mode
private extension CircularFader {
        /// Convert internal 0...1 value to display value based on mode
    func valueToDisplay(internalValue: Double, center: UInt8, positiveRange: Range<UInt8>, negativeRange: Range<UInt8>) -> Double {
        let posRange = Double(positiveRange.upperBound - positiveRange.lowerBound)
        let negRange = Double(negativeRange.upperBound - negativeRange.lowerBound)
        let totalRange = posRange + negRange
        let rawValue = internalValue * totalRange  // 0 to (posRange + negRange)
        return rawValue - negRange  // -negRange to +posRange
    }
    
        /// Convert display value to internal 0...1 value
    func displayToInternal(displayValue: Double, center: UInt8, positiveRange: Range<UInt8>, negativeRange: Range<UInt8>) -> Double {
        let posRange = Double(positiveRange.upperBound - positiveRange.lowerBound)
        let negRange = Double(negativeRange.upperBound - negativeRange.lowerBound)
        let totalRange = posRange + negRange
        return (displayValue + negRange) / totalRange
    }
    
        /// Get angle for bidirectional value
    func angleForBidirectionalValue(internalValue: Double, center: UInt8, positiveRange: Range<UInt8>, negativeRange: Range<UInt8>) -> Double {
        let displayValue = valueToDisplay(
            internalValue: internalValue,
            center: center,
            positiveRange: positiveRange,
            negativeRange: negativeRange
        )
        
        let posRange = Double(positiveRange.upperBound - positiveRange.lowerBound)
        let negRange = Double(negativeRange.upperBound - negativeRange.lowerBound)
        
        if displayValue >= 0 {
                // Positive: CW from center (270°)
            let fraction = displayValue / posRange
            return fmod(centerDetent + (maxCWSweep * fraction), 360)
        } else {
                // Negative: CCW from center
            let fraction = abs(displayValue) / negRange
            return fmod(centerDetent - (maxCCWSweep * fraction) + 360, 360)
        }
    }
}

    // MARK: - Value <-> angle (unidirectional)
private extension CircularFader {
    func angleForValue(_ value: Double) -> Double {
        fmod(startCW + sweepCW * value.clamped01(), 360)
    }
}

    // MARK: - Gesture (axis lock + linear delta mapping)
private extension CircularFader {
    func longPressGesture() -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                guard isActive else { return }
                
                    // Only reset for bidirectional mode
                if case .bidirectional(_, _, let center, let positiveRange, let negativeRange) = mode {
                        // Reset to center (display value = 0)
                    let posRange = Double(positiveRange.upperBound - positiveRange.lowerBound)
                    let negRange = Double(negativeRange.upperBound - negativeRange.lowerBound)
                    let totalRange = posRange + negRange
                    value = negRange / totalRange  // This gives display value of 0
                    
                        // Provide haptic feedback
#if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
#endif
                }
            }
    }
    
    func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { state in
                guard isActive else { return }
                
                let loc = state.location
                if dragStartPoint == nil {
                    dragStartPoint = loc
                    startValue = value
                    axisLock = nil
                }
                guard let start = dragStartPoint else { return }
                
                if axisLock == nil {
                    let dx = abs(loc.x - start.x)
                    let dy = abs(loc.y - start.y)
                    if max(dx, dy) > 2 {
                        axisLock = (dx >= dy) ? .horizontal : .vertical
                    }
                }
                
                    // Calculate sweep range based on mode
                let totalSweep: Double = {
                    switch mode {
                        case .unidirectional:
                            return sweepCW
                        case .bidirectional:
                            return maxCWSweep + maxCCWSweep
                    }
                }()
                
                let effectiveRadius = (min(size.width, size.height) / 2) - max(0, ringWidth / 2)
                let pixelsForFullSweep = max(24.0, Double(effectiveRadius) * (totalSweep * .pi / 180))
                
                let deltaPixels: Double = {
                    guard let lock = axisLock else { return 0 }
                    switch lock {
                        case .horizontal:
                            return Double(loc.x - start.x)
                        case .vertical:
                            return Double(start.y - loc.y)
                    }
                }()
                
                let deltaValue = deltaPixels / pixelsForFullSweep
                value = (startValue + deltaValue).clamped01()
            }
            .onEnded { _ in
                dragStartPoint = nil
                axisLock = nil
            }
    }
}

    // MARK: - Accessibility
private extension CircularFader {
    func accessibilityString() -> String {
        switch mode {
            case .unidirectional:
                return "\(Int(value.clamped01() * 100)) percent"
            case .bidirectional(_, _, let center, let positiveRange, let negativeRange):
                let displayValue = valueToDisplay(
                    internalValue: value,
                    center: center,
                    positiveRange: positiveRange,
                    negativeRange: negativeRange
                )
                return String(format: "%.0f", displayValue)
        }
    }
}

    // MARK: - Shapes & Layout Helpers

    /// Polyline arc built in **clockwise** angle space to match indicator math.
struct ArcCW_Polyline: Shape {
    var startCW: Double
    var sweepCW: Double
    var resolution: Int = 120
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        
        guard sweepCW > 0 else { return p }
        
        let steps = max(2, Int(Double(resolution) * max(0.01, sweepCW / 360.0)))
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let ang = startCW + sweepCW * t
            let θ = ang * .pi / 180
            let x = center.x + CGFloat(cos(θ)) * r
            let y = center.y + CGFloat(sin(θ)) * r
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }
}

    /// Positions an arc **outside** the knob with a given gap and stroke width.
struct OutsideArcFrameModifier: ViewModifier {
    let knobSize: CGFloat
    let lineWidth: CGFloat
    let gap: CGFloat
    
    func body(content: Content) -> some View {
        let rKnob = knobSize / 2
        let strokeCenterRadius = rKnob + gap + lineWidth / 2
        let frameSide = strokeCenterRadius * 2
        return content.frame(width: frameSide, height: frameSide)
    }
}

    /// Dot positioned INSIDE the knob with a small inset from the outer edge.
struct IndicatorDotInside: View {
    let angleCW: Double
    let diameter: CGFloat
    let insetFromOuterEdge: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let c = CGPoint(x: w/2, y: h/2)
            let rOuter = min(w, h) / 2
            let r = rOuter - insetFromOuterEdge
            
            let θ = angleCW * .pi / 180
            let x = c.x + CGFloat(cos(θ)) * r
            let y = c.y + CGFloat(sin(θ)) * r
            
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
                .frame(width: diameter, height: diameter)
                .position(x: x, y: y)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
        }
    }
}

    // MARK: - Utils
private extension Double {
    func clamped01() -> Double { min(max(self, 0), 1) }
}

    // MARK: - Demo
struct CircularFaderDemo: View {
    @State private var uniValue: Double = 0.5
    @State private var biValue: Double = 0.504  // Slightly off center to show color
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                    // Unidirectional examples
                Text("Unidirectional Mode (Original)")
                    .font(.headline)
                
                HStack(spacing: 40) {
                    VStack(spacing: 12) {
                        CircularFader(
                            value: $uniValue,
                            size: 200,
                            mode: .unidirectional(color: .blue)
                        )
                        Text(String(format: "Value: %.1f", uniValue * 127))
                        Text("Drag or move up/down to adjust")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        CircularFader(
                            value: $uniValue,
                            size: 100,
                            mode: .unidirectional(color: .purple)
                        )
                        Text(String(format: "Value: %.1f", uniValue * 127))
                    }
                }
                
                Divider()
                
                    // Bidirectional examples
                Text("Bidirectional Mode (New)")
                    .font(.headline)
                
                Text("Center at 12 o'clock (white when centered) | Green: +62 max (CW) | Red: -63 max (CCW)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Long press to reset to center")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                HStack(spacing: 40) {
                    VStack(spacing: 12) {
                        CircularFader(
                            value: $biValue,
                            size: 200,
                            mode: .bidirectional(
                                positiveColor: .green,
                                negativeColor: .red,
                                center: 64,
                                positiveRange: 0..<63,   // 0 to 62 inclusive
                                negativeRange: 0..<64    // 0 to 63 inclusive (negative)
                            )
                        )
                            // Convert to display value
                        let displayVal = (biValue * 127) - 64
                        Text(String(format: "Display: %.0f", displayVal))
                            .fontWeight(.semibold)
                        Text(String(format: "Raw: %.1f/127", biValue * 127))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        CircularFader(
                            value: $biValue,
                            size: 120,
                            mode: .bidirectional(
                                positiveColor: .green,
                                negativeColor: .red,
                                center: 64,
                                positiveRange: 0..<63,
                                negativeRange: 0..<64
                            )
                        )
                        let displayVal = (biValue * 127) - 64
                        Text(String(format: "Display: %.0f", displayVal))
                    }
                }
                
                Divider()
                
                    // Custom range example
                Text("Custom Range: ±100")
                    .font(.headline)
                
                HStack(spacing: 40) {
                    VStack(spacing: 12) {
                        CircularFader(
                            value: $biValue,
                            size: 150,
                            mode: .bidirectional(
                                positiveColor: .cyan,
                                negativeColor: .orange,
                                center: 100,
                                positiveRange: 0..<100,
                                negativeRange: 0..<100
                            )
                        )
                        let displayVal = (biValue * 200) - 100
                        Text(String(format: "Display: %.0f", displayVal))
                    }
                }
                
                Divider()
                
                    // Show different sizes
                Text("Various Sizes (Bidirectional)")
                    .font(.headline)
                
                HStack(spacing: 30) {
                    ForEach([300, 150, 80, 50], id: \.self) { size in
                        VStack(spacing: 8) {
                            CircularFader(
                                value: $biValue,
                                size: CGFloat(size),
                                mode: .bidirectional(
                                    positiveColor: .green,
                                    negativeColor: .red,
                                    center: 64,
                                    positiveRange: 0..<63,
                                    negativeRange: 0..<64
                                )
                            )
                            Text("\(size)pt")
                                .font(.caption2)
                        }
                    }
                }
                
                    // Slider for testing
                VStack {
                    Text("Test Control (Bidirectional Value)")
                        .font(.caption)
                    Slider(value: $biValue, in: 0...1)
                        .frame(width: 400)
                    
                    HStack {
                        Button("Set Min") { biValue = 0 }
                        Button("Set Center") { biValue = 64.0/127.0 }
                        Button("Set Max") { biValue = 1 }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 20)
            }
            .padding(40)
        }
    }
}

#Preview { CircularFaderDemo() }
