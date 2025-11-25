import SwiftUI
import Foundation

// MARK: - Arrow Shapes

/// Single, right-pointing arrow (shaft + one head).
struct DragSingleArrowShape: Shape {
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
/// Used for the neutral state in singleDirectional mode,
/// and as the outline reference for dualTinted.
struct DragDoubleArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        let headWidth   = w * 0.25          // each head width
        let shaftWidth  = w - 2 * headWidth
        let shaftHeight = h * 0.45
        
        let shaftTopY    = rect.midY - shaftHeight / 2
        let shaftBottomY = rect.midY + shaftHeight / 2
        
        let leftHeadEndX    = rect.minX + headWidth
        let rightHeadStartX = rect.maxX - headWidth
        
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

/// Half of a double arrow: just the "right" or "left" side
/// with half of the shared shaft.
///
/// This lets us tint only one side while keeping outline
/// geometry that perfectly matches DoubleArrowShape.
struct DoubleArrowHalfShape: Shape {
    enum Side {
        case positive  // right side in local coordinates
        case negative  // left side in local coordinates
    }
    
    var side: Side
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        let headWidth   = w * 0.25          // each head width
        let shaftWidth  = w - 2 * headWidth
        let shaftHeight = h * 0.45
        
        let shaftTopY    = rect.midY - shaftHeight / 2
        let shaftBottomY = rect.midY + shaftHeight / 2
        
        let leftHeadEndX    = rect.minX + headWidth
        let rightHeadStartX = rect.maxX - headWidth
        
        let midX = rect.midX
        
        switch side {
            case .positive:
                // Right half: midX → right head
                path.move(to: CGPoint(x: midX, y: shaftTopY))
                path.addLine(to: CGPoint(x: rightHeadStartX, y: shaftTopY))
                path.addLine(to: CGPoint(x: rightHeadStartX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX,       y: rect.midY))
                path.addLine(to: CGPoint(x: rightHeadStartX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rightHeadStartX, y: shaftBottomY))
                path.addLine(to: CGPoint(x: midX,            y: shaftBottomY))
                path.closeSubpath()
                
            case .negative:
                // Left half: midX → left head
                path.move(to: CGPoint(x: midX, y: shaftTopY))
                path.addLine(to: CGPoint(x: leftHeadEndX, y: shaftTopY))
                path.addLine(to: CGPoint(x: leftHeadEndX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX,    y: rect.midY))
                path.addLine(to: CGPoint(x: leftHeadEndX, y: rect.maxY))
                path.addLine(to: CGPoint(x: leftHeadEndX, y: shaftBottomY))
                path.addLine(to: CGPoint(x: midX,         y: shaftBottomY))
                path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Configuration types

enum PercentageArrowMode {
    case singleDirectional
    case dualTinted
}

enum ArrowOrientation {
    case horizontal   // positive = right, negative = left
    case vertical     // positive = up,   negative = down
}

// MARK: - Percentage Arrow Control

struct PercentageArrowView: View {
    // Public API
    @Binding var rawValue: Double          // 0...127
    let showGlow: Bool
    let mode: PercentageArrowMode
    let orientation: ArrowOrientation
    let dragSensitivity: Double
    
    /// Center value in raw units (0…127).
    private let centerRawValue: Double = 64
    
    /// How "sticky" the center is in raw units.
    private let centerDeadZone: Double = 3.0
    
    init(
        rawValue: Binding<Double>,
        showGlow: Bool = true,
        mode: PercentageArrowMode = .singleDirectional,
        orientation: ArrowOrientation = .horizontal,
        dragSensitivity: Double = 1.0
    ) {
        self._rawValue = rawValue
        self.showGlow = showGlow
        self.mode = mode
        self.orientation = orientation
        self.dragSensitivity = dragSensitivity
    }
    
    // MARK: - Derived values
    
    private var mappedValue: Int {
        let clamped = min(max(Int(rawValue.rounded()), 0), 127)
        return clamped - 64
    }
    
    private var percentValue: Int {
        if mappedValue == 0 { return 0 }
        let p = Double(mappedValue) / 63.0 * 100.0
        return Int(p.rounded()).clamped(to: -100...100)
    }
    
    private var isPositive: Bool { mappedValue > 0 }
    private var isNegative: Bool { mappedValue < 0 }
    
    private var baseColor: Color {
        if mappedValue == 0 {
            return Color.gray.opacity(0.35)
        }
        else if mappedValue > 0 {
            return Color.green.opacity(0.55)
        }
        else {
            return Color.red.opacity(0.55)
        }
    }
    
    private var strokeColor: Color {
        baseColor.opacity(0.9)
    }
    
    // Orientation-dependent base angles (DragSingleArrowShape and DoubleArrow* point "right" in local coords).
    // For vertical, we rotate so that:
    // - positiveAngle is up
    // - negativeAngle is down
    private var positiveAngle: Angle {
        switch orientation {
            case .horizontal:
                return .degrees(0)      // right
            case .vertical:
                return .degrees(-90)    // up
        }
    }
    
    private var negativeAngle: Angle {
        positiveAngle + .degrees(180)
    }
    
    // MARK: - Drag state
    
    @State private var dragStartValue: Double? = nil
    @State private var isDragging: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geo in
            let arrowWidth  = min(geo.size.width * 0.7, 280)
            let arrowHeight = arrowWidth * 0.35
            
            ZStack {
                TimelineView(.animation) { timeline in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let cps = showGlow && mappedValue != 0 ? 1.0 : 0.0
                    let phase: Double = (cps > 0)
                    ? (now * cps).truncatingRemainder(dividingBy: 1.0)
                    : 0.0
                    
                    ZStack {
                        // --- Arrow drawing ---
                        arrowBody(
                            arrowWidth: arrowWidth,
                            arrowHeight: arrowHeight,
                            phase: phase
                        )
                        
                        // --- Center label ---
                        VStack(spacing: 2) {
                            Text("\(percentValue >= 0 ? "+" : "")\(percentValue)%")
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                            
//                            Text("(\(mappedValue))")
//                                .font(.caption2)
//                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(width: arrowWidth, height: arrowHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .contentShape(Rectangle())
            .gesture(
                dragGesture(arrowWidth: arrowWidth, arrowHeight: arrowHeight)
            )
            .onTapGesture(count: 2) {
                resetToCenter()
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.7)
                    .onEnded { _ in resetToCenter() }
            )
        }
    }
    
    // MARK: - Arrow body
    
    @ViewBuilder
    private func arrowBody(
        arrowWidth: CGFloat,
        arrowHeight: CGFloat,
        phase: Double
    ) -> some View {
        switch mode {
            case .singleDirectional:
                singleDirectionalArrow(arrowWidth: arrowWidth,
                                       arrowHeight: arrowHeight,
                                       phase: phase)
            case .dualTinted:
                dualTintedArrow(arrowWidth: arrowWidth,
                                arrowHeight: arrowHeight,
                                phase: phase)
        }
    }
    
    /// Original behavior: double arrow at 0, single arrow otherwise.
    @ViewBuilder
    private func singleDirectionalArrow(
        arrowWidth: CGFloat,
        arrowHeight: CGFloat,
        phase: Double
    ) -> some View {
        if mappedValue == 0 {
            DoubleArrowShape()
                .fill(baseColor)
                .overlay(
                    DoubleArrowShape()
                        .stroke(strokeColor, lineWidth: 2)
                )
                .rotationEffect(positiveAngle)
        } else {
            let arrowRotation: Angle = isPositive ? positiveAngle : negativeAngle
            
            ZStack {
                DragSingleArrowShape()
                    .fill(baseColor)
                    .overlay(
                        DragSingleArrowShape()
                            .stroke(strokeColor, lineWidth: 2)
                    )
                    .rotationEffect(arrowRotation)
                
                if showGlow {
                    glowCore(
                        arrowWidth: arrowWidth,
                        arrowHeight: arrowHeight,
                        phase: phase
                    )
                    // Mask to arrow shape in local coords, then rotate.
                    .mask(
                        DragSingleArrowShape()
                            .fill(style: FillStyle(eoFill: false, antialiased: true))
                    )
                    .rotationEffect(arrowRotation)
                }
            }
        }
    }
    
    /// Dual-tinted behavior:
    /// - Always show double-arrow outline for orientation.
    /// - Tint only the "direction" half:
    ///   • positive → right half (or up after rotation)
    ///   • negative → left half (or down after rotation)
    @ViewBuilder
    private func dualTintedArrow(
        arrowWidth: CGFloat,
        arrowHeight: CGFloat,
        phase: Double
    ) -> some View {
        let outlineColor = Color.gray.opacity(0.45)
        
        let posAngle = positiveAngle
        
        if mappedValue == 0 {
            // Neutral: both halves gray.
            ZStack {
                DoubleArrowShape()
                    .stroke(outlineColor, lineWidth: 2)
                    .rotationEffect(posAngle)
            }
        } else {
            let side: DoubleArrowHalfShape.Side = isPositive ? .positive : .negative
            
            ZStack {
                // Base gray double-arrow outline.
                DoubleArrowShape()
                    .stroke(outlineColor, lineWidth: 2)
                    .rotationEffect(posAngle)
                
                // Colored half-arrow exactly matching one side of the double arrow.
                DoubleArrowHalfShape(side: side)
                    .fill(baseColor)
                    .overlay(
                        DoubleArrowHalfShape(side: side)
                            .stroke(strokeColor, lineWidth: 2)
                    )
                    .rotationEffect(posAngle)
                
                // Glow along only the colored half.
                if showGlow {
                    glowCore(
                        arrowWidth: arrowWidth,
                        arrowHeight: arrowHeight,
                        phase: phase
                    )
                    .mask(
                        DoubleArrowHalfShape(side: side)
                            .fill(style: FillStyle(eoFill: false, antialiased: true))
                    )
                    .rotationEffect(posAngle)
                }
            }
        }
    }
    
    // MARK: - Drag Gesture with sticky center
    
    private func dragGesture(
        arrowWidth: CGFloat,
        arrowHeight: CGFloat
    ) -> some Gesture {
        let threshold: CGFloat = 8
        
        let baseRange: CGFloat
        switch orientation {
            case .horizontal:
                baseRange = max(arrowWidth * 0.8, 1)
            case .vertical:
                baseRange = max(arrowHeight * 0.8, 1)
        }
        
        let dragRange = max(baseRange / max(dragSensitivity, 0.1), 1)
        
        return DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                
                let dx = value.translation.width
                let dy = value.translation.height
                let distance = hypot(dx, dy)
                
                guard distance >= threshold else { return }
                
                if dragStartValue == nil {
                    dragStartValue = rawValue
                }
                guard let start = dragStartValue else { return }
                
                // Project onto the arrow's axis.
                let signedDelta: CGFloat
                switch orientation {
                    case .horizontal:
                        signedDelta = dx              // right → positive
                    case .vertical:
                        signedDelta = -dy             // up → positive
                }
                
                let proportion = signedDelta / dragRange
                let candidate = start + Double(proportion) * 127.0
                var clamped = candidate.clamped(to: 0...127)
                
                // Sticky center: snap to exact center within dead zone.
                if abs(clamped - centerRawValue) <= centerDeadZone {
                    clamped = centerRawValue
                }
                
                rawValue = clamped
            }
            .onEnded { _ in
                isDragging = false
                dragStartValue = nil
            }
    }
    
    // MARK: - Reset helper
    
    private func resetToCenter() {
        withAnimation(.spring()) {
            rawValue = centerRawValue
        }
    }
    
    // MARK: - Glow core (unmasked, unrotated)
    
    /// Core glow band in *local* coordinates:
    /// - Always travels left → right
    /// - We later mask and rotate this to line up with the arrow.
    private func glowCore(
        arrowWidth: CGFloat,
        arrowHeight: CGFloat,
        phase: Double
    ) -> some View {
        let bandWidth = arrowWidth * 0.45
        let travel    = arrowWidth + bandWidth
        let startX    = -travel / 2
        let endX      =  travel / 2
        
        // ALWAYS left → right in local coordinates.
        let xOffset = startX + CGFloat(phase) * (endX - startX)
        
        return ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    baseColor.opacity(1.0),
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
    }
}

// MARK: - Helpers & Demo

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct PercentageArrowDemoView: View {
    @State private var rawValue: Double = 64
    @State private var useDualMode: Bool = false
    @State private var vertical: Bool = false
    @State private var dragSensitivity: Double = 1.0
    
    var body: some View {
//        VStack(spacing: 24) {
//            VStack(spacing: 12) {
//                Toggle("Use Dual-Tinted Mode", isOn: $useDualMode)
//                Toggle("Vertical Orientation", isOn: $vertical)
//                
//                HStack {
//                    Text("Drag Sensitivity")
//                    Slider(value: $dragSensitivity, in: 0.3...2.0)
//                }
//            }
//            .padding(.horizontal)
        VStack {
            Spacer()
            VStack {
                Text("Amount")
                
                PercentageArrowView(
                    rawValue: $rawValue,
                    showGlow: true,
                    mode: useDualMode ? .dualTinted : .singleDirectional,
                    orientation: vertical ? .vertical : .horizontal,
                    dragSensitivity: dragSensitivity
                )
                .border(.red)
            }
            Spacer()
        }
//            .frame(height: 100)
//            .padding(.horizontal)
            
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Value: \(Int(rawValue.rounded())) → mapped: \(Int(rawValue.rounded()) - 64)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                
//                Slider(value: $rawValue, in: 0...127, step: 1) {
//                    Text("Value")
//                }
//            }
//            .padding(.horizontal)
//            
//            Stepper("Adjust via Stepper (\(Int(rawValue)))",
//                    value: $rawValue,
//                    in: 0...127,
//                    step: 1)
//            .padding(.horizontal)
//        }
//        .padding(.vertical, 30)
        .background(Color.black.opacity(0.96).ignoresSafeArea())
    }
}

struct PercentageArrowDemoView_Previews: PreviewProvider {
    static var previews: some View {
        PercentageArrowDemoView()
            .frame(maxWidth: 160, maxHeight: 100)
    }
}
