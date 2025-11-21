//
//  ADSREnvelopeEditor.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI
import Foundation


// MARK: - ADSR Envelope Editor

/// Main interactive ADSR view.
///
/// Responsibilities:
/// - Display the ADSR envelope shape within a fixed 4-slot layout:
///     [ Attack | Decay | Sustain | Release ]
/// - Provide an interactive gesture to adjust values:
///     * Attack, Decay, Release: horizontal movement along each segment
///     * Sustain: vertical movement only
/// - Show a background grid, including a log-scaled attack time grid
///   that highlights the current attack "time band".
/// - Expose sliders for all four stages, colored to match their segments.
struct ADSREnvelopeEditor: View {
    // Stage values (0...127)
    var attack: ProgramParameter
    var decay: ProgramParameter
    var sustain: ProgramParameter   // level (vertical)
    var release: ProgramParameter
    
    private let range = 0...127
    
    /// Which stage is actively being edited by a drag.
    ///
    /// Design:
    /// - When a drag begins, we determine which segment (A/D/S/R) is closest
    ///   to the starting location and "lock" onto that stage.
    /// - While the drag continues, only that stage is updated, even if
    ///   the gesture crosses into other segments horizontally.
    @State private var activeStage: Stage? = nil
    
    /// ADSR stages.
    enum Stage {
        case attack, decay, sustain, release
    }
    
    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                // The main envelope drawing lives in this GeometryReader
                // so it adapts to any given size.
                let rect = CGRect(origin: .zero, size: geo.size)

                // Compute the ADSR polyline points *once* per layout pass.
                // These points are used by:
                //  - The envelope rendering
                //  - The background labeling that follows the shape (A/D/S/R)
                //  - The interaction logic for hit-testing and parameter mapping.
                let points = envelopePoints(in: rect) // shared geometry for drawing & hit testing
                
                ZStack {
                    gridBackground(
                        in: rect,
                        points: points,
                        attackValue: attack.value
                    )
                    coloredEnvelope(in: rect, points: points)
                }
                .contentShape(Rectangle())
                // IMPORTANT: Only a drag updates values.
                // A simple tap (down/up with < minimumDistance movement) does nothing.
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
//            HStack(spacing: 40) {
            HStack {
                VStack(alignment: .center, spacing: 20) {
                    Text("\(attack.value)")
                    CircularFader(value: attack.knobBinding,
                                  size: 40,
                                  mode: .unidirectional(color: ADSRStageColors.attack))
//                    CircularFader(value: attack.knobBinding,
//                                  size: 40,
//                                  ringColor: ADSRStageColors.attack)
                    Text("Attack")
                }
                
                VStack(alignment: .center, spacing: 20) {
                    Text("\(decay.value)")
                    CircularFader(value: decay.knobBinding,
                                  size: 40,
                                  mode: .unidirectional(color: ADSRStageColors.decay))
                    Text("Decay")
                }

                VStack(alignment: .center, spacing: 20) {
                    Text("\(sustain.value)")
                    CircularFader(value: sustain.knobBinding,
                                  size: 40,
                                  mode: .unidirectional(color: ADSRStageColors.sustain))
                    Text("Sustain")
                }

                VStack(alignment: .center, spacing: 20) {
                    Text("\(release.value)")
                    CircularFader(value: release.knobBinding,
                                  size: 40,
                                  mode: .unidirectional(color: ADSRStageColors.release))
                    Text("Release")
                }

            }
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
    ///
    /// Why segment distance and not just "slot" x-position?
    /// - Using slots (e.g. divide width into 4 columns) can make it too easy to
    ///   accidentally grab the wrong stage, especially when the envelope lines
    ///   are near the edges or when segments are short.
    /// - Using the actual geometric distance to the segment better matches
    ///   what the eye sees and what the user expects to grab.
    private func determineStage(at location: CGPoint, in rect: CGRect) -> Stage? {
        let points = envelopePoints(in: rect)
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        // Helper: distance from a point to a line segment
        //
        // Geometric idea:
        //   - Treat the segment AB and point P.
        //   - Compute the projection of AP onto AB.
        //   - Clamp to [0,1] to stay within the segment.
        //   - Measure the distance from P to that projected point.
        func distanceToSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
            if a == b { return hypot(point.x - a.x, point.y - a.y) }
            
            let ap = CGPoint(x: point.x - a.x, y: point.y - a.y)
            let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
            let abLen2 = ab.x * ab.x + ab.y * ab.y
            
            // Dot(AP, AB) / |AB|^2
            let t = max(0, min(1, (ap.x * ab.x + ap.y * ab.y) / abLen2))
            let proj = CGPoint(x: a.x + ab.x * t, y: a.y + ab.y * t)
            return hypot(point.x - proj.x, point.y - proj.y)
        }
        
        // Distances to each stage's line segment
        //
        // Attack:  segment p0 -> p1
        // Decay:   segment p1 -> p2
        // Sustain: segment p2 -> p3
        // Release: segment p3 -> p4
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
        
        // Pick the stage whose segment is closest to the touch point.
        guard let (stage, minDistance) = distances.min(by: { $0.1 < $1.1 }) else {
            return nil
        }
        
        // Threshold: how close you must be to the envelope to grab a stage.
        // Increase to make hit areas "fatter"; decrease to require more precision.
        let maxDistance: CGFloat = min(rect.width, rect.height) * 0.15
        
        return (minDistance <= maxDistance) ? stage : nil
    }
    
    // MARK: - Stage Value Updates (segment-based)
    
    /// Project a point onto a segment AB and return the parameter t in [0, 1]
    /// where t=0 is at `a` and t=1 is at `b`.
    ///
    /// This is similar to the distance helper, but we return the normalized
    /// projection parameter instead of the actual distance.
    private func tAlongSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> Double {
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let ap = CGPoint(x: point.x - a.x, y: point.y - a.y)
        let abLen2 = ab.x * ab.x + ab.y * ab.y
        
        guard abLen2 > 0 else { return 0.0 } // segment collapsed
        let t = (ap.x * ab.x + ap.y * ab.y) / abLen2
        return Double(max(0, min(1, t)))
    }
    
    /// Map a touch location to a new value for a given stage:
    ///
    ///   - Attack, Decay, Release:
    ///       * Use the *actual line segment* for that stage (p0->p1, p1->p2, p3->p4).
    ///       * Compute t in [0,1] along that segment using `tAlongSegment`.
    ///       * Map t linearly to the MIDI value range 0...127.
    ///
    ///   - Sustain:
    ///       * Use vertical position only.
    ///       * Top of the view is high sustain (127), bottom is low sustain (0).
    ///
    /// This avoids confusing "slot-based" mapping and keeps the behavior tightly
    /// coupled to what the user sees on screen.
    private func updateStage(_ stage: Stage, with location: CGPoint, in rect: CGRect) {
        let h = rect.height
        let points = envelopePoints(in: rect)
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        // Convert (x,y) to a vertical sustain value in 0...127
        func verticalValue() -> Int {
            let clampedY = min(max(location.y - rect.minY, 0), h)
            let t = Double(1.0 - (clampedY / h))  // 0 bottom -> 1 top
            return clampToIntRange(Int(round(t * 127.0)))
        }
        
        
        func verticalUInt8Value() -> UInt8 {
            let clampedY = min(max(location.y - rect.minY, 0), h)
            let t = Double(1.0 - (clampedY / h))  // 0 bottom -> 1 top
            return clampToUInt8Range(UInt8(round(t * 127.0)))
        }
        
        
        switch stage {
            case .attack:
                // Attack uses the segment p0 -> p1
                let t = tAlongSegment(point: location, a: p0, b: p1)
                attack._value = clampToUInt8Range(UInt8(round(t * 127.0)))
            case .decay:
                // Decay uses the segment p1 -> p2
                let t = tAlongSegment(point: location, a: p1, b: p2)
                decay._value = clampToUInt8Range(UInt8(round(t * 127.0)))
//                decay = clampToRange(Int(round(t * 127.0)))
            case .sustain:
                // Sustain uses vertical position only.
                sustain._value = verticalUInt8Value()
            case .release:
                // Release uses the segment p3 -> p4
                let t = tAlongSegment(point: location, a: p3, b: p4)
                release._value = clampToUInt8Range(UInt8(round(t * 127.0)))
//                release = clampToRange(Int(round(t * 127.0)))
        }
    }
    
    /// Clamp a MIDI value into the 0...127 range.
    private func clampToIntRange(_ value: Int) -> Int {
        max(range.lowerBound, min(range.upperBound, value))
    }
    
    private func clampToUInt8Range(_ value: UInt8) -> UInt8 {
        UInt8(clampToIntRange(Int(value)))
    }

    // MARK: - Colored Envelope
    
    /// Draws the ADSR envelope polyline as four separately colored segments,
    /// plus colored circular handles for A, D, and S.
    ///
    /// Segment layout:
    ///   p0 -> p1 : Attack
    ///   p1 -> p2 : Decay
    ///   p2 -> p3 : Sustain
    ///   p3 -> p4 : Release
    ///
    /// The handle positions match the key joints:
    ///   p1: end of Attack, start of Decay
    ///   p2: end of Decay, start of Sustain
    ///   p3: end of Sustain, start of Release
    private func coloredEnvelope(in rect: CGRect,
                                 points: (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint)) -> some View {
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        return ZStack {
            // Attack segment
            Path { path in
                path.move(to: p0)
                path.addLine(to: p1)
            }
            .stroke(ADSRStageColors.attack, lineWidth: 2)
            
            // Decay segment
            Path { path in
                path.move(to: p1)
                path.addLine(to: p2)
            }
            .stroke(ADSRStageColors.decay, lineWidth: 2)
            
            // Sustain segment
            Path { path in
                path.move(to: p2)
                path.addLine(to: p3)
            }
            .stroke(ADSRStageColors.sustain, lineWidth: 2)
            
            // Release segment
            Path { path in
                path.move(to: p3)
                path.addLine(to: p4)
            }
            .stroke(ADSRStageColors.release, lineWidth: 2)
            
            // Draw small circular handles for the main control points
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
    
    /// Draws:
    ///  - The outer panel and linear grid
    ///  - The attack log-scale grid and highlighted tick lines
    ///  - Slot separators between A/D/S/R
    ///  - Floating "A D S R" labels that follow the envelope segments
    private func gridBackground(
        in rect: CGRect,
        points: (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint),
        attackValue: UInt8
    ) -> some View {
        let slot = rect.width / 4.0
        let vLinesPerSlot = 4
        let hLines = 6
        
        return ZStack {
            // Panel background + border
            RoundedRectangle(cornerRadius: 12)
                .fill(.background.opacity(0.45))
            
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.secondary.opacity(0.35), lineWidth: 1)
            
            // Global linear grid for orientation
            Path { p in
                let totalV = vLinesPerSlot * 4
                // Vertical lines
                for i in 0...totalV {
                    let x = rect.minX + CGFloat(i) * (rect.width / CGFloat(totalV))
                    p.move(to: CGPoint(x: x, y: rect.minY))
                    p.addLine(to: CGPoint(x: x, y: rect.maxY))
                }
                // Horizontal lines
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
            
            // Slot separators between Attack / Decay / Sustain / Release
            Path { p in
                for i in 1..<4 {
                    let x = rect.minX + CGFloat(i) * slot
                    p.move(to: CGPoint(x: x, y: rect.minY))
                    p.addLine(to: CGPoint(x: x, y: rect.maxY))
                }
            }
            .stroke(.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            
            // Floating ADSR labels (move with the envelope)
            floatingADSRLabels(in: rect, points: points)
        }
    }
    
    /// Attack slot log-scale grid.
    ///
    ///  - All tick lines are drawn in a faint attack color.
    ///  - The two lines that bound the *current* attack time band are
    ///    drawn brighter and the labels are also emphasized.
    ///  - The legend sits above the top of the graph in the attack region.
    private func attackLogGridAndLegend(
        in rect: CGRect,
        slotWidth: CGFloat,
        attackValue: UInt8
    ) -> some View {
        // Time markers (ms) for log ticks / legend.
        // Chosen to cover a musically meaningful range:
        //   2ms (very snappy) up to 60s (extremely slow).
        let timeMarkersMs: [Double] = [2, 10, 100, 1000, 10000, 60000]
        
        // Internal representation of a grid marker
        struct Marker {
            let ms: Double   // time in ms
            let midi: UInt8    // corresponding MIDI value (approx)
            let x: CGFloat   // x-position in the attack slot
            let label: String
        }
        
        // Build the markers: map time -> midi -> x-position in [0, slotWidth]
        let markers: [Marker] = timeMarkersMs.map { ms in
            let midi = ADSRAttackTime.midi(fromMilliseconds: ms)
            let t = Double(midi) / 127.0
            let x = rect.minX + CGFloat(t) * slotWidth
            
            // Short label for each marker
            let label: String
            if ms < 1000 {
                label = "\(Int(ms))\nms"
            } else {
                label = "\(Int(ms / 1000))s"
            }
            return Marker(ms: ms, midi: midi, x: x, label: label)
        }
        
        // Determine which two markers bound the current attack time.
        //
        // Cases:
        //  - If attackMs is between two markers -> highlight that pair.
        //  - If attackMs is below first marker   -> highlight first two.
        //  - If attackMs is above last marker    -> highlight last two.
        let attackMs = ADSRAttackTime.ms(from: attackValue)
        var highlightedIndices: Set<Int> = []
        
        if let idx = (0..<(markers.count - 1)).first(where: { attackMs >= markers[$0].ms && attackMs <= markers[$0 + 1].ms }) {
            highlightedIndices.insert(idx)
            highlightedIndices.insert(idx + 1)
        }
        else if attackMs < markers.first?.ms ?? 0 {
            highlightedIndices.insert(0)
            if markers.count > 1 { highlightedIndices.insert(1) }
        }
        else if attackMs > markers.last?.ms ?? 0 {
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
            
            // Legend ABOVE the grid: labels for each marker
            ForEach(Array(markers.enumerated()), id: \.offset) { index, marker in
                let isHighlighted = highlightedIndices.contains(index)
                Text(marker.label)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(
                        isHighlighted
                        ? ADSRStageColors.attack
                        : ADSRStageColors.attack.opacity(0.2)
                    )
                    .position(x: marker.x,
                              y: rect.minY - 10)
            }
        }
    }
    
    /// Places "A", "D", "S", "R" roughly at the center of their corresponding
    /// segment (in both x and y), so they move with the envelope.
    ///
    /// This avoids the classic "labels stuck at the bottom" issue and keeps
    /// the labeling visually tied to the shape the user is manipulating.
    private func floatingADSRLabels(
        in rect: CGRect,
        points: (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint)
    ) -> some View {
        let p0 = points.p0
        let p1 = points.p1
        let p2 = points.p2
        let p3 = points.p3
        let p4 = points.p4
        
        // Simple midpoints of segments
        let midA = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
        let midD = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
        let midS = CGPoint(x: (p2.x + p3.x) / 2, y: (p2.y + p3.y) / 2)
        let midR = CGPoint(x: (p3.x + p4.x) / 2, y: (p3.y + p4.y) / 2)
        
        // Slight vertical offset so the letter doesn't sit directly on the line
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
    
    /// Renders a row in the control section:
    ///  - Left-aligned label (e.g. "Attack")
    ///  - Colored slider bound to the given value (0...127)
    ///  - Numeric readout of the raw MIDI value
    ///  - Optional "extra" readout (e.g. time in ms/s)
    ///  - Optional legend line under the row (used for Attack time scale)
//    private func sliderRow(title: String,
//                           value: Binding<UInt8>,
//                           color: Color,
//                           extra: String? = nil,
//                           legend: String? = nil) -> some View {
//        VStack(alignment: .leading, spacing: 2) {
//            HStack(spacing: 10) {
//                Text(title)
//                    .frame(width: 140, alignment: .leading)
//                
//                Slider(
//                    value: Binding(
//                        get: { Double(value.wrappedValue) },
//                        set: { newVal in
//                            value.wrappedValue = clampToUInt8Range(UInt8(newVal.rounded()))
//                        }
//                    ),
//                    in: 0...127,
//                    step: 1
//                )
//                .tint(color)
//                .accessibilityLabel(Text(title))
//                .accessibilityValue(Text("\(value.wrappedValue)"))
//                
//                Text(String(format: "%3d", value.wrappedValue))
//                    .font(.caption2.monospacedDigit())
//                    .foregroundStyle(.secondary)
//                    .frame(width: 40, alignment: .trailing)
//                
//                if let extra = extra {
//                    Text(extra)
//                        .font(.caption2.monospacedDigit())
//                        .foregroundStyle(.secondary)
//                        .frame(minWidth: 80, alignment: .trailing)
//                }
//            }
//            
//            if let legend = legend {
//                Text(legend)
//                    .font(.caption2.monospacedDigit())
//                    .foregroundStyle(color.opacity(0.9))
//                    .padding(.leading, 140) // align under slider area (same as label width)
//            }
//        }
//    }
    
    // MARK: - Geometry helper
    
    /// Computes the key points of the envelope polyline for use by:
    ///  - coloredEnvelope(...)   (drawing)
    ///  - determineStage(...)    (hit testing)
    ///  - updateStage(...)       (value mapping)
    ///  - floatingADSRLabels(...) (moving labels with envelope)
    ///
    /// Layout model:
    ///  - The total width is divided into 4 equal "slots" for A/D/S/R.
    ///  - Attack, Decay, Release interpret their 0...127 value as
    ///    "relative width within their slot".
    ///  - Sustain interprets its 0...127 value as a vertical level.
    private func envelopePoints(in rect: CGRect)
    -> (p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) {
        let w = rect.width
        let h = rect.height
        let slot = w / 4.0
        
            // Convert a sustain-like value (0...127) into a y-position,
            // with some padding at the top and bottom.
            //
            // 127 -> near top
            //   0 -> near bottom
        func yForLevel(_ v: Double) -> CGFloat {
            let t = max(0.0, min(1.0, v / 127.0))
            let topPad: CGFloat = h * 0.08
            let bottomPad: CGFloat = h * 0.06
            return rect.maxY - bottomPad - CGFloat(t) * (h - topPad - bottomPad)
        }
        
            // Convert a time-like value (0...127) into a width within a slot.
            //
            // This keeps each stage's temporal domain visually independent and avoids
            // compressing other stages when one is long.
        func widthFor(_ v: Double) -> CGFloat {
            let t = max(0.0, min(1.0, v / 127.0))
            return slot * CGFloat(t)
        }
        
            // Sustain horizontal line's y coordinate
        let sustainY = yForLevel(Double(sustain.value))
        
            // Stage-specific widths
        let aW = widthFor(Double(attack.value))
        let dW = widthFor(Double(decay.value))
        let sW = slot
        let rW = widthFor(Double(release.value))
        
            // Points:
            // p0: start (time=0, level=0)
            // p1: end of Attack (top of envelope)
            // p2: end of Decay (reached sustain)
            // p3: end of Sustain (fixed slot width)
            // p4: end of Release (back to zero)
        let p0 = CGPoint(x: rect.minX, y: rect.maxY)
        let p1 = CGPoint(x: rect.minX + aW, y: rect.minY + h * 0.08)
        let p2 = CGPoint(x: p1.x + dW, y: sustainY)
        let p3 = CGPoint(x: p2.x + sW, y: sustainY)
        let p4 = CGPoint(x: p3.x + rW, y: rect.maxY)
        
        return (p0, p1, p2, p3, p4)
    }
}



#Preview {
    @Previewable @State var viewModel: EditorViewModel = .init()
    viewModel.program.vcfEnvelopeAttack._value = 64
    viewModel.program.vcfEnvelopeDecay._value = 64
    viewModel.program.vcfEnvelopeSustain._value = 64
    viewModel.program.vcfEnvelopeRelease._value = 64

    return VStack {
//        Spacer(minLength: 30)
        ADSREnvelopeEditor(attack: viewModel.program.vcfEnvelopeAttack,
                           decay: viewModel.program.vcfEnvelopeDecay,
                           sustain: viewModel.program.vcfEnvelopeSustain,
                           release: viewModel.program.vcfEnvelopeRelease)
//        .frame(width: 400, height: 300)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: 350, height: 350)
//    .frame(maxWidth: .infinity, maxHeight: .infinity)
//    .padding()
    
}
