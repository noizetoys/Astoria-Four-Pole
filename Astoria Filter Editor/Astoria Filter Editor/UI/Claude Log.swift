import SwiftUI
import Combine


//class MIDIManager: ObservableObject {
//    @Published var isPlaying: Bool = false
//    
//    func play() {
//        isPlaying.toggle()
//    }
//    
//    func stop() {
//        isPlaying.toggle()
//    }
//}


enum ADSREnvelopeType: String, CaseIterable, Identifiable {
    case vcf
    case adsr
    
    var id: String { self.rawValue }
}


/// Main ADSR envelope editor view with visual graph and parameter sliders
struct ADSREditorView: View {
    // MARK: - Properties
    
    @ObservedObject var envelope: EnvelopeModel
    
    /// Color scheme for the envelope display
    private let envelopeColor = Color.blue
    private let backgroundColor = Color(white: 0.95)
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Waldorf 4-Pole — ADSR Envelope")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Envelope type indicator
            HStack {
                Text("Envelope Type:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(envelope.envelopeType == .vcf ? "VCF (Filter)" : "VCA (Amplifier)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Visual envelope graph
            envelopeGraphView
                .frame(height: 200)
                .padding()
            
            // ADSR parameter sliders
            VStack(spacing: 16) {
                attackSlider
                
                parameterSlider(
                    label: "Decay",
                    value: $envelope.decay,
                    color: .orange
                )
                
                parameterSlider(
                    label: "Sustain",
                    value: $envelope.sustain,
                    color: .yellow
                )
                
                parameterSlider(
                    label: "Release",
                    value: $envelope.release,
                    color: .green
                )
            }
            .padding(.horizontal)
            
            VStack {
               lfoSlider
                
                gateTimeSlider
            }
            
            // Preset buttons
            presetButtons
                .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Envelope Graph View
    
    /// Visual representation of the ADSR envelope shape
    private var envelopeGraphView: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
            
            // Grid lines
            GeometryReader { geometry in
                Path { path in
                    // Horizontal grid lines
                    for i in 0...4 {
                        let y = CGFloat(i) * geometry.size.height / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    
                    // Vertical grid lines
                    for i in 0...8 {
                        let x = CGFloat(i) * geometry.size.width / 8
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            }
            
            // ADSR envelope shape
            EnvelopeShape(
                attackTimeMs: envelope.attackTimeMs,
                decay: envelope.decay,
                sustain: envelope.sustain,
                release: envelope.release
            )
            .stroke(envelopeColor, lineWidth: 3)
            .padding(8)
            
            // Stage labels
            GeometryReader { geometry in
                stageLabels(in: geometry.size)
            }
        }
    }
    
    /// Stage labels positioned on the envelope graph
    private func stageLabels(in size: CGSize) -> some View {
        // Calculate attack time as proportion of total time for visual representation
        let normalizedAttack = log(envelope.attackTimeMs / 2.0) / log(30000.0)
        let attackX = CGFloat(max(0.02, normalizedAttack)) * size.width * 0.5
        let decayX = attackX + CGFloat(max(0.02, envelope.decay)) * size.width * 0.3
        let releaseStartX = decayX + 0.1 * size.width
        
        return ZStack(alignment: .top) {
            // Attack label
            Text("A")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.red.opacity(0.8))
                .position(x: attackX / 2, y: 10)
            
            // Decay label
            Text("D")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange.opacity(0.8))
                .position(x: (attackX + decayX) / 2, y: 10)
            
            // Sustain label
            Text("S")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.yellow.opacity(0.8))
                .position(x: (decayX + releaseStartX) / 2, y: 10)
            
            // Release label
            Text("R")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.green.opacity(0.8))
                .position(x: (releaseStartX + size.width) / 2, y: 10)
        }
    }
    
    // MARK: - Parameter Slider
    
    /// Special attack slider with logarithmic time scale
    private var attackSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Attack")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 70, alignment: .leading)
                
                Slider(
                    value: Binding(
                        get: { envelope.attackMidiValue },
                        set: { envelope.attackMidiValue = $0 }
                    ),
                    in: 0...127
                )
                .accentColor(.red)
                
                Text(EnvelopeModel.formatAttackTime(envelope.attackTimeMs))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
    
    
    private var lfoSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("LFO Rate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 70, alignment: .leading)
                
                Slider(
                    value: Binding(
                        get: {envelope.lfoRateMidiValue},
                        set: { envelope.lfoRateMidiValue = $0 }
                    ),
                    in: 0...127
                )
                .accentColor(.red)
                
                Text(EnvelopeModel.formatLfoRate(envelope.lfoRateHz))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
    
    
    private var gateTimeSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Gate Time")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 70, alignment: .trailing)
                
                Slider(
                    value: Binding(
                        get: { envelope.gateTimeMidiValue },
                        set: { envelope.gateTimeMidiValue = $0 }
                    ),
                    in: 0...127
                )
                .accentColor(Color(.systemRed))
                
                Text(EnvelopeModel.formatGateTime(envelope.gateTimeMs))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
    
    /// Reusable parameter slider with label and value display
    private func parameterSlider(label: String, value: Binding<Double>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 70, alignment: .leading)
                
                Slider(value: value, in: 0...1)
                    .accentColor(color)
                
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Preset Buttons
    
    /// Quick preset buttons for common envelope shapes
    private var presetButtons: some View {
        HStack(spacing: 12) {
            Button(action: envelope.resetToDefault) {
                Label("Default", systemImage: "arrow.counterclockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            
            Button(action: envelope.setInstant) {
                Label("Instant", systemImage: "bolt.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            
            Button(action: envelope.setSlowPad) {
                Label("Slow Pad", systemImage: "cloud.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Envelope Shape

/// SwiftUI Shape that draws the ADSR envelope curve
struct EnvelopeShape: Shape {
    var attackTimeMs: Double
    var decay: Double
    var sustain: Double
    var release: Double
    
    /// Enable smooth animations when parameters change
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, AnimatablePair<Double, Double>>> {
        get {
            // Normalize attack time for animation (use log scale)
            let normalizedAttack = log(attackTimeMs / 2.0) / log(30000.0)
            return AnimatablePair(normalizedAttack, AnimatablePair(decay, AnimatablePair(sustain, release)))
        }
        set {
            // Convert back from normalized to ms
            let normalizedAttack = max(0, min(1, newValue.first))
            attackTimeMs = 2.0 * exp(normalizedAttack * log(30000.0))
            decay = newValue.second.first
            sustain = newValue.second.second.first
            release = newValue.second.second.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Calculate X positions for each stage
        // Attack: normalize time value to 0-1 for visual representation
        let normalizedAttack = log(attackTimeMs / 2.0) / log(30000.0)
        let attackX = CGFloat(max(0.02, normalizedAttack)) * w * 0.5
        
        // Decay: attack end to attack + ~30% (minimum 2%)
        let decayX = attackX + CGFloat(max(0.02, decay)) * w * 0.3
        
        // Sustain level (inverted: 0.0 = bottom, 1.0 = top)
        let sustainY = h * (1 - CGFloat(sustain))
        
        // Sustain duration: 10% of width
        let releaseStartX = decayX + 0.25 * w
        
        // Release: sustain end to end of graph (scaled by release value)
        let releaseX = w
        
        // Draw envelope path
        path.move(to: CGPoint(x: 0, y: h))                           // Start at bottom-left
        path.addLine(to: CGPoint(x: attackX, y: 0))                  // Attack to peak
        path.addLine(to: CGPoint(x: decayX, y: sustainY))           // Decay to sustain level
        path.addLine(to: CGPoint(x: releaseStartX, y: sustainY))    // Sustain hold
        path.addLine(to: CGPoint(x: releaseX, y: h))                // Release to bottom
        
        return path
    }
}


// MARK: - Preview

#Preview {
        let envelope = EnvelopeModel()
        
        ADSREditorView(envelope: envelope)
            .frame(width: 400, height: 600)
}
