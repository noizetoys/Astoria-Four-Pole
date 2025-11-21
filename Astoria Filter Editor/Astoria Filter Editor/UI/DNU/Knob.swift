//import SwiftUI
//
//struct CircularFader: View {
//    @Binding var value: Double   // 0...1
//    
//    // Knob sizing
//    var size: CGFloat // = 200
//    let ringColor: Color
//    var isActive: Bool = true
//    
//    
//    private var ringWidth: CGFloat { size / 8 }// = 16                  // internal decorative ring width (optional)
//    private var dotDiameter: CGFloat { size / 6 }
//    var dotInsetInside: CGFloat { dotDiameter * 2 }// dot inside the knob rim
//    
//    // Outside line (the tracking indicator line)
//    var outsideLineWidth: CGFloat { size / 10 }
//    var outsideLineGap: CGFloat { 0 }             // gap between knob rim and outside line
//    
//    // Arc definition (CLOCKWISE; 3 o'clock = 0°)
//    // 7 o'clock ≈ 120°, 5 o'clock ≈ 60°. Sweep CW 300° from 120° → 60°.
//    private let startCW: Double = 120
//    private let sweepCW: Double = 300
//    
//    // Gesture state with axis lock and linear delta mapping
//    @State private var dragStartPoint: CGPoint?
//    @State private var axisLock: AxisLock?
//    @State private var startValue: Double = 0
//    enum AxisLock { case horizontal, vertical }
//    
//    var body: some View {
//        let diameter = size
//        let radius = diameter / 2
//        
//        ZStack {
//            // Knob body with center→edge gradient
//            Circle()
//                .fill(
//                    RadialGradient(
//                        gradient: Gradient(colors: [
//                            Color(white: 0.95),
////                            Color(white: 0.86),
//                            Color(white: 0.28)
//                        ]),
//                        center: .center,
//                        startRadius: 0,
//                        endRadius: radius
//                    )
//                )
//                .frame(width: diameter, height: diameter)
//                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
//            
//            // Rim
//            Circle()
//                .stroke(Color.black.opacity(0.35), lineWidth: 1)
//                .frame(width: diameter, height: diameter)
//            
//            // Optional internal track (subtle, inside knob)
////            ArcCW_Polyline(startCW: startCW, sweepCW: sweepCW)
////                .stroke(Color.black.opacity(0.10), style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
////                .frame(width: diameter - ringWidth, height: diameter - ringWidth)
//            
//            // OUTSIDE LINE (Background)
//            ArcCW_Polyline(startCW: startCW, sweepCW: sweepCW)
//                .stroke(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
//                .modifier(OutsideArcFrameModifier(
//                    knobSize: diameter,
//                    lineWidth: outsideLineWidth,
//                    gap: outsideLineGap
//                ))
//            
//            // OUTSIDE LINE (Active) — tracks value clockwise
//            ArcCW_Polyline(startCW: startCW, sweepCW: sweepCW * value.clamped01())
//                .stroke(ringColor.opacity((value/0.5)), style: StrokeStyle(lineWidth: outsideLineWidth, lineCap: .round))
//                .shadow(color: Color.accentColor.opacity(0.35), radius: 3)
//                .modifier(OutsideArcFrameModifier(
//                    knobSize: diameter,
//                    lineWidth: outsideLineWidth,
//                    gap: outsideLineGap
//                ))
//            
//            // INDICATOR DOT (INSIDE)
//            IndicatorDotInside(
//                angleCW: angleForValue(value.clamped01()),
//                diameter: dotDiameter,
//                insetFromOuterEdge: dotDiameter
////                insetFromOuterEdge: dotInsetInside
//            )
//            .frame(width: diameter, height: diameter)
//        }
//        .contentShape(Circle())
//        .gesture(dragGesture(in: CGSize(width: size, height: size)))
//        .frame(width: size, height: size)
//        .accessibilityLabel("Circular Fader")
//        .accessibilityValue("\(Int(value.clamped01()*100)) percent")
//    }
//}
//
//// MARK: - Value <-> angle
//private extension CircularFader {
//    func angleForValue(_ value: Double) -> Double {
//        fmod(startCW + sweepCW * value.clamped01(), 360)
//    }
//}
//
//// MARK: - Gesture (axis lock + linear delta mapping: right/up ↑, left/down ↓)
//private extension CircularFader {
//    func dragGesture(in size: CGSize) -> some Gesture {
//        DragGesture(minimumDistance: 0)
//            .onChanged { state in
//                guard isActive else { return }
//                
//                let loc = state.location
//                if dragStartPoint == nil {
//                    dragStartPoint = loc
//                    startValue = value
//                    axisLock = nil
//                }
//                guard let start = dragStartPoint else { return }
//                
//                if axisLock == nil {
//                    let dx = abs(loc.x - start.x)
//                    let dy = abs(loc.y - start.y)
//                    if max(dx, dy) > 2 {
//                        axisLock = (dx >= dy) ? .horizontal : .vertical
//                    }
//                }
//                
//                // Pixels needed to traverse the full sweep (arc length)
//                let effectiveRadius = (min(size.width, size.height) / 2) - max(0, ringWidth / 2)
//                let pixelsForFullSweep = max(24.0, Double(effectiveRadius) * (sweepCW * .pi / 180)) // guard low radius
//                
//                let deltaPixels: Double = {
//                    guard let lock = axisLock else { return 0 }
//                    switch lock {
//                        case .horizontal:
//                            // Right increases, left decreases
//                            return Double(loc.x - start.x)
//                        case .vertical:
//                            // Up increases (y decreases), down decreases (y increases)
//                            return Double(start.y - loc.y)
//                    }
//                }()
//                
//                let deltaValue = deltaPixels / pixelsForFullSweep
//                value = (startValue + deltaValue).clamped01()
//            }
//            .onEnded { _ in
//                dragStartPoint = nil
//                axisLock = nil
//            }
//    }
//}
//
//// MARK: - Shapes & Layout Helpers
//
///// Polyline arc built in **clockwise** angle space to match indicator math.
//struct ArcCW_Polyline: Shape {
//    var startCW: Double
//    var sweepCW: Double
//    var resolution: Int = 120
//    
//    func path(in rect: CGRect) -> Path {
//        var p = Path()
//        let center = CGPoint(x: rect.midX, y: rect.midY)
//        let r = min(rect.width, rect.height) / 2
//        
//        guard sweepCW > 0 else { return p }
//        
//        let steps = max(2, Int(Double(resolution) * max(0.01, sweepCW / 360.0)))
//        for i in 0...steps {
//            let t = Double(i) / Double(steps)
//            let ang = startCW + sweepCW * t
//            let θ = ang * .pi / 180
//            let x = center.x + CGFloat(cos(θ)) * r
//            let y = center.y + CGFloat(sin(θ)) * r   // +sin for our CW convention
//            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
//            else { p.addLine(to: CGPoint(x: x, y: y)) }
//        }
//        return p
//    }
//}
//
///// Positions an arc **outside** the knob with a given gap and stroke width.
//struct OutsideArcFrameModifier: ViewModifier {
//    let knobSize: CGFloat
//    let lineWidth: CGFloat
//    let gap: CGFloat
//    
//    func body(content: Content) -> some View {
//        let rKnob = knobSize / 2
//        let strokeCenterRadius = rKnob + gap + lineWidth / 2
//        let frameSide = strokeCenterRadius * 2
//        return content.frame(width: frameSide, height: frameSide)
//    }
//}
//
///// Dot positioned INSIDE the knob with a small inset from the outer edge.
//struct IndicatorDotInside: View {
//    let angleCW: Double
//    let diameter: CGFloat
//    let insetFromOuterEdge: CGFloat
//    
//    var body: some View {
//        GeometryReader { geo in
//            let w = geo.size.width
//            let h = geo.size.height
//            let c = CGPoint(x: w/2, y: h/2)
//            let rOuter = min(w, h) / 2
//            let r = rOuter - insetFromOuterEdge
////            let r = rOuter - 20
//
//            let θ = angleCW * .pi / 180
//            let x = c.x + CGFloat(cos(θ)) * r
//            let y = c.y + CGFloat(sin(θ)) * r   // +sin for CW
//            
//            Circle()
//                .fill(Color.white)
//                .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
//                .frame(width: diameter, height: diameter)
//                .position(x: x, y: y)
//                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
//        }
//    }
//}
//
//// MARK: - Utils
//private extension Double {
//    func clamped01() -> Double { min(max(self, 0), 1) }
//}
//
//// MARK: - Demo
//struct CircularFaderDemo: View {
//    @State private var v: Double = 0.0
//    
//    var body: some View {
//        HStack {
//            VStack(spacing: 24) {
//                CircularFader(
//                    value: $v,
//                    size: 300,
//                    ringColor: .red
//                )
//                .padding(40)
//                
//                Text(String(format: "Value: %.3f", v * 127))
//            }
//            
//            VStack(spacing: 24) {
//                CircularFader(
//                    value: $v,
//                    size: 100, ringColor: .green, // was 220
//                )
//                .padding(40)
//                
//                Text(String(format: "Value: %.3f", v * 127))
//            }
//
//            VStack(spacing: 24) {
//                CircularFader(
//                    value: $v,
//                    size: 60, // was 220
//                    ringColor: .blue
//                )
//                .padding(40)
//                
//                Text(String(format: "Value: %.3f", v * 127))
//            }
//
//            VStack(spacing: 24) {
//                CircularFader(
//                    value: $v,
//                    size: 30, // was 220
//                    ringColor: .orange
//                )
//                .padding(40)
//                
//                Text(String(format: "Value: %.3f", v * 127))
//            }
//
//        }
//        .padding()
//    }
//}
//
//#Preview { CircularFaderDemo() }
