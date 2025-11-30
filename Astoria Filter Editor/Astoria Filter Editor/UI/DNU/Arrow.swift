import SwiftUI

// MARK: - Models

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
    
    var color: Color? {
        switch self {
            case .none:  return nil
            case .red:   return .red
            case .green: return .green
            case .blue:  return .blue
        }
    }
}

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
        
        let leftHeadEndX  = rect.minX + headWidth
        let rightHeadStartX = rect.maxX - headWidth
        
        // Outline goes around both heads + shaft in one loop.
        path.move(to: CGPoint(x: rightHeadStartX, y: rect.minY))             // top of right head
        path.addLine(to: CGPoint(x: rect.maxX,       y: rect.midY))          // right tip
        path.addLine(to: CGPoint(x: rightHeadStartX, y: rect.maxY))          // bottom of right head
        path.addLine(to: CGPoint(x: rightHeadStartX, y: shaftBottomY))       // shaft bottom-right
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: shaftBottomY))       // shaft bottom-left
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: rect.maxY))          // bottom of left head
        path.addLine(to: CGPoint(x: rect.minX,       y: rect.midY))          // left tip
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: rect.minY))          // top of left head
        path.addLine(to: CGPoint(x: leftHeadEndX,    y: shaftTopY))          // shaft top-left
        path.addLine(to: CGPoint(x: rightHeadStartX, y: shaftTopY))          // shaft top-right
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Main View

struct ArrowPickerGlowView: View {
    @State private var selection: ArrowSelection = .none
    @State private var direction: ArrowDirection = .right
    @State private var glowSpeedCPS: Double = 0.5
    @State private var glowIntensity: Double = 0.9
    
    private var hasColor: Bool { selection != .none }
    
    private var baseColor: Color {
        guard let color = selection.color else {
            return Color.gray.opacity(0.35)
        }
        return color.opacity(0.55)
    }
    
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
                let arrowHeight = arrowWidth * 0.35
                
                ZStack {
                    // This ZStack holds arrow visuals + picker in a single
                    // coordinate system. We rotate it once so the picker
                    // is always inside the shaft for all directions.
                    ZStack {
                        TimelineView(.animation) { timeline in
                            let now = timeline.date.timeIntervalSinceReferenceDate
                            let phase: Double = (hasColor && glowSpeedCPS > 0)
                            ? (now * glowSpeedCPS).truncatingRemainder(dividingBy: 1.0)
                            : 0.0
                            
                            Group {
                                if selection == .none {
                                    // Dull, double-headed arrow, no glow.
                                    DoubleArrowShape()
                                        .fill(baseColor)
                                        .overlay(
                                            DoubleArrowShape()
                                                .stroke(strokeColor, lineWidth: 2)
                                        )
                                } else {
                                    // Single-headed arrow with glow.
                                    ZStack {
                                        SingleArrowShape()
                                            .fill(baseColor)
                                            .overlay(
                                                SingleArrowShape()
                                                    .stroke(strokeColor, lineWidth: 2)
                                            )
                                        
                                        if let activeColor = selection.color,
                                           glowSpeedCPS > 0 {
                                            // Glow container same size as arrow.
                                            ZStack {
                                                let bandWidth = arrowWidth * 0.45
                                                let travel = arrowWidth + bandWidth
                                                let startX = -travel / 2
                                                let endX   =  travel / 2
                                                let xOffset = startX + phase * (endX - startX)
                                                
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
                                }
                            }
                            .frame(width: arrowWidth, height: arrowHeight)
                        }
                        
                        // Picker inside the shaft; rotates with the arrow.
                        Picker("", selection: $selection) {
                            ForEach(ArrowSelection.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: arrowWidth * 0.7)
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
    }
}


#Preview {
    ArrowPickerGlowView()
}
