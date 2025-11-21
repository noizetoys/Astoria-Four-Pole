import SwiftUI

struct LFOTracerView: View {
    @State private var phase: Double = 0
    @State private var frequency: Double = 1.0 // Hz
    @State private var selectedWaveform: Waveform = .sine
    @State private var timer: Timer?
    @State private var sampleHoldValue: Double = 0
    @State private var lastSamplePhase: Double = 0
    @State private var sampleHoldValues: [Double] = []
    
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
                
                GeometryReader { geometry in
                    // Grid lines
                    Path { path in
                        // Horizontal center line
                        path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    
                    // Static waveform path
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let midY = height / 2
                        let amplitude = height * 0.4
                        let points = 500
                        
                        for i in 0..<points {
                            let x = (Double(i) / Double(points)) * width
                            let localPhase = (Double(i) / Double(points)) * 2 * .pi
                            let value = calculateWaveform(phase: localPhase)
                            let y = midY - (value * amplitude)
                            
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.green.opacity(0.7), lineWidth: 2)
                    
                    // Tracer dot with glow effect
                    let tracerPosition = getTracerPosition(geometry: geometry)
                    
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    tracerColor.opacity(0.8),
                                    tracerColor.opacity(0.4),
                                    tracerColor.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 30, height: 30)
                        .position(tracerPosition)
                    
                    // Main dot
                    Circle()
                        .fill(tracerColor)
                        .frame(width: 14, height: 14)
                        .position(tracerPosition)
                        .shadow(color: tracerColor.opacity(0.8), radius: 8)
                    
                    // Trail effect (fade behind the dot)
                    ForEach(0..<5, id: \.self) { index in
                        let trailPhase = phase - Double(index + 1) * 0.1
                        if trailPhase >= 0 {
                            let trailPosition = getTracerPosition(geometry: geometry, customPhase: trailPhase)
                            let opacity = 0.3 - (Double(index) * 0.05)
                            
                            Circle()
                                .fill(tracerColor.opacity(opacity))
                                .frame(width: 10 - Double(index) * 1.5, height: 10 - Double(index) * 1.5)
                                .position(trailPosition)
                        }
                    }
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
                .onChange(of: selectedWaveform) { _ in
                    // Reset sample & hold when switching to it
                    if selectedWaveform == .sampleHold {
                        initializeSampleHold()
                    }
                }
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
            initializeSampleHold()
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    var tracerColor: Color {
        // Color changes based on frequency for visual feedback
        let hue = min(log10(frequency / minFrequency) / log10(maxFrequency / minFrequency), 1.0)
        return Color(hue: hue * 0.6, saturation: 0.9, brightness: 1.0) // Red to cyan
    }
    
    func initializeSampleHold() {
        sampleHoldValues = (0..<50).map { _ in Double.random(in: -1...1) }
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
                let sampleRate = max(frequency / 8, 0.1)
                let samplePhaseInterval = 2 * .pi * sampleRate * (1.0 / 60.0)
                
                if phase - lastSamplePhase >= samplePhaseInterval || phase < lastSamplePhase {
                    sampleHoldValue = Double.random(in: -1...1)
                    lastSamplePhase = phase
                    
                    // Update the sample hold values array
                    sampleHoldValues.removeFirst()
                    sampleHoldValues.append(sampleHoldValue)
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
            // Use the pre-calculated sample hold values for smooth display
            let index = Int(progress * Double(sampleHoldValues.count - 1))
            return sampleHoldValues[index]
        }
    }
    
    func getTracerPosition(geometry: GeometryProxy, customPhase: Double? = nil) -> CGPoint {
        let usePhase = customPhase ?? phase
        let width = geometry.size.width
        let height = geometry.size.height
        let midY = height / 2
        let amplitude = height * 0.4
        
        let normalizedPhase = usePhase.truncatingRemainder(dividingBy: 2 * .pi)
        let progress = normalizedPhase / (2 * .pi)
        
        let x = progress * width
        let value = calculateWaveform(phase: normalizedPhase)
        let y = midY - (value * amplitude)
        
        return CGPoint(x: x, y: y)
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
    LFOTracerView()
}
