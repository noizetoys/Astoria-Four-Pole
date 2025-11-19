import SwiftUI

// MARK: - Models

/// Arrow color / mode selection.
enum ArrowSelection: String, CaseIterable, Identifiable {
    case none
    case red
    case green
    case blue
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
            case .none:  return "None"
            case .red:   return "Red"
            case .green: return "Green"
            case .blue:  return "Blue"
        }
    }
    
    /// Base color for this selection (nil means "gray mode").
    var color: Color? {
        switch self {
            case .none:  return nil
            case .red:   return .red
            case .green: return .green
            case .blue:  return .blue
        }
    }
}

/// Direction the arrow should point. The base shapes are right-pointing;
/// we rotate them by this angle.
enum ArrowDirection: String, CaseIterable, Identifiable {
    case right
    case left
    case up
    case down
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
            case .right: return "Right"
            case .left:  return "Left"
            case .up:    return "Up"
            case .down:  return "Down"
        }
    }
    
    var rotationAngle: Angle {
        switch self {
            case .right: return .degrees(0)
            case .left:  return .degrees(180)
            case .up:    return .degrees(-90)
            case .down:  return .degrees(90)
        }
    }
}

// MARK: - Shapes

/// Single, right-pointing arrow (shaft + one head).
struct SingleArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        let headWidth   = w * 0.30
        let shaftWidth  = w - headWidth
        let shaftHeight = h * 0.45
        
        let shaftTopY    = rect.midY - shaftHeight / 2
        let shaftBottomY = rect.midY + shaftHeight / 2
        
        path.move(to: CGPoint(x: rect.minX, y: shaftTopY))                     // shaft top-left
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: shaftTopY))     // shaft top-right
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: rect.minY))     // head top
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))                  // tip
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: rect.maxY))     // head bottom
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: shaftBottomY))  // shaft bottom-right
        path.addLine(to: CGPoint(x: rect.minX, y: shaftBottomY))               // shaft bottom-left
        path.closeSubpath()
        
        return path
    }
}

/// Double-headed arrow (heads on both ends, shared shaft).
struct DoubleArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        let headWidth   = w * 0.25          // each head width
        let shaftWidth  = w - 2 * headWidth
        let shaftHeight = h * 0.45
        
        let shaftTopY    = rect.midY - shaftHeight / 2
        let shaftBottomY = rect.midY + shaftHeight / 2
        
        let leftHeadEndX     = rect.minX + headWidth
        let rightHeadStartX  = rect.maxX - headWidth
        
        // Outline goes around both heads + shaft in one loop.
        path.move(to: CGPoint(x: rightHeadStartX, y: rect.minY))              // top of right head
        path.addLine(to: CGPoint(x: rect.maxX,       y: rect.midY))           // right tip
        path.addLine(to: CGPoint(x: rightHeadStartX, y: rect.maxY))           // bottom of right head
        path.addLine(to: CGPoint(x: rightHeadStartX, y: shaftBottomY))        // shaft bottom-right
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: shaftBottomY))        // shaft bottom-left
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: rect.maxY))           // bottom of left head
        path.addLine(to: CGPoint(x: rect.minX,       y: rect.midY))           // left tip
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: rect.minY))           // top of left head
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: shaftTopY))           // shaft top-left
        path.addLine(to: CGPoint(x: rightHeadStartX, y: shaftTopY))           // shaft top-right
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Main View

struct ArrowPickerGlowView: View {
    // Selection & direction
    @State private var selection: ArrowSelection = .none
    @State private var direction: ArrowDirection = .right
    
    // Glow behavior
    /// Cycles per second: how many times per second the glow runs tail → tip.
    @State private var glowSpeedCPS: Double = 0.5
    /// Glow intensity (0–1) for the bright center of the band.
    @State private var glowIntensity: Double = 0.9
    
    private var hasColor: Bool { selection != .none }
    
    /// Base body fill color (gray when none, semi-transparent when colored).
    private var baseColor: Color {
        guard let color = selection.color else {
            return Color.gray.opacity(0.35)
        }
        return color.opacity(0.55)
    }
    
    /// Outline color, same family as body.
    private var strokeColor: Color {
        baseColor.opacity(hasColor ? 0.9 : 0.7)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Direction control
            HStack {
                Text("Direction")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Direction", selection: $direction) {
                    ForEach(ArrowDirection.allCases) { dir in
                        Text(dir.label).tag(dir)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // Arrow + picker
            GeometryReader { geo in
                let arrowWidth  = min(geo.size.width * 0.7, 280)
                let arrowHeight = arrowWidth * 0.35   // shallow arrow
                
                ZStack {
                    // This ZStack holds arrow visuals + picker in one coordinate system.
                    ZStack {
                        TimelineView(.animation) { timeline in
                            let now = timeline.date.timeIntervalSinceReferenceDate
                            
                            // phase in [0,1): fractional part of (time * cyclesPerSecond)
                            let phase: Double = (hasColor && glowSpeedCPS > 0)
                            ? (now * glowSpeedCPS).truncatingRemainder(dividingBy: 1.0)
                            : 0.0
                            
                            // Both arrow variants are always present; we animate opacity
                            // so the transition between double-ended ↔ single-ended is smooth.
                            ZStack {
                                // --- Double-ended arrow (used for .none) ---
                                DoubleArrowShape()
                                    .fill(baseColor)
                                    .overlay(
                                        DoubleArrowShape()
                                            .stroke(strokeColor, lineWidth: 2)
                                    )
                                    .opacity(selection == .none ? 1.0 : 0.0)
                                
                                // --- Single-ended arrow (used when a color is selected) ---
                                ZStack {
                                    SingleArrowShape()
                                        .fill(baseColor)
                                        .overlay(
                                            SingleArrowShape()
                                                .stroke(strokeColor, lineWidth: 2)
                                        )
                                    
                                    // Glow only when we have a color and non-zero speed.
                                    if let activeColor = selection.color,
                                       selection != .none,
                                       glowSpeedCPS > 0 {
                                        
                                        ZStack {
                                            let bandWidth = arrowWidth * 0.45
                                            let travel    = arrowWidth + bandWidth
                                            let startX    = -travel / 2
                                            let endX      =  travel / 2
                                            let xOffset   = startX + phase * (endX - startX)
                                            
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    .clear,
                                                    activeColor.opacity(glowIntensity),
                                                    .clear
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .frame(width: bandWidth, height: arrowHeight * 1.2)
                                            .offset(x: xOffset)
                                            .blur(radius: 10)
                                        }
                                        .frame(width: arrowWidth, height: arrowHeight)
                                        .mask(
                                            SingleArrowShape()
                                                .fill(style: FillStyle(eoFill: false, antialiased: true))
                                        )
                                    }
                                }
                                .opacity(selection == .none ? 0.0 : 1.0)
                            }
                            .frame(width: arrowWidth, height: arrowHeight)
                        }
                        
                        // Picker inside the shaft; shares the same coordinate system,
                        // then we rotate the whole container. We counter-rotate only
                        // for .left so the picker label is not upside-down.
                        Picker("", selection: $selection) {
                            ForEach(ArrowSelection.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: arrowWidth * 0.7)
                        .rotationEffect(direction == .left ? .degrees(180) : .degrees(0))
                    }
                    .frame(width: arrowWidth, height: arrowHeight)
                    .rotationEffect(direction.rotationAngle)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 160)
            .padding(.horizontal)
            
            // Glow controls
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Glow Speed (cycles per second)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $glowSpeedCPS, in: 0.1...3.0, step: 0.05) {
                        Text("Glow Speed")
                    }
                    
                    Text(String(format: "%.2f cycles/s", glowSpeedCPS))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Glow Intensity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $glowIntensity, in: 0.1...1.0, step: 0.05) {
                        Text("Glow Intensity")
                    }
                    
                    Text(String(format: "%.2f", glowIntensity))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .background(Color.black.opacity(0.96).ignoresSafeArea())
        // Animate shape cross-fade when selection changes.
        .animation(.easeInOut(duration: 0.25), value: selection)
    }
}



#Preview {
    ArrowPickerGlowView()
}
