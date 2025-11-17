import SwiftUI

// MARK: - Mapping between UI 1...63 and MiniWorks MIDI 0...127

enum ADSRValueMapping {
    static func uiToMidi(_ uiValue: Int) -> Int {
        let clamped = min(max(uiValue, 1), 63)
        // 1 -> 0, 63 -> 127
        let t = Double(clamped - 1) / 62.0
        return Int((t * 127.0).rounded())
    }
    
    static func midiToUi(_ midiValue: Int) -> Int {
        let clamped = min(max(midiValue, 0), 127)
        let t = Double(clamped) / 127.0
        return Int((t * 62.0).rounded()) + 1
    }
}

// MARK: - Public ADSR Envelope Editor

struct ADSREnvelopeEditor: View {
    @Binding var attack: Int    // 1...63
    @Binding var decay: Int     // 1...63
    @Binding var sustain: Int   // 1...63
    @Binding var release: Int   // 1...63
    
    private let knobRange = 1...127
    
    // MIDI-mapped values (0...127)
    var midiAttack: Int  { ADSRValueMapping.uiToMidi(attack) }
    var midiDecay: Int   { ADSRValueMapping.uiToMidi(decay) }
    var midiSustain: Int { ADSRValueMapping.uiToMidi(sustain) }
    var midiRelease: Int { ADSRValueMapping.uiToMidi(release) }
    
    func loadFromMidi(attack a: Int, decay d: Int, sustain s: Int, release r: Int) {
        attack  = ADSRValueMapping.midiToUi(a)
        decay   = ADSRValueMapping.midiToUi(d)
        sustain = ADSRValueMapping.midiToUi(s)
        release = ADSRValueMapping.midiToUi(r)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Envelope drawing (each stage independent)
            ADSREnvelopeShape(
                attack: Double(attack),
                decay: Double(decay),
                sustain: Double(sustain),
                release: Double(release)
            )
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .aspectRatio(2.0, contentMode: .fit)
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.secondary.opacity(0.4), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.background.opacity(0.4))
                    )
            )
            .padding(.horizontal)
            
            // Knobs with dual readouts
            HStack(spacing: 24) {
                ADSRKnob(
                    value: $attack,
                    range: knobRange,
                    label: "Attack",
                    midiValue: midiAttack
                )
                ADSRKnob(
                    value: $decay,
                    range: knobRange,
                    label: "Decay",
                    midiValue: midiDecay
                )
                ADSRKnob(
                    value: $sustain,
                    range: knobRange,
                    label: "Sustain",
                    midiValue: midiSustain
                )
                ADSRKnob(
                    value: $release,
                    range: knobRange,
                    label: "Release",
                    midiValue: midiRelease
                )
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Envelope Shape (updated so sections don't affect each other)

/// Each stage gets its own horizontal "slot" (1/4 of the width).
/// Inside that slot, the actual used width is proportional to that stage's value (1...63).
/// So changing Attack only stretches/shrinks the Attack segment, without compressing others.
struct ADSREnvelopeShape: Shape {
    var attack: Double
    var decay: Double
    var sustain: Double
    var release: Double
    
    var maxStageValue: Double = 127.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        let baseY = rect.maxY
        let peakY = rect.minY + height * 0.05      // near the top
        let sustainY = rect.minY + height * 0.35   // sustain level
        
        // Each stage gets 1/4 of the width.
        let slotWidth = width / 4.0
        
        // Normalize each stage to its slot independently.
        func stageWidth(for value: Double) -> CGFloat {
            let clamped = max(1.0, min(value, maxStageValue))
            let t = clamped / maxStageValue          // 1.0 -> small, 63.0 -> full slot
            return slotWidth * t
        }
        
        let attackWidth  = stageWidth(for: attack)
        let decayWidth   = stageWidth(for: decay)
        let sustainWidth = stageWidth(for: sustain)
        let releaseWidth = stageWidth(for: release)
        
        // Lower left
        let p0 = CGPoint(x: rect.minX, y: baseY)
        // X:  Lower left + section width (width/4)
        // Y: Just below the top
        let p1 = CGPoint(x: p0.x + attackWidth, y: peakY)
        // X: start of the next section
        // 
        let p2 = CGPoint(x: p1.x + decayWidth, y: sustainY)
        let p3 = CGPoint(x: p2.x + sustainWidth, y: sustainY)
        let p4 = CGPoint(x: p3.x + releaseWidth, y: baseY)
        
        path.move(to: p0)
        path.addLine(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p4)
        
        return path
    }
}

// MARK: - Rotary Knob with UI + MIDI readouts

struct ADSRKnob: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    let midiValue: Int?
    
    @State private var startValue: Int?
    
    private var normalized: Double {
        let minV = Double(range.lowerBound)
        let maxV = Double(range.upperBound)
        let clamped = min(max(Double(value), minV), maxV)
        return (clamped - minV) / (maxV - minV)
    }
    
    private var angle: Angle {
        Angle(degrees: -150 + normalized * 300)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let knobRadius = size / 2.0
                
                ZStack {
                    Circle()
                        .fill(.ultraThickMaterial)
                        .shadow(radius: 2)
                    
                    Circle()
                        .strokeBorder(.secondary.opacity(0.4), lineWidth: 2)
                    
                    Capsule(style: .continuous)
                        .frame(width: 2, height: knobRadius * 0.35)
                        .offset(y: -knobRadius * 0.55)
                        .foregroundStyle(.secondary)
                    
                    Capsule(style: .continuous)
                        .frame(width: 3, height: knobRadius * 0.5)
                        .offset(y: -knobRadius * 0.35)
                        .foregroundStyle(.primary)
                        .rotationEffect(angle)
                    
                    Text("\(value)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .frame(width: size, height: size)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if startValue == nil {
                                startValue = value
                            }
                            guard let start = startValue else { return }
                            
                            let sensitivity: Double = 3.0
                            let delta = -Double(gesture.translation.height) / sensitivity
                            let newValue = start + Int(delta.rounded())
                            value = max(range.lowerBound,
                                        min(range.upperBound, newValue))
                        }
                        .onEnded { _ in
                            startValue = nil
                        }
                )
            }
            .aspectRatio(1, contentMode: .fit)
            
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                
                if let midi = midiValue {
                    Text("UI \(value) • MIDI \(midi)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("UI \(value)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 80, height: 110)
    }
}

// MARK: - Preview

struct ADSREnvelopeEditor_Previews: PreviewProvider {
    struct DemoContainer: View {
        @State private var attack = 64
        @State private var decay = 64
        @State private var sustain = 64
        @State private var release = 64
        
        var body: some View {
            VStack {
                ADSREnvelopeEditor(
                    attack: $attack,
                    decay: $decay,
                    sustain: $sustain,
                    release: $release
                )
                .padding()
                
                Text("VCF/VCA MIDI: " +
                     "A \(ADSRValueMapping.uiToMidi(attack))  " +
                     "D \(ADSRValueMapping.uiToMidi(decay))  " +
                     "S \(ADSRValueMapping.uiToMidi(sustain))  " +
                     "R \(ADSRValueMapping.uiToMidi(release))")
                .font(.caption.monospacedDigit())
                .padding(.top, 8)
            }
        }
    }
    
    static var previews: some View {
        DemoContainer()
            .preferredColorScheme(.dark)
        DemoContainer()
            .preferredColorScheme(.light)
    }
}
