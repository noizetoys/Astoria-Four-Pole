import SwiftUI

// MARK: - Stage Colors

/// Colors used for each stage of the ADSR envelope.
/// Update these to match your app's palette.
struct ADSRStageColors {
    static let attack  = Color.red
    static let decay   = Color.orange
    static let sustain = Color.green
    static let release = Color.blue
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

// MARK: - ADSR Envelope Editor

struct ADSREnvelopeEditor: View {
    // Stage values (0...127)
    @Binding var attack: Int
    @Binding var decay: Int
    @Binding var sustain: Int   // level (vertical)
    @Binding var release: Int
    
    private let range = 0...127
    
    /// Which stage is actively being edited by a drag.
    @State private var activeStage: Stage? = nil
    
    /// ADSR stages.
    enum Stage {
        case attack, decay, sustain, release
    }
    
    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                let points = envelopePoints(in: rect) // shared geometry for drawing & hit testing
                
                ZStack {
                    gridBackground(
                        in: rect,
                        points: points,
                        attackValue: attack
                    )
                    coloredEnvelope(in: rect, points: points)
                }
                .contentShape(Rectangle())
                // IMPORTANT: Only a drag updates values.
                // A simple tap (down/up with < 8pt movement) does nothing.
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            handleDragChanged(value, in: rect)
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
    
    /// Value changes only happen during drag once movement exceeds the minimumDistance.
    private func handleDragChanged(_ value: DragGesture.Value, in rect: CGRect) {
        // On first movement, lock to the stage whose line is closest
        if activeStage == nil {
            activeStage = determineStage(at: value.startLocation, in: rect)
        }
        guard let stage = activeStage else { return }
        updateStage(stage, with: value.location, in: rect)
    }
    
    // MARK: - Stage Detection (line-based)
    
    /// Determine which stage the user intended to interact with by checking the
    /// distance to each envelope segment (Attack, Decay, Sustain, Release).
    /// If the drag starts too far from the envelope, we ignore it.
    private func determineStage(at location: CGPoint, in rect: CGRect) -> Stage? {
        let points = envelopePoints(in: rect)
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        // Helper: distance from a point to a line segment
        func distanceToSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
            if a == b { return hypot(point.x - a.x, point.y - a.y) }
            
            let ap = CGPoint(x: point.x - a.x, y: point.y - a.y)
            let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
            let abLen2 = ab.x * ab.x + ab.y * ab.y
            
            let t = max(0, min(1, (ap.x * ab.x + ap.y * ab.y) / abLen2))
            let proj = CGPoint(x: a.x + ab.x * t, y: a.y + ab.y * t)
            return hypot(point.x - proj.x, point.y - proj.y)
        }
        
        // Distances to each stage's line segment
        let dAttack  = distanceToSegment(point: location, a: p0, b: p1)
        let dDecay   = distanceToSegment(point: location, a: p1, b: p2)
        let dSustain = distanceToSegment(point: location, a: p2, b: p3)
        let dRelease = distanceToSegment(point: location, a: p3, b: p4)
        
        let distances: [(Stage, CGFloat)] = [
            (.attack,  dAttack),
            (.decay,   dDecay),
            (.sustain, dSustain),
            (.release, dRelease)
        ]
        
        guard let (stage, minDistance) = distances.min(by: { $0.1 < $1.1 }) else {
            return nil
        }
        
        // Threshold: how close you must be to the envelope to grab a stage.
        // Increase to make it more forgiving, decrease to require more precision.
        let maxDistance: CGFloat = min(rect.width, rect.height) * 0.15
        
        return (minDistance <= maxDistance) ? stage : nil
    }
    
    // MARK: - Stage Value Updates (segment-based)
    
    /// Project a point onto a segment and return the parameter t in [0, 1]
    /// where t=0 is at `a` and t=1 is at `b`.
    private func tAlongSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> Double {
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let ap = CGPoint(x: point.x - a.x, y: point.y - a.y)
        let abLen2 = ab.x * ab.x + ab.y * ab.y
        
        guard abLen2 > 0 else { return 0.0 } // segment collapsed
        let t = (ap.x * ab.x + ap.y * ab.y) / abLen2
        return Double(max(0, min(1, t)))
    }
    
    /// Map a touch location to a new value for a given stage:
    /// - Attack/Decay/Release: position along the actual segment line -> 0...127
    /// - Sustain: vertical position (0...127 level), ignoring x.
    private func updateStage(_ stage: Stage, with location: CGPoint, in rect: CGRect) {
        let h = rect.height
        let points = envelopePoints(in: rect)
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        func verticalValue() -> Int {
            let clampedY = min(max(location.y - rect.minY, 0), h)
            let t = Double(1.0 - (clampedY / h))  // 0 bottom -> 1 top
            return clampToRange(Int(round(t * 127.0)))
        }
        
        switch stage {
            case .attack:
                let t = tAlongSegment(point: location, a: p0, b: p1)
                attack = clampToRange(Int(round(t * 127.0)))
            case .decay:
                let t = tAlongSegment(point: location, a: p1, b: p2)
                decay = clampToRange(Int(round(t * 127.0)))
            case .sustain:
                sustain = verticalValue()
            case .release:
                let t = tAlongSegment(point: location, a: p3, b: p4)
                release = clampToRange(Int(round(t * 127.0)))
        }
    }
    
    private func clampToRange(_ value: Int) -> Int {
        max(range.lowerBound, min(range.upperBound, value))
    }
    
    // MARK: - Colored Envelope
    
    private func coloredEnvelope(in rect: CGRect,
                                 points: (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint)) -> some View {
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
        in rect: CGRect,
        points: (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint),
        attackValue: Int
    ) -> some View {
        let slot = rect.width / 4.0
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
            
            // Attack log grid + highlight for current attack region
            attackLogGridAndLegend(
                in: rect,
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
            floatingADSRLabels(in: rect, points: points)
        }
    }
    
    /// Attack slot log-scale grid.
    /// - All tick lines are drawn faint.
    /// - The two lines that bound the current attack time are drawn brighter.
    /// - The time legend sits above the slot.
    private func attackLogGridAndLegend(
        in rect: CGRect,
        slotWidth: CGFloat,
        attackValue: Int
    ) -> some View {
        // Time markers (ms) for log ticks / legend
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
        
        // Determine which two markers bound the current attack time
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
            // Base (faint) attack grid lines
            Path { p in
                for marker in markers {
                    p.move(to: CGPoint(x: marker.x, y: rect.minY))
                    p.addLine(to: CGPoint(x: marker.x, y: rect.maxY))
                }
            }
            .stroke(ADSRStageColors.attack.opacity(0.25), lineWidth: 1)
            
            // Highlighted lines around current attack time
            Path { p in
                for (idx, marker) in markers.enumerated() where highlightedIndices.contains(idx) {
                    p.move(to: CGPoint(x: marker.x, y: rect.minY))
                    p.addLine(to: CGPoint(x: marker.x, y: rect.maxY))
                }
            }
            .stroke(ADSRStageColors.attack.opacity(0.9), lineWidth: 1.5)
            
            // Legend ABOVE the grid
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
        in rect: CGRect,
        points: (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint)
    ) -> some View {
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        let midA = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
        let midD = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
        let midS = CGPoint(x: (p2.x + p3.x) / 2, y: (p2.y + p3.y) / 2)
        let midR = CGPoint(x: (p3.x + p4.x) / 2, y: (p3.y + p4.y) / 2)
        
        let offsetY: CGFloat = -10
        
        return ZStack {
            Text("A")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.attack)
                .position(x: midA.x, y: midA.y + offsetY)
            
            Text("D")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.decay)
                .position(x: midD.x, y: midD.y + offsetY)
            
            Text("S")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.sustain)
                .position(x: midS.x, y: midS.y + offsetY)
            
            Text("R")
                .font(.caption2.bold())
                .foregroundStyle(ADSRStageColors.release)
                .position(x: midR.x, y: midR.y + offsetY)
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
                            value.wrappedValue = clampToRange(Int(newVal.rounded()))
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
                    .padding(.leading, 140) // align under slider area (same as label width)
            }
        }
    }
    
    // MARK: - Geometry helper
    
    /// Computes the key points of the envelope polyline for use by:
    ///  - coloredEnvelope(...)   (drawing)
    ///  - determineStage(...)    (hit testing)
    ///  - updateStage(...)       (value mapping)
    ///  - floatingADSRLabels(...) (moving labels with envelope)
    private func envelopePoints(in rect: CGRect)
    -> (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint)
    {
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
        
        let sustainY = yForLevel(Double(sustain))
        
        let aW = widthFor(Double(attack))
        let dW = widthFor(Double(decay))
        let sW = slot
        let rW = widthFor(Double(release))
        
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
        
        return (p0, p1, p2, p3, p4)
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
