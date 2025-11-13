import SwiftUI

struct LFOView: View {
    @State private var phase: Double = 0
    @State private var frequency: Double = 1.0 // Hz
    @State private var selectedWaveform: Waveform = .sine
    @State private var timer: Timer?
    @State private var sampleHoldValue: Double = 0
    @State private var lastSamplePhase: Double = 0
    
    let minFrequency: Double = 0.008
    let maxFrequency: Double = 261.6
    
    enum Waveform: String, CaseIterable {
        case sine = "Sine"
        case triangle = "Triangle"
        case sawtooth = "Sawtooth"
        case pulse = "Pulse (Square)"
        case sampleHold = "Sample & Hold"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Low Frequency Oscillator")
                .font(.title)
                .bold()
            
            // Waveform display
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .frame(height: 250)
                
                // Grid lines
                GeometryReader { geometry in
                    Path { path in
                        // Horizontal center line
                        path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    
                    // Waveform path
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let midY = height / 2
                        let amplitude = height * 0.4
                        let points = 500
                        
                        for i in 0..<points {
                            let x = (Double(i) / Double(points)) * width
                            let localPhase = (Double(i) / Double(points)) * 2 * .pi + phase
                            let value = calculateWaveform(phase: localPhase)
                            let y = midY - (value * amplitude)
                            
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.green, lineWidth: 2)
                    
                    // Current position indicator
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .position(x: 10, y: midY(geometry: geometry))
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
            
            // Waveform selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Waveform")
                    .font(.headline)
                
                Picker("Waveform", selection: $selectedWaveform) {
                    ForEach(Waveform.allCases, id: \.self) { waveform in
                        Text(waveform.rawValue).tag(waveform)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // Frequency control
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Frequency")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.3f Hz", frequency))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("0.008")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(value: Binding(
                        get: { log10(frequency) },
                        set: { frequency = pow(10, $0) }
                    ), in: log10(minFrequency)...log10(maxFrequency))
                    
                    Text("261.6")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Preset buttons
                HStack(spacing: 10) {
                    PresetButton(title: "0.1 Hz", frequency: 0.1, currentFrequency: $frequency)
                    PresetButton(title: "1 Hz", frequency: 1.0, currentFrequency: $frequency)
                    PresetButton(title: "10 Hz", frequency: 10.0, currentFrequency: $frequency)
                    PresetButton(title: "100 Hz", frequency: 100.0, currentFrequency: $frequency)
                }
            }
            .padding(.horizontal)
            
            // Info display
            HStack {
                VStack(alignment: .leading) {
                    Text("Period: \(String(format: "%.3f s", 1.0 / frequency))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Value: \(String(format: "%.3f", calculateWaveform(phase: phase)))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    func startAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            let deltaPhase = 2 * .pi * frequency * (1.0 / 60.0)
            phase += deltaPhase
            
            // Keep phase in range [0, 2π]
            if phase >= 2 * .pi {
                phase = phase.truncatingRemainder(dividingBy: 2 * .pi)
            }
            
            // Update sample & hold at regular intervals
            if selectedWaveform == .sampleHold {
                let sampleRate = max(frequency / 8, 0.1) // Sample at 1/8 of frequency or 0.1Hz minimum
                let samplePhaseInterval = 2 * .pi * sampleRate * (1.0 / 60.0)
                
                if phase - lastSamplePhase >= samplePhaseInterval || phase < lastSamplePhase {
                    sampleHoldValue = Double.random(in: -1...1)
                    lastSamplePhase = phase
                }
            }
        }
    }
    
    func calculateWaveform(phase: Double) -> Double {
        let normalizedPhase = phase.truncatingRemainder(dividingBy: 2 * .pi)
        let progress = normalizedPhase / (2 * .pi)
        
        switch selectedWaveform {
            case .sine:
                return sin(normalizedPhase)
                
            case .triangle:
                if progress < 0.25 {
                    return progress * 4
                } else if progress < 0.75 {
                    return 1 - (progress - 0.25) * 4
                } else {
                    return -1 + (progress - 0.75) * 4
                }
                
            case .sawtooth:
                return (progress * 2) - 1
                
            case .pulse:
                return progress < 0.5 ? 1.0 : -1.0
                
            case .sampleHold:
                return sampleHoldValue
        }
    }
    
    func midY(geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        let midY = height / 2
        let amplitude = height * 0.4
        let value = calculateWaveform(phase: phase)
        return midY - (value * amplitude)
    }
}


struct PresetButton: View {
    let title: String
    let frequency: Double
    @Binding var currentFrequency: Double
    
    var body: some View {
        Button(action: {
            withAnimation {
                currentFrequency = frequency
            }
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
    }
}


#Preview {
    LFOView()
}
