import SwiftUI

enum PanVisualStyle: String, CaseIterable, Identifiable {
    case circles
    case squares
    case line
    
    var id: String { rawValue }
}

struct PanControl: View {
    /// Pan value from -1 (full left) to +1 (full right)
    @Binding var value: Double
    
    /// Visual style of the control
    var style: PanVisualStyle = .squares
    
    /// Color of the main indicator
    var indicatorColor: Color = .blue
    
    /// Color of the glow (can be different from indicator color)
    var glowColor: Color = .teal
    
    /// 0.0 = no glow, 1.0 = strong, wide glow
    var glowIntensity: Double = 0.5
    
    /// Desired number of items for circles/squares (auto-coerced to odd >= 3)
    var itemCount: Int = 13
    
    /// How many neighbors (in index steps) are affected by glow / size / brightness
    var neighborGlowRadius: Double = 1.2
    
    /// How fast glow/size falls off from the center. 1 = slow, 2 = faster, etc.
    var glowFalloffExponent: Double = 2.0
    
    private var effectiveItemCount: Int {
        let minOdd = max(itemCount, 3)
        return (minOdd % 2 == 0) ? (minOdd + 1) : minOdd
    }
    
    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                
                ZStack {
                    switch style {
                        case .circles:
                            circlesStyle(width: width, height: height)
                        case .squares:
                            squaresStyle(width: width, height: height)
                        case .line:
                            lineStyle(width: width, height: height)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .highPriorityGesture(dragGesture(width: width))   // horizontal drag
                .simultaneousGesture(doubleTapResetGesture)       // double tap -> center
                .simultaneousGesture(longPressResetGesture)       // long press -> center
            }
            .frame(height: 44)
            
            // Slider from -1...1 mirrored to 0...1
//            Slider(
//                value: Binding(
//                    get: { value },
//                    set: { value = $0 }
////                    get: { (value + 1) / 2 },
////                    set: { value = $0 * 2 - 1 }
//                )
//            )
//            .padding(.vertical)
        }
        .padding(.horizontal)
    }
}

// MARK: - Gestures

private extension PanControl {
    func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { gesture in
                // Lock axis to horizontal
//                let clampedX = min(max(0, gesture.location.x), width)
                let clampedX = gesture.location.x / width
//                let normalized = clampedX / width          // 0...1
//                value = ((normalized * 2) - 1)                 // -1...1
                value = clampedX
            }
    }
    
    
    var doubleTapResetGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                value = 0.5
            }
    }
    
    
    var longPressResetGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                value = 0.5
            }
    }
}


// MARK: - Glow / size weighting

private extension PanControl {
    /// Returns (weight 0...1, isCurrent)
    /// Weight affects size, brightness, and glow.
    func glowWeight(forIndex index: Int) -> (weight: Double, isCurrent: Bool) {
        let count = effectiveItemCount
        guard count > 1 else { return (1.0, true) }
        
        let position = value //(value + 1) / 2 // 0...1
        let currentIndex = position * Double(count - 1)
        let distance = abs(Double(index) - currentIndex) // in item steps
        
        let isCurrent = distance < 0.5
        
        guard neighborGlowRadius > 0 else {
            return (isCurrent ? 1.0 : 0.0, isCurrent)
        }
        
        // normalize: 0 at current, 1 at edge of radius
        let normalized = min(max(distance / neighborGlowRadius, 0), 1)
        // invert & apply falloff
        let base = 1.0 - pow(normalized, glowFalloffExponent)
        
        return (weight: max(0, base), isCurrent: isCurrent)
    }
}

// MARK: - Styles

private extension PanControl {
    // Circles with spacing, glow and size falloff
    @ViewBuilder
    func circlesStyle(width: CGFloat, height: CGFloat) -> some View {
        let count = effectiveItemCount
        let spacing = width / CGFloat(max(count - 1, 1))
        let baseRadius: CGFloat = min(6, height * 0.24)
        let extraRadius: CGFloat = baseRadius * 1.4 // how much bigger the center gets
        let centerY = height / 2
        
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let fraction = CGFloat(index) / CGFloat(max(count - 1, 1))
                let x = fraction * width
                
                let (weight, _) = glowWeight(forIndex: index)
                
                // Size interpolation (neighbors slightly bigger, center clearly biggest)
                let radius = baseRadius + extraRadius * CGFloat(weight)
                
                let baseOpacity = 0.15
                let opacity = baseOpacity + (1.0 - baseOpacity) * weight
                
                // Glow scales both with weight and global glowIntensity
                let glowRadius = CGFloat(2 + 14 * glowIntensity * weight)
                let glowAlpha = glowIntensity * weight
                
                Circle()
                    .fill(indicatorColor.opacity(opacity))
//                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: x, y: centerY)
                    .shadow(
                        color: glowColor.opacity(glowAlpha),
                        radius: glowRadius,
                        x: 0, y: 0
                    )
            }
        }
        .padding(.horizontal, spacing * 0.1) // slight side breathing room
    }
    
    // Squares packed & centered, with glow + size falloff
    @ViewBuilder
    func squaresStyle(width: CGFloat, height: CGFloat) -> some View {
        let count = effectiveItemCount
        let slotWidth = width / CGFloat(max(count, 1))
        let baseHeight = height * 0.4
        let extraHeight = baseHeight * 0.7
        let centerY = height / 2
        
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let fraction = CGFloat(index) / CGFloat(max(count - 1, 1))
                let x = fraction * width
                let (weight, _) = glowWeight(forIndex: index)
                
                let baseOpacity = 0.12
                let opacity = baseOpacity + (1.0 - baseOpacity) * weight
                
                let rectHeight = baseHeight + extraHeight * CGFloat(weight)
                
                let glowRadius = CGFloat(2 + 12 * glowIntensity * weight)
                let glowAlpha = glowIntensity * weight
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(indicatorColor.opacity(opacity))
                    .frame(width: slotWidth, height: rectHeight)
                    .position(x: x, y: centerY)
                    .shadow(
                        color: glowColor.opacity(glowAlpha),
                        radius: glowRadius,
                        x: 0, y: 0
                    )
            }
        }
    }
    
    // Slot with strong glow + orb
    @ViewBuilder
    func lineStyle(width: CGFloat, height: CGFloat) -> some View {
        let slotHeight: CGFloat = max(10, height * 0.28)
        let baseOrbSize: CGFloat = min(20, height * 0.8)
        let centerY = height / 2
        
        let normalized = (value + 1) / 2 // 0...1
        let x = normalized * width
        
        // Glow spread depends on glowIntensity
        let glowSpreadMultiplier = 1 + CGFloat(glowIntensity * 1.8)
        let glowSize = baseOrbSize * glowSpreadMultiplier
        
        ZStack {
            // Slot background (like a recessed LED bar)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .frame(width: width, height: slotHeight)
                .position(x: width / 2, y: centerY)
            
            // Glowing region behind slot, clipped to the slot shape
            Circle()
                .fill(glowColor.opacity(glowIntensity * 0.9))
                .frame(width: glowSize * 2.5, height: glowSize * 2.5)
                .position(x: x, y: centerY)
                .blur(radius: glowSize * 0.8)
                .compositingGroup()
                .mask(
                    Capsule()
                        .frame(width: width, height: slotHeight)
                        .position(x: width / 2, y: centerY)
                )
            
            // Core orb (indicator) on top
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            indicatorColor,
                            indicatorColor.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: baseOrbSize * 0.9
                    )
                )
                .frame(width: baseOrbSize * 1.3, height: baseOrbSize * 1.3)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .position(x: x, y: centerY)
                .shadow(
                    color: glowColor.opacity(glowIntensity),
                    radius: CGFloat(8 + 16 * glowIntensity),
                    x: 0, y: 0
                )
        }
    }
}

// MARK: - Preview / Demo with ColorPicker

struct PanControl_Previews: PreviewProvider {
    struct Demo: View {
        @State private var panValue: Double = 1
        @State private var style: PanVisualStyle = .squares
        @State private var glowIntensity: Double = 0.5
        @State private var items: Double = 15
        @State private var neighborRadius: Double = 1.2
        @State private var indicatorColor: Color = .red
        
        var body: some View {
            VStack(spacing: 24) {
                PanControl(
                    value: $panValue,
                    style: style,
                    indicatorColor: indicatorColor,
                    glowColor: indicatorColor,
                    glowIntensity: glowIntensity,
                    itemCount: Int(items),
                    neighborGlowRadius: neighborRadius,
                    glowFalloffExponent: 2.0
                )
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    }
    
    static var previews: some View {
        Demo()
            .frame(maxWidth: 450)
    }
}
