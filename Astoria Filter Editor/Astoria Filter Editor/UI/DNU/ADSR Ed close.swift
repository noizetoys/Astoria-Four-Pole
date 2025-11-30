import SwiftUI

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
    
    /// Optional inverse mapping (ms -> approx MIDI), not used in this view
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
}

// MARK: - ADSR Envelope Editor
//
// - All stage values are 0...127.
// - View size is fixed; each stage occupies a "slot" horizontally.
// - Attack, Decay, Release: horizontal length in their own slot.
// - Sustain: vertical level only; sustain segment’s width is fixed.
// - User can adjust:
//   * by sliders, or
//   * by tapping/dragging on the envelope lines or dots.
//
// Drag behavior:
// - On drag begin, we lock onto a single stage (Attack/Decay/Sustain/Release)
//   chosen by the closest "handle" (fatter hit area).
// - While dragging, we *ignore crossing into other slots*, so only that
//   stage is updated.
// - On drag end, the lock is released.
//
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
                
                ZStack {
                    gridBackground(in: rect)
                    
                    ADSREnvelopeShape(
                        attack: Double(attack),
                        decay: Double(decay),
                        sustainLevel: Double(sustain),
                        release: Double(release)
                    )
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .foregroundStyle(.primary)
                }
                // Make the whole plotting area interactive
                .contentShape(Rectangle())
                // Drag: we lock to a stage on first movement, then only update that stage
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChanged(value, in: rect)
                        }
                        .onEnded { _ in
                            activeStage = nil
                        }
                )
                // Tap: single-position update (no lock needed)
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { event in
                            handleTap(at: event.location, in: rect)
                        }
                )
            }
            .aspectRatio(2.0, contentMode: .fit)
            .padding(.horizontal, 12)
            
            // Sliders + readouts
            VStack(spacing: 10) {
                sliderRow(
                    title: "Attack",
                    value: $attack,
                    extra: String(format: "≈ %.0f ms", ADSRAttackTime.ms(from: attack))
                )
                sliderRow(title: "Decay", value: $decay)
                sliderRow(title: "Sustain (Level)", value: $sustain)
                sliderRow(title: "Release", value: $release)
            }
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Drag & Tap Handling
    
    /// Handle drag changes (pressed/dragging).
    /// - We determine the active stage *once*, based on the starting location,
    ///   then keep updating only that stage even if the drag crosses slot boundaries.
    private func handleDragChanged(_ value: DragGesture.Value, in rect: CGRect) {
        // Lock stage when drag starts.
        if activeStage == nil {
            activeStage = determineStage(at: value.startLocation, in: rect)
        }
        guard let stage = activeStage else { return }
        
        updateStage(stage, with: value.location, in: rect)
    }
    
    /// Handle a single tap: determine nearest stage and update once.
    private func handleTap(at location: CGPoint, in rect: CGRect) {
        guard let stage = determineStage(at: location, in: rect) else { return }
        updateStage(stage, with: location, in: rect)
    }
    
    // MARK: - Stage Detection (fatter hit areas)
    
    /// Determine which stage the user intended to interact with by looking at
    /// "handles" on the envelope (fatter hit areas) and falling back to slot index.
    ///
    /// Handles:
    ///  - Attack:  peak (end of attack segment)
    ///  - Decay:   knee where decay reaches sustain
    ///  - Sustain: mid-point of the sustain horizontal line
    ///  - Release: mid-point of the release segment
    ///
    /// We pick the stage whose handle is closest to the touch location,
    /// as long as it is within a reasonable threshold. This makes the
    /// hit area effectively "fatter" around the visually interesting points.
    private func determineStage(at location: CGPoint, in rect: CGRect) -> Stage? {
        let points = envelopePoints(in: rect)
        let p1 = points.p1    // attack peak
        let p2 = points.p2    // decay->sustain knee
        let p3 = points.p3    // end of sustain
        let p4 = points.p4    // end of release
        
        // Define one handle per stage.
        let handleAttack  = p1
        let handleDecay   = p2
        let handleSustain = CGPoint(x: (p2.x + p3.x) / 2, y: p2.y)     // mid sustain
        let handleRelease = CGPoint(x: (p3.x + p4.x) / 2, y: (p3.y + p4.y) / 2)
        
        // Distance helper
        func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx*dx + dy*dy)
        }
        
        // Measure distances
        let dA = dist(location, handleAttack)
        let dD = dist(location, handleDecay)
        let dS = dist(location, handleSustain)
        let dR = dist(location, handleRelease)
        
        // Choose smallest distance
        let distances: [(Stage, CGFloat)] = [
            (.attack,  dA),
            (.decay,   dD),
            (.sustain, dS),
            (.release, dR)
        ]
        let closest = distances.min { $0.1 < $1.1 }
        
        // Max distance threshold for handles (adjust to make hit areas fatter/thinner)
        let maxHandleDistance: CGFloat = min(rect.width, rect.height) * 0.25
        
        if let (stage, dist) = closest, dist <= maxHandleDistance {
            return stage
        }
        
        // Fallback: use slot index by x-position if no handle is near.
        // This makes the whole slot clickable even away from the handle.
        let w = rect.width
        let slotWidth = w / 4.0
        let clampedX = min(max(location.x - rect.minX, 0), w)
        let slotIndex = min(max(Int(clampedX / slotWidth), 0), 3)
        
        switch slotIndex {
            case 0: return .attack
            case 1: return .decay
            case 2: return .sustain
            case 3: return .release
            default: return nil
        }
    }
    
    // MARK: - Stage Value Updates
    
    /// Update a specific stage based on a touch location.
    /// - Attack/Decay/Release map horizontal position inside their slot to 0...127.
    /// - Sustain maps vertical position (0...127 level), ignoring x.
    private func updateStage(_ stage: Stage, with location: CGPoint, in rect: CGRect) {
        let w = rect.width
        let h = rect.height
        guard w > 0, h > 0 else { return }
        
        let slotWidth = w / 4.0
        
        func clampX(_ x: CGFloat, slotIndex: Int) -> CGFloat {
            let slotMinX = rect.minX + CGFloat(slotIndex) * slotWidth
            let slotMaxX = slotMinX + slotWidth
            return min(max(location.x, slotMinX), slotMaxX)
        }
        
        func horizontalValue(inSlot slotIndex: Int) -> Int {
            let x = clampX(location.x, slotIndex: slotIndex) - rect.minX
            let slotMinX = CGFloat(slotIndex) * slotWidth
            let localX = min(max(x - slotMinX, 0), slotWidth)
            let t = Double(localX / slotWidth)    // 0...1
            return clampToRange(Int(round(t * 127.0)))
        }
        
        func verticalValue() -> Int {
            let clampedY = min(max(location.y - rect.minY, 0), h)
            let t = Double(1.0 - (clampedY / h))  // 0 bottom -> 1 top
            return clampToRange(Int(round(t * 127.0)))
        }
        
        switch stage {
            case .attack:
                attack = horizontalValue(inSlot: 0)
            case .decay:
                decay = horizontalValue(inSlot: 1)
            case .sustain:
                sustain = verticalValue()
            case .release:
                release = horizontalValue(inSlot: 3)
        }
    }
    
    private func clampToRange(_ value: Int) -> Int {
        max(range.lowerBound, min(range.upperBound, value))
    }
    
    // MARK: - Grid Background
    
    /// Draws background panel, grid lines, and slot labels "A D S R".
    private func gridBackground(in rect: CGRect) -> some View {
        let slot = rect.width / 4.0
        let vLinesPerSlot = 4   // vertical grid subdivisions per slot
        let hLines = 6          // horizontal grid lines
        
        return ZStack {
            // Panel
            RoundedRectangle(cornerRadius: 12)
                .fill(.background.opacity(0.45))
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.secondary.opacity(0.35), lineWidth: 1)
            
            // Grid
            Path { p in
                // Vertical grid
                let totalV = vLinesPerSlot * 4
                for i in 0...totalV {
                    let x = rect.minX + CGFloat(i) * (rect.width / CGFloat(totalV))
                    p.move(to: CGPoint(x: x, y: rect.minY))
                    p.addLine(to: CGPoint(x: x, y: rect.maxY))
                }
                // Horizontal grid
                for j in 0...hLines {
                    let y = rect.minY + CGFloat(j) * (rect.height / CGFloat(hLines))
                    p.move(to: CGPoint(x: rect.minX, y: y))
                    p.addLine(to: CGPoint(x: rect.maxX, y: y))
                }
            }
            .stroke(.secondary.opacity(0.18), lineWidth: 1)
            
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
            
            // A / D / S / R labels
            HStack(spacing: 0) {
                ForEach(["A","D","S","R"], id: \.self) { label in
                    Text(label)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: slot, height: 16)
                }
            }
            .frame(width: rect.width,
                   height: rect.height,
                   alignment: .bottomLeading)
            .offset(y: -4)
        }
    }
    
    // MARK: - Slider Row
    
    /// Single row showing a label, slider (0...127), numeric value, and optional extra text.
    private func sliderRow(title: String,
                           value: Binding<Int>,
                           extra: String? = nil) -> some View {
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
    }
    
    // MARK: - Geometry helper (must match ADSREnvelopeShape)
    
    /// Computes the key points of the envelope polyline for use by both:
    ///  - ADSREnvelopeShape (for drawing)
    ///  - determineStage(...) (for hit testing "fatter" around handles)
    ///
    /// If you change the visual geometry in `ADSREnvelopeShape`, keep this
    /// function in sync so hit testing still matches what you see.
    private func envelopePoints(in rect: CGRect)
    -> (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint)
    {
        let w = rect.width
        let h = rect.height
        let slot = w / 4.0
        
        // Match ADSREnvelopeShape's mapping:
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

// MARK: - Envelope Shape
//
// Same geometry as in `envelopePoints(in:)`. If you change one, change the other.
//
struct ADSREnvelopeShape: Shape {
    var attack: Double       // 0...127
    var decay: Double        // 0...127
    var sustainLevel: Double // 0...127
    var release: Double      // 0...127
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
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
        
        let sustainY = yForLevel(sustainLevel)
        
        let aW = widthFor(attack)
        let dW = widthFor(decay)
        let sW = slot                     // fixed width sustain
        let rW = widthFor(release)
        
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
        
        path.move(to: p0)
        path.addLine(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p4)
        
        // Small node handles to show draggable points
        let handleSize: CGFloat = 6
        [p1, p2, p3].forEach { point in
            let r = CGRect(
                x: point.x - handleSize / 2,
                y: point.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            path.addEllipse(in: r)
        }
        return path
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
