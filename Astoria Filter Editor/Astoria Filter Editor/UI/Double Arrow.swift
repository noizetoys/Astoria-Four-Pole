import SwiftUI

// MARK: - Stage Colors

/// Colors used for each stage of the ADSR envelope.
/// These are used for:
///  - Drawing the individual envelope segments (Attack, Decay, Sustain, Release)
///  - Coloring the handles
///  - Tinting the corresponding sliders
///
/// If you want to restyle the UI, these are good "knobs" to tweak.
struct ADSRStageColors {
    static let attack  = Color.red
    static let decay   = Color.orange
    static let sustain = Color.green
    static let release = Color.blue
}

// MARK: - Core ADSR Types (State + Stage)

/// Simple value container for an ADSR envelope.
/// All values are in MIDI-like integer domain 0...127.
struct ADSRState {
    var attack: Int    // time
    var decay: Int     // time
    var sustain: Int   // level
    var release: Int   // time
    
    /// Clamped copy to 0...127 domain.
    func clamped() -> ADSRState {
        func clamp(_ v: Int) -> Int { max(0, min(127, v)) }
        return ADSRState(
            attack:  clamp(attack),
            decay:   clamp(decay),
            sustain: clamp(sustain),
            release: clamp(release)
        )
    }
}

/// Global ADSR stage enum so it can be shared between the
/// view, geometry, and interaction engine.
enum ADSRStage {
    case attack
    case decay
    case sustain
    case release
}

// MARK: - Attack Time Mapping (logarithmic)
//
// Anchors (MIDI -> milliseconds):
//   (0,   2 ms)
//   (64,  1000 ms)
//   (127, 60000 ms)
//
// We interpolate in log-time space in two segments:
//   [0,64]   : 2 ms -> 1000 ms
//   (64,127] : 1 s  -> 60 s
//
// This keeps the exact anchors while giving a nice perceptual curve.
enum ADSRAttackTime {
    /// Convert an attack value in MIDI space (0...127) to milliseconds.
    static func ms(from midi: Int) -> Double {
        let m = max(0, min(127, midi))
        if m <= 64 {
            // 0...64 : 0.002 s -> 1.0 s
            return exp(lerp(log(0.002), log(1.0), Double(m) / 64.0)) * 1000.0
        } else {
            // 65...127 : 1.0 s -> 60.0 s
            return exp(lerp(log(1.0), log(60.0), Double(m - 64) / 63.0)) * 1000.0
        }
    }
    
    /// Approx inverse mapping (ms -> MIDI), used for drawing log grid.
    static func midi(fromMilliseconds ms: Double) -> Int {
        let s = max(0.002, min(60_000.0, ms)) / 1000.0 // clamp and convert to seconds
        if s <= 1.0 {
            let t = (log(s) - log(0.002)) / (log(1.0) - log(0.002))
            return Int(round(t * 64.0))
        } else {
            let t = (log(s) - log(1.0)) / (log(60.0) - log(1.0))
            return 64 + Int(round(t * 63.0))
        }
    }
    
    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * max(0, min(1, t))
    }
    
    /// Human-friendly string for an attack time in ms:
    /// - < 1000ms  → "X ms"
    /// - ≥ 1000ms → "Y.YYs"
    static func formatted(_ ms: Double) -> String {
        if ms < 1000 {
            return "\(Int(round(ms))) ms"
        } else {
            let seconds = ms / 1000.0
            return String(format: "%.2fs", seconds)
        }
    }
}

// MARK: - Geometry Engine
//
// Encapsulates all layout math for the envelope inside a given rect.
//
// Coordinate system reference:
//
//   +---------------- rect.minY
//   |
///  |          p1 (Attack peak)
//  |         / \
///  |        /   \
///  | p0 ___/     \____ p3 (end of sustain)
///  |               \
///  |                \
///  |                 p4 (end of release; back to 0)
///  +---------------------------> x
//  rect.minX                 rect.maxX
//
// We conceptually split the width into 4 equal "slots":
//
//   [ Attack | Decay | Sustain | Release ]
//
// Attack/Decay/Release use their 0...127 values as segment widths within
// their slot; Sustain uses 0...127 as vertical level.
//
struct ADSREnvelopeGeometry {
    
    /// Container for the 5 key points
    struct Points {
        let p0: CGPoint // start
        let p1: CGPoint // attack peak
        let p2: CGPoint // decay->sustain knee
        let p3: CGPoint // end of sustain
        let p4: CGPoint // end of release
    }
    
    let rect: CGRect
    let state: ADSRState
    
    /// Compute all envelope points given the current state.
    func envelopePoints() -> Points {
        let w = rect.width
        let h = rect.height
        let slot = w / 4.0
        
        func yForLevel(_ v: Double) -> CGFloat {
            let t = max(0.0, min(1.0, v / 127.0))
            let topPad: CGFloat = h * 0.08
            let bottomPad: CGFloat = h * 0.06
            return rect.maxY - bottomPad - CGFloat(t) * (h - topPad - bottomPad)
        }
        
        func widthFor(_ v: Double) -> CGFloat {
            let t = max(0.0, min(1.0, v / 127.0))
            return slot * CGFloat(t)
        }
        
        let sustainY = yForLevel(Double(state.sustain))
        
        let aW = widthFor(Double(state.attack))
        let dW = widthFor(Double(state.decay))
        let sW = slot
        let rW = widthFor(Double(state.release))
        
        let p0 = CGPoint(x: rect.minX,
                         y: rect.maxY)
        let p1 = CGPoint(x: rect.minX + aW,
                         y: rect.minY + h * 0.08)
        let p2 = CGPoint(x: p1.x + dW,
                         y: sustainY)
        let p3 = CGPoint(x: p2.x + sW,
                         y: sustainY)
        let p4 = CGPoint(x: p3.x + rW,
                         y: rect.maxY)
        
        return Points(p0: p0, p1: p1, p2: p2, p3: p3, p4: p4)
    }
    
    /// Midpoints of each segment, useful for placing floating labels (A/D/S/R).
    func segmentMidpoints(points: Points) -> (attack: CGPoint, decay: CGPoint, sustain: CGPoint, release: CGPoint) {
        let a = CGPoint(x: (points.p0.x + points.p1.x) / 2, y: (points.p0.y + points.p1.y) / 2)
        let d = CGPoint(x: (points.p1.x + points.p2.x) / 2, y: (points.p1.y + points.p2.y) / 2)
        let s = CGPoint(x: (points.p2.x + points.p3.x) / 2, y: (points.p2.y + points.p3.y) / 2)
        let r = CGPoint(x: (points.p3.x + points.p4.x) / 2, y: (points.p3.y + points.p4.y) / 2)
        return (attack: a, decay: d, sustain: s, release: r)
    }
    
    /// Convenience: width of a single slot.
    var slotWidth: CGFloat {
        rect.width / 4.0
    }
}

// MARK: - Interaction Engine
//
// Centralizes:
//   - Hit-testing: which stage am I interacting with?
//   - Mapping drag locations to updated ADSRState values.
//
// This can be reused for different envelope views (e.g. VCF, VCA)
// by passing in different bound states and rects.
//
struct ADSREnvelopeInteractionEngine {
    
    let geometry: ADSREnvelopeGeometry
    
    /// Compute distance from a point to a line segment AB.
    /// Used for determining the closest envelope segment.
    private func distanceToSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        if a == b { return hypot(point.x - a.x, point.y - a.y) }
        
        let ap = CGPoint(x: point.x - a.x, y: point.y - a.y)
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let abLen2 = ab.x * ab.x + ab.y * ab.y
        
        let t = max(0, min(1, (ap.x * ab.x + ap.y * ab.y) / abLen2))
        let proj = CGPoint(x: a.x + ab.x * t, y: a.y + ab.y * t)
        return hypot(point.x - proj.x, point.y - proj.y)
    }
    
    /// Project a point onto a segment AB and return the parameter t in [0, 1]
    /// where t=0 is at `a` and t=1 is at `b`.
    private func tAlongSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> Double {
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let ap = CGPoint(x: point.x - a.x, y: point.y - a.y)
        let abLen2 = ab.x * ab.x + ab.y * ab.y
        
        guard abLen2 > 0 else { return 0.0 }
        let t = (ap.x * ab.x + ap.y * ab.y) / abLen2
        return Double(max(0, min(1, t)))
    }
    
    /// Determine which stage the user intended to interact with by checking the
    /// distance to each envelope segment (Attack, Decay, Sustain, Release).
    ///
    /// If the drag starts too far from all segments, we return `nil` and the
    /// caller can ignore the gesture.
    func stage(at location: CGPoint) -> ADSRStage? {
        let pts = geometry.envelopePoints()
        let p0 = pts.p0
        let p1 = pts.p1
        let p2 = pts.p2
        let p3 = pts.p3
        let p4 = pts.p4
        
        let dAttack  = distanceToSegment(point: location, a: p0, b: p1)
        let dDecay   = distanceToSegment(point: location, a: p1, b: p2)
        let dSustain = distanceToSegment(point: location, a: p2, b: p3)
        let dRelease = distanceToSegment(point: location, a: p3, b: p4)
        
        let entries: [(ADSRStage, CGFloat)] = [
            (.attack,  dAttack),
            (.decay,   dDecay),
            (.sustain, dSustain),
            (.release, dRelease)
        ]
        
        guard let (stage, minDistance) = entries.min(by: { $0.1 < $1.1 }) else {
            return nil
        }
        
        let rect = geometry.rect
        let maxDistance: CGFloat = min(rect.width, rect.height) * 0.15
        
        return minDistance <= maxDistance ? stage : nil
    }
    
    /// Given a stage to edit and a drag location in view coordinates,
    /// return a new ADSRState with that stage updated.
    ///
    /// - Attack/Decay/Release:
    ///     Map position along their segment (t in [0,1]) to 0...127.
    /// - Sustain:
    ///     Map vertical position to 0...127 level (bottom->0, top->127).
    func updatedState(for stage: ADSRStage, dragLocation: CGPoint) -> ADSRState {
        let rect = geometry.rect
        let h = rect.height
        let pts = geometry.envelopePoints()
        let p0 = pts.p0
        let p1 = pts.p1
        let p2 = pts.p2
        let p3 = pts.p3
        let p4 = pts.p4
        
        var newState = geometry.state
        
        func clamp(_ v: Int) -> Int { max(0, min(127, v)) }
        
        func verticalValue() -> Int {
            let clampedY = min(max(dragLocation.y - rect.minY, 0), h)
            let t = Double(1.0 - (clampedY / h))
            return clamp(Int(round(t * 127.0)))
        }
        
        switch stage {
            case .attack:
                let t = tAlongSegment(point: dragLocation, a: p0, b: p1)
                newState.attack = clamp(Int(round(t * 127.0)))
            case .decay:
                let t = tAlongSegment(point: dragLocation, a: p1, b: p2)
                newState.decay = clamp(Int(round(t * 127.0)))
            case .sustain:
                newState.sustain = verticalValue()
            case .release:
                let t = tAlongSegment(point: dragLocation, a: p3, b: p4)
                newState.release = clamp(Int(round(t * 127.0)))
        }
        
        return newState.clamped()
    }
}

// MARK: - ADSR Envelope Editor View
//
// This view is now mostly "wiring":
//  - It binds to the 4 @State / @Binding ints
//  - It delegates geometry & interaction to the engine types above
//  - It draws the envelope + grid + labels + sliders
//
struct ADSREnvelopeEditor: View {
    // Stage values (0...127)
    @Binding var attack: Int
    @Binding var decay: Int
    @Binding var sustain: Int   // level (vertical)
    @Binding var release: Int
    
    private let range = 0...127
    
    /// Which stage is actively being edited by a drag.
    @State private var activeStage: ADSRStage? = nil
    
    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                
                // Build state + geometry + interaction engine.
                let state = ADSRState(
                    attack: attack,
                    decay: decay,
                    sustain: sustain,
                    release: release
                ).clamped()
                
                let geometry = ADSREnvelopeGeometry(rect: rect, state: state)
                let engine = ADSREnvelopeInteractionEngine(geometry: geometry)
                let points = geometry.envelopePoints()
                
                ZStack {
                    gridBackground(
                        geometry: geometry,
                        points: points,
                        attackValue: state.attack
                    )
                    coloredEnvelope(geometry: geometry, points: points)
                }
                .contentShape(Rectangle())
                // IMPORTANT: Only a drag updates values.
                // A simple tap (down/up with < 8pt movement) does nothing.
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            handleDragChanged(value, engine: engine)
                        }
                        .onEnded { _ in
                            activeStage = nil
                        }
                )
            }
            .aspectRatio(2.0, contentMode: .fit)
            .padding(.horizontal, 12)
            
            // Sliders + readouts (each tinted to match its stage color)
            VStack(spacing: 10) {
                let attackMs = ADSRAttackTime.ms(from: attack)
                sliderRow(
                    title: "Attack",
                    value: $attack,
                    color: ADSRStageColors.attack,
                    extra: ADSRAttackTime.formatted(attackMs),
                    legend: "Scale: 2ms → 1s → 60s"
                )
                sliderRow(
                    title: "Decay",
                    value: $decay,
                    color: ADSRStageColors.decay
                )
                sliderRow(
                    title: "Sustain (Level)",
                    value: $sustain,
                    color: ADSRStageColors.sustain
                )
                sliderRow(
                    title: "Release",
                    value: $release,
                    color: ADSRStageColors.release
                )
            }
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Drag Handling (no tap-only changes)
    
    /// Value changes only happen during drag once movement exceeds `minimumDistance`.
    ///
    /// Interaction model:
    /// - First movement:
    ///     * Determine which segment (A/D/S/R) the user intended by
    ///       measuring distance to each line segment.
    ///     * Store that in `activeStage`.
    /// - Subsequent movement:
    ///     * Map location -> parameter value for that stage only.
    private func handleDragChanged(_ value: DragGesture.Value,
                                   engine: ADSREnvelopeInteractionEngine) {
        if activeStage == nil {
            activeStage = engine.stage(at: value.startLocation)
        }
        guard let stage = activeStage else { return }
        
        let newState = engine.updatedState(for: stage, dragLocation: value.location)
        
        // Push state back into the bindings
        attack  = newState.attack
        decay   = newState.decay
        sustain = newState.sustain
        release = newState.release
    }
    
    // MARK: - Colored Envelope
    
    private func coloredEnvelope(
        geometry: ADSREnvelopeGeometry,
        points: ADSREnvelopeGeometry.Points
    ) -> some View {
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        return ZStack {
            Path { path in
                path.move(to: p0)
                path.addLine(to: p1)
            }
            .stroke(ADSRStageColors.attack, lineWidth: 2)
            
            Path { path in
                path.move(to: p1)
                path.addLine(to: p2)
            }
            .stroke(ADSRStageColors.decay, lineWidth: 2)
            
            Path { path in
                path.move(to: p2)
                path.addLine(to: p3)
            }
            .stroke(ADSRStageColors.sustain, lineWidth: 2)
            
            Path { path in
                path.move(to: p3)
                path.addLine(to: p4)
            }
            .stroke(ADSRStageColors.release, lineWidth: 2)
            
            let handleSize: CGFloat = 8
            
            Circle()
                .fill(ADSRStageColors.attack)
                .frame(width: handleSize, height: handleSize)
                .position(p1)
            
            Circle()
                .fill(ADSRStageColors.decay)
                .frame(width: handleSize, height: handleSize)
                .position(p2)
            
            Circle()
                .fill(ADSRStageColors.sustain)
                .frame(width: handleSize, height: handleSize)
                .position(p3)
        }
    }
    
    // MARK: - Grid Background (with attack log-scale + highlighted lines + legends)
    
    private func gridBackground(
        geometry: ADSREnvelopeGeometry,
        points: ADSREnvelopeGeometry.Points,
        attackValue: Int
    ) -> some View {
        let rect = geometry.rect
        let slot = geometry.slotWidth
        let vLinesPerSlot = 4
        let hLines = 6
        
        return ZStack {
            // Panel
            RoundedRectangle(cornerRadius: 12)
                .fill(.background.opacity(0.45))
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.secondary.opacity(0.35), lineWidth: 1)
            
            // Global linear grid
            Path { p in
                let totalV = vLinesPerSlot * 4
                for i in 0...totalV {
                    let x = rect.minX + CGFloat(i) * (rect.width / CGFloat(totalV))
                    p.move(to: CGPoint(x: x, y: rect.minY))
                    p.addLine(to: CGPoint(x: x, y: rect.maxY))
                }
                for j in 0...hLines {
                    let y = rect.minY + CGFloat(j) * (rect.height / CGFloat(hLines))
                    p.move(to: CGPoint(x: rect.minX, y: y))
                    p.addLine(to: CGPoint(x: rect.maxX, y: y))
                }
            }
            .stroke(.secondary.opacity(0.18), lineWidth: 1)
            
            // Attack log grid + highlight
            attackLogGridAndLegend(
                rect: rect,
                slotWidth: slot,
                attackValue: attackValue
            )
            
            // Slot separators
            Path { p in
                for i in 1..<4 {
                    let x = rect.minX + CGFloat(i) * slot
                    p.move(to: CGPoint(x: x, y: rect.minY))
                    p.addLine(to: CGPoint(x: x, y: rect.maxY))
                }
            }
            .stroke(.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            
            // Floating ADSR labels (move with envelope)
            floatingADSRLabels(geometry: geometry, points: points)
        }
    }
    
    /// Attack slot log-scale grid.
    ///
    ///  - All tick lines are drawn faint.
    ///  - The two lines that bound the current attack time are drawn brighter.
    ///  - The time legend sits above the slot.
    private func attackLogGridAndLegend(
        rect: CGRect,
        slotWidth: CGFloat,
        attackValue: Int
    ) -> some View {
        let timeMarkersMs: [Double] = [
            2,
            10,
            100,
            1000,
            10000,
            60000
        ]
        
        struct Marker {
            let ms: Double
            let midi: Int
            let x: CGFloat
            let label: String
        }
        
        let markers: [Marker] = timeMarkersMs.map { ms in
            let midi = ADSRAttackTime.midi(fromMilliseconds: ms)
            let t = Double(midi) / 127.0
            let x = rect.minX + CGFloat(t) * slotWidth
            
            let label: String
            if ms < 1000 {
                label = "\(Int(ms))ms"
            } else {
                label = "\(Int(ms / 1000))s"
            }
            return Marker(ms: ms, midi: midi, x: x, label: label)
        }
        
        let attackMs = ADSRAttackTime.ms(from: attackValue)
        var highlightedIndices: Set<Int> = []
        if let idx = (0..<(markers.count - 1)).first(where: { attackMs >= markers[$0].ms && attackMs <= markers[$0 + 1].ms }) {
            highlightedIndices.insert(idx)
            highlightedIndices.insert(idx + 1)
        } else if attackMs < markers.first?.ms ?? 0 {
            highlightedIndices.insert(0)
            if markers.count > 1 { highlightedIndices.insert(1) }
        } else if attackMs > markers.last?.ms ?? 0 {
            let last = markers.count - 1
            highlightedIndices.insert(last)
            if last > 0 { highlightedIndices.insert(last - 1) }
        }
        
        return ZStack {
            // Base (faint) lines
            Path { p in
                for marker in markers {
                    p.move(to: CGPoint(x: marker.x, y: rect.minY))
                    p.addLine(to: CGPoint(x: marker.x, y: rect.maxY))
                }
            }
            .stroke(ADSRStageColors.attack.opacity(0.25), lineWidth: 1)
            
            // Highlighted lines
            Path { p in
                for (idx, marker) in markers.enumerated() where highlightedIndices.contains(idx) {
                    p.move(to: CGPoint(x: marker.x, y: rect.minY))
                    p.addLine(to: CGPoint(x: marker.x, y: rect.maxY))
                }
            }
            .stroke(ADSRStageColors.attack.opacity(0.9), lineWidth: 1.5)
            
            // Legend above
            ForEach(Array(markers.enumerated()), id: \.offset) { index, marker in
                let isHighlighted = highlightedIndices.contains(index)
                Text(marker.label)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(
                        isHighlighted
                        ? ADSRStageColors.attack
                        : ADSRStageColors.attack.opacity(0.6)
                    )
                    .position(x: marker.x,
                              y: rect.minY - 10)
            }
        }
    }
    
    private func floatingADSRLabels(
        geometry: ADSREnvelopeGeometry,
        points: ADSREnvelopeGeometry.Points
    ) -> some View {
        let mids = geometry.segmentMidpoints(points: points)
        let offsetY: CGFloat = -10
        
        return ZStack {
            Text("A")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.attack)
                .position(x: mids.attack.x, y: mids.attack.y + offsetY)
            
            Text("D")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.decay)
                .position(x: mids.decay.x, y: mids.decay.y + offsetY)
            
            Text("S")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.sustain)
                .position(x: mids.sustain.x, y: mids.sustain.y + offsetY)
            
            Text("R")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.release)
                .position(x: mids.release.x, y: mids.release.y + offsetY)
        }
    }
    
    // MARK: - Slider Row
    
    private func sliderRow(title: String,
                           value: Binding<Int>,
                           color: Color,
                           extra: String? = nil,
                           legend: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Text(title)
                    .frame(width: 140, alignment: .leading)
                
                Slider(
                    value: Binding(
                        get: { Double(value.wrappedValue) },
                        set: { newVal in
                            value.wrappedValue = max(0, min(127, Int(newVal.rounded())))
                        }
                    ),
                    in: 0...127,
                    step: 1
                )
                .tint(color)
                .accessibilityLabel(Text(title))
                .accessibilityValue(Text("\(value.wrappedValue)"))
                
                Text(String(format: "%3d", value.wrappedValue))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
                
                if let extra = extra {
                    Text(extra)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 80, alignment: .trailing)
                }
            }
            
            if let legend = legend {
                Text(legend)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(color.opacity(0.9))
                    .padding(.leading, 140)
            }
        }
    }
}

// MARK: - Preview

struct ADSREnvelopeEditor_Previews: PreviewProvider {
    struct Demo: View {
        @State var attack = 32
        @State var decay = 48
        @State var sustain = 80
        @State var release = 40
        
        var body: some View {
            ADSREnvelopeEditor(
                attack: $attack,
                decay: $decay,
                sustain: $sustain,
                release: $release
            )
            .padding()
            .preferredColorScheme(.dark)
        }
    }
    
    static var previews: some View {
        Demo()
    }
}
