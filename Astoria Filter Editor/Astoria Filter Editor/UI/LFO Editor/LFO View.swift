//
//  LFOAnimationView 2.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//
import SwiftUI


struct MusicalNote {
    let description: String
    let cents: Double
    let midiNote: Int
}


    /// SwiftUI wrapper for the high-performance CALayer-based LFO view
struct LFOAnimationView: View {
    var lfoSpeed: ProgramParameter
    var lfoShape: ProgramParameter
    var lfoModulationSource: ProgramParameter
    var lfoModulationAmount: ProgramParameter
    @State private var isRunning: Bool = true
    @State private var snapToNote: Bool = false
    
    let minFrequency: Double = 0.008
    let maxFrequency: Double = 261.6
    
    @State var musicNote: MusicalNote = .init(description: "", cents: 0, midiNote: 0)
    
    
    var body: some View {
        GeometryReader { geometry in
            
            HStack {
                GroupBox {
                    VStack {
                        Text("Amount")
                        PercentageArrowView(rawValue: lfoModulationAmount.doubleBinding)
                    }
                    .padding(.horizontal, -20)
                    
                    Text("LFO Mod.")
                        .bold()
                    
                    VStack(spacing: 0) {
                        ArrowPickerGlowView(selection: lfoModulationSource.modulationBinding,
                                            direction: .right,
                                            arrowColor: .green)
                        Text("Source")
                    }
                    .padding(.horizontal, -20)
                }
                .frame(maxWidth: geometry.size.width * (1/5))
                .foregroundStyle(Color.purple.opacity(0.6))

                
                    //            headerView
                
                    // The high-performance CALayer view
                VStack {
                    LFOLayerViewRepresentable(
                        lfoSpeed: lfoSpeed,
                        lfoShape: lfoShape,
                        isRunning: isRunning
                    )
                    .allowsHitTesting(true)
//                    .frame(height: 250)
                    .cornerRadius(12)
                    .contextMenu {
                        ForEach(LFOType.allCases, id: \.self) { waveform in
                            Button(action: {
                                setWaveform(waveform)
                            }) {
                                HStack {
                                    Text(waveform.rawValue)
                                    if selectedWaveform == waveform {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    
                    frequencyControlView
                        //            infoDisplayView
                    
                        //            Spacer()
                }
//                .frame(maxWidth: geometry.size.width * (4/5))
                
                modulationDestinationsView
                    .frame(maxWidth: geometry.size.width * (1/5))
            }
        }
        .padding()
    }
    
        // MARK: - View Components
    
    
    var modulationDestinationsView: some View {
        let destinations = ["Cutoff", "Resonance", "Panning"]
//        let destinations = ["Cutoff", "Resonance", "Panning", "Volume", ]

        return VStack {
            Text("Mod Destinations")
            
            ForEach(destinations, id: \.self) { mod in
                Color
                    .green
                    .cornerRadius(5)
//                    .padding(.horizontal, 5)
                    .overlay {
                        Text(mod)
                    }
            }
            .background(.orange)
            .cornerRadius(10)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var headerView: some View {
        HStack {
            Text("Low Frequency Oscillator")
                .font(.title)
                .bold()
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(isRunning ? "ON" : "OFF")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isRunning ? .green : .gray)
                
                Toggle("", isOn: $isRunning)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
        }
        .padding(.horizontal)
    }
    
    
    private var frequencyControlView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack {
                    Text("Frequency")
                        .font(.headline)
                        //                Spacer()
                    Text(String(format: "%.3f Hz", frequency))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("Period:")
                        .font(.headline)
                    
                    Text("\(String(format: "%.3f s", 1.0 / max(frequency, 0.001)))")
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)

                let musicalNote = frequencyToMusicalNote(frequency)
                VStack {
                    Text("Musical Note:")
                        .font(.headline)
                        //                        .foregroundColor(.gray)
                        //                Spacer()
                    Text(musicalNote.description)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    if abs(musicalNote.cents) < 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity)

                
                GroupBox {
                    VStack {
                        Text("MIDI Note #:")
                            .font(.headline)
                        
                        Text("\(musicalNote.midiNote)")
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            
            HStack {
                snapToNoteToggle
                
                HStack {
                    Text("0.008")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(value: frequencySliderBinding(), in: log10(minFrequency)...log10(maxFrequency))
                    
                    Text("261.6")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }
    
    
    private var snapToNoteToggle: some View {
        Toggle(isOn: Binding(
            get: { snapToNote },
            set: { newValue in
                snapToNote = newValue
                if newValue {
                        // Immediately snap to nearest note when toggled on
                    let snappedFreq = snapFrequencyToNote(frequency)
                    frequency = snappedFreq
                }
            }
        )) {
            HStack(spacing: 4) {
                Text("Snap to Note")
                    .font(.subheadline)
                Image(systemName: "music.note")
                    .font(.caption)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .blue))
    }
    
    
    private var infoDisplayView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Period: \(String(format: "%.3f s", 1.0 / max(frequency, 0.001)))")
                    .font(.caption)
                    .foregroundColor(.gray)
//                Spacer()
            }
            
            let musicalNote = frequencyToMusicalNote(frequency)
            HStack {
                Text("Musical Note:")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(musicalNote.description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cyan)
                if abs(musicalNote.cents) < 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Text("(MIDI: \(musicalNote.midiNote))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
    
        // MARK: - Computed Properties & Helpers
    
    private var frequency: Double {
        get {
            let normalized = Double(lfoSpeed.value) / 127.0
            let logMin = log10(minFrequency)
            let logMax = log10(maxFrequency)
            let logFreq = logMin + normalized * (logMax - logMin)
            return pow(10, logFreq)
        }
        
        nonmutating set {
            let logMin = log10(minFrequency)
            let logMax = log10(maxFrequency)
            let logFreq = log10(newValue)
            let normalized = (logFreq - logMin) / (logMax - logMin)
            let midiValue = UInt8(max(0, min(127, normalized * 127)))
            lfoSpeed.setValue(midiValue)
        }
    }
    
    
    private var selectedWaveform: LFOType {
        if case .lfo(let lfoType) = lfoShape.containedParameter {
            return lfoType
        }
        return .sine
    }
    
    
    private func setWaveform(_ waveform: LFOType) {
        lfoShape.containedParameter = .lfo(waveform)
    }
    
    
    private func waveformBinding() -> Binding<LFOType> {
        Binding(
            get: { selectedWaveform },
            set: { setWaveform($0) }
        )
    }
    
    
    private func frequencySliderBinding() -> Binding<Double> {
        Binding(
            get: { log10(frequency) },
            set: { newValue in
                var newFrequency = pow(10, newValue)
                
                if snapToNote {
                        // Snap to nearest note frequency
                    newFrequency = snapFrequencyToNote(newFrequency)
                }
                
                frequency = newFrequency
            }
        )
    }
    
    
    private func snapFrequencyToNote(_ freq: Double) -> Double {
            // Calculate the nearest MIDI note
        let midiNoteFloat = 12.0 * log2(freq / 440.0) + 69.0
        let midiNote = Int(round(midiNoteFloat))
        
            // Convert back to exact frequency for that note
        let exactFreq = 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
        
        return exactFreq
    }
    
    
    private func frequencyToMusicalNote(_ frequency: Double) -> (description: String, cents: Double, midiNote: Int) {
        print("\(#function)")
        
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let midiNoteFloat = 12.0 * log2(frequency / 440.0) + 69.0
        let midiNote = Int(round(midiNoteFloat))
        let cents = (midiNoteFloat - Double(midiNote)) * 100.0
        let noteIndex = ((midiNote % 12) + 12) % 12
        let octave = Int(floor(Double(midiNote) / 12.0)) - 1
        let noteName = noteNames[noteIndex]
        let centsSign = cents >= 0 ? "+" : ""
        let centsString = String(format: "%@%.0f¢", centsSign, cents)
        return ("\(noteName)\(octave) \(centsString)", cents, midiNote)
    }
}


#Preview {
//    @Previewable @State var lfoSpeed: ProgramParameter = .init(type: .LFOSpeed)
//    @Previewable @State var lfoShape: ProgramParameter = .init(type: .LFOShape)
    @Previewable @State var program: MiniWorksProgram = .init()

    LFOAnimationView(lfoSpeed: program.lfoSpeed,
                     lfoShape: program.lfoShape,
                     lfoModulationSource: program.lfoSpeedModulationSource,
                     lfoModulationAmount: program.lfoSpeedModulationAmount)
        .frame(width: 800, height: 260)
}
