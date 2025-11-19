//
//  ADSRView.swift
//  MiniWorksMIDI
//
//  Visual representation of an ADSR envelope with BOTH knobs and direct
//  manipulation of the envelope shape itself. Users can click and drag
//  directly on the envelope curve to adjust parameters intuitively.
//
//  ADSR Envelope Explained:
//  An ADSR envelope controls how a sound changes over time when you press
//  and release a key on a synthesizer. It has four stages:
//
//  - Attack (A): How long it takes for the sound to reach full volume
//    after you press a key. Short = punchy, Long = slow fade-in
//  - Decay (D): How long it takes to fall from peak to the sustain level
//  - Sustain (S): The volume level held while you keep the key pressed
//    (This is a LEVEL, not a time - the sound stays here until you release)
//  - Release (R): How long the sound takes to fade to silence after you
//    release the key. Short = abrupt stop, Long = gradual fade
//
//  Direct Manipulation:
//  - Drag the attack peak horizontally to change attack time
//  - Drag the decay corner to change decay time
//  - Drag the sustain line vertically to change sustain level
//  - Drag the release endpoint to change release time
//

import SwiftUI

struct ADSRView: View {
    let title: String
    @Binding var attack: Int
    @Binding var decay: Int
    @Binding var sustain: Int
    @Binding var release: Int
    var onChange: ((Int) -> Void)?
    
    private let range = 0...127
    
    @State private var draggedSegment: EnvelopeSegment?
    @State private var isDragging = false
    
    enum EnvelopeSegment {
        case attack, decay, sustain, release
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            
            // Interactive envelope visualization
            ZStack {
                // Background grid for reference
                envelopeGrid
                
                // The envelope shape
                envelopeShape
                    .stroke(isDragging ? Color.blue : Color.blue.opacity(0.8), lineWidth: 2.5)
                
                // Interactive control points
                envelopeControlPoints
            }
            .frame(height: 140)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.05))
            )
            .gesture(envelopeDragGesture)
            
            // Helper text showing what's being adjusted
            if let segment = draggedSegment {
                Text(segmentDescription(segment))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // ADSR knobs for precise control
            HStack(spacing: 20) {
                KnobView(label: "Attack", value: $attack, range: range, onChange: onChange)
                KnobView(label: "Decay", value: $decay, range: range, onChange: onChange)
                KnobView(label: "Sustain", value: $sustain, range: range, onChange: onChange)
                KnobView(label: "Release", value: $release, range: range, onChange: onChange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Envelope Visualization
    
    private var envelopeGrid: some View {
        GeometryReader { geo in
            Path { path in
                // Horizontal grid lines (amplitude levels)
                for i in 0...4 {
                    let y = geo.size.height * CGFloat(i) / 4.0
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                
                // Vertical grid lines (time divisions)
                for i in 0...8 {
                    let x = geo.size.width * CGFloat(i) / 8.0
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
            }
            .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
        }
    }
    
    private var envelopeShape: some Shape {
        EnvelopePath(
            attack: Double(attack) / 127.0,
            decay: Double(decay) / 127.0,
            sustain: Double(sustain) / 127.0,
            release: Double(release) / 127.0
        )
    }
    
    private var envelopeControlPoints: some View {
        GeometryReader { geo in
            let points = calculateControlPoints(in: geo.size)
            
            ZStack {
                // Attack peak point
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 12, height: 12)
                    .position(points.attackPeak)
                
                // Decay endpoint / Sustain start
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 12, height: 12)
                    .position(points.decayEnd)
                
                // Sustain line (horizontal indicator)
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: points.sustainEnd.x - points.decayEnd.x, height: 2)
                    .position(x: (points.decayEnd.x + points.sustainEnd.x) / 2, y: points.decayEnd.y)
                
                // Release endpoint
                Circle()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 12, height: 12)
                    .position(points.releaseEnd)
            }
        }
    }
    
    // MARK: - Direct Manipulation
    
    private var envelopeDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    // Determine which segment the user clicked on
                    draggedSegment = detectSegment(at: value.startLocation)
                    isDragging = true
                }
                
                guard let segment = draggedSegment else { return }
                updateParameter(segment: segment, location: value.location)
            }
            .onEnded { _ in
                isDragging = false
                draggedSegment = nil
            }
    }
    
    private func detectSegment(at location: CGPoint) -> EnvelopeSegment? {
        // This would ideally use the actual geometry, but for simplicity
        // we'll use normalized positions
        let normalizedX = location.x / 200.0  // Approximate width
        
        if normalizedX < 0.25 {
            return .attack
        } else if normalizedX < 0.45 {
            return .decay
        } else if normalizedX < 0.65 {
            return .sustain
        } else {
            return .release
        }
    }
    
    private func updateParameter(segment: EnvelopeSegment, location: CGPoint) {
        // Convert location to parameter values
        // X axis = time (0-127), Y axis = level (0-127, inverted)
        let normalizedX = max(0, min(1, location.x / 200.0))
        let normalizedY = max(0, min(1, 1.0 - (location.y / 140.0)))
        
        switch segment {
        case .attack:
            // Attack: control time with horizontal drag
            let newValue = Int(normalizedX * 255.0).clamped(to: range)
            if newValue != attack {
                attack = newValue
                onChange?(newValue)
            }
            
        case .decay:
            // Decay: control time with horizontal drag
            let newValue = Int(normalizedX * 255.0).clamped(to: range)
            if newValue != decay {
                decay = newValue
                onChange?(newValue)
            }
            
        case .sustain:
            // Sustain: control level with vertical drag
            let newValue = Int(normalizedY * 127.0).clamped(to: range)
            if newValue != sustain {
                sustain = newValue
                onChange?(newValue)
            }
            
        case .release:
            // Release: control time with horizontal drag
            let newValue = Int(normalizedX * 255.0).clamped(to: range)
            if newValue != release {
                release = newValue
                onChange?(newValue)
            }
        }
    }
    
    private func calculateControlPoints(in size: CGSize) -> ControlPoints {
        let totalTime = Double(attack + decay) / 127.0 * 0.6 + 0.2 + Double(release) / 127.0 * 0.4
        
        let attackWidth = (Double(attack) / 127.0 * 0.6 / totalTime) * size.width
        let decayWidth = (Double(decay) / 127.0 * 0.6 / totalTime) * size.width
        let sustainWidth = (0.2 / totalTime) * size.width
        let releaseWidth = (Double(release) / 127.0 * 0.4 / totalTime) * size.width
        
        let peakY = size.height * 0.1
        let sustainY = size.height * (1.0 - Double(sustain) / 127.0 * 0.8) - size.height * 0.1
        let baseY = size.height * 0.9
        
        return ControlPoints(
            attackPeak: CGPoint(x: attackWidth, y: peakY),
            decayEnd: CGPoint(x: attackWidth + decayWidth, y: sustainY),
            sustainEnd: CGPoint(x: attackWidth + decayWidth + sustainWidth, y: sustainY),
            releaseEnd: CGPoint(x: attackWidth + decayWidth + sustainWidth + releaseWidth, y: baseY)
        )
    }
    
    private func segmentDescription(_ segment: EnvelopeSegment) -> String {
        switch segment {
        case .attack:
            return "Adjusting Attack Time (\(attack)) - How fast the sound rises"
        case .decay:
            return "Adjusting Decay Time (\(decay)) - How fast it falls to sustain"
        case .sustain:
            return "Adjusting Sustain Level (\(sustain)) - Volume while key is held"
        case .release:
            return "Adjusting Release Time (\(release)) - How fast it fades after release"
        }
    }
    
    struct ControlPoints {
        let attackPeak: CGPoint
        let decayEnd: CGPoint
        let sustainEnd: CGPoint
        let releaseEnd: CGPoint
    }
}

/// Custom shape that draws an ADSR envelope curve
struct EnvelopePath: Shape {
    let attack: Double      // 0-1
    let decay: Double       // 0-1
    let sustain: Double     // 0-1 (amplitude level)
    let release: Double     // 0-1
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Scale time segments proportionally
        // Attack and decay get more weight, sustain is fixed visual duration
        let totalTime = attack * 0.6 + decay * 0.6 + 0.2 + release * 0.4
        let sustainHoldTime = 0.2
        
        let attackWidth = (attack * 0.6 / totalTime) * rect.width
        let decayWidth = (decay * 0.6 / totalTime) * rect.width
        let sustainWidth = (sustainHoldTime / totalTime) * rect.width
        let releaseWidth = (release * 0.4 / totalTime) * rect.width
        
        let peakY = rect.minY + rect.height * 0.1
        let sustainY = rect.maxY - (sustain * rect.height * 0.8) - rect.height * 0.1
        let baseY = rect.maxY - rect.height * 0.1
        
        // Start at baseline (silence)
        path.move(to: CGPoint(x: rect.minX, y: baseY))
        
        // Attack phase: rise to peak
        path.addLine(to: CGPoint(x: rect.minX + attackWidth, y: peakY))
        
        // Decay phase: fall to sustain level
        path.addLine(to: CGPoint(x: rect.minX + attackWidth + decayWidth, y: sustainY))
        
        // Sustain phase: hold at sustain level
        path.addLine(to: CGPoint(x: rect.minX + attackWidth + decayWidth + sustainWidth, y: sustainY))
        
        // Release phase: fall to baseline
        path.addLine(to: CGPoint(x: rect.minX + attackWidth + decayWidth + sustainWidth + releaseWidth, y: baseY))
        
        return path
    }
}



#Preview {
    @Previewable @State var attack: Int = 50
    @Previewable @State var decay: Int = 50
    @Previewable @State var sustain: Int = 50
    @Previewable @State var release: Int = 50
    
    ADSRView(title: "Teting",
             attack: $attack,
             decay: $decay,
             sustain: $sustain,
             release: $release,
             onChange: nil)
}
