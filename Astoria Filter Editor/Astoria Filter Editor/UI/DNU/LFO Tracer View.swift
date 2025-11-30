import SwiftUI

/*
 LFOTracerView: A Low Frequency Oscillator Visualizer
 
 WHAT IS AN LFO?
 ===============
 A Low Frequency Oscillator (LFO) is a repeating waveform that cycles at sub-audio frequencies
 (typically below 20 Hz). Unlike audio oscillators that produce sound, LFOs are used to modulate
 (control) other parameters over time, such as filter cutoff, pitch, or volume in synthesizers.
 
 OVERVIEW OF THIS VIEW
 =====================
 This SwiftUI view visualizes an LFO by:
 1. Drawing a static waveform shape across the screen
 2. Animating a colored dot that traces along that waveform
 3. The dot's speed represents the LFO frequency (how many cycles per second)
 4. Optional snap-to-note feature for musical applications
 
 KEY COMPONENTS
 ==============
 - Phase: A value from 0 to 2π (0 to 6.28...) that represents where we are in one complete cycle
 - Frequency: How many complete cycles happen per second (measured in Hz/Hertz)
 - Waveform: The shape of the oscillation (sine, triangle, sawtooth, etc.)
 - Timer: A 60fps timer that updates the phase based on the frequency
 - Snap to Note: When enabled, frequency locks to exact musical note values (0 cents deviation)
 - On/Off Switch: Start/stop the LFO animation (preserves current phase position when stopped)
 
 THE ANIMATION LOOP
 ==================
 Every 1/60th of a second (60 times per second):
 1. Calculate how much the phase should advance: deltaPhase = 2π × frequency × (1/60)
 2. Add that to the current phase: phase += deltaPhase
 3. SwiftUI redraws the view, positioning the dot based on the new phase
 4. The dot appears to move smoothly along the waveform
 
 Example: At 1 Hz (1 cycle per second):
 - deltaPhase = 2π × 1 × (1/60) = 0.1047 radians per frame
 - After 60 frames (1 second), phase advances by 2π (one complete cycle)
 */

struct LFOTracerView: View {
        // MARK: - State Variables
    
        /// The current position in the oscillator's cycle, measured in radians (0 to 2π)
        /// Think of this like a clock hand going around: 0 = start, π = halfway, 2π = back to start
    @State private var phase: Double = 0
    
        /// The LFO speed parameter (0-127 MIDI range maps to 0.008-261.6 Hz)
    var lfoSpeed: ProgramParameter
    
        /// The LFO shape/waveform parameter (ContainedParameter with LFOType)
    var lfoShape: ProgramParameter
    
    
    @State private var musicalNote: MusicalNote = .init(noteName: "", octave: 0, cents: 0, midiNote: 0)
    
        /// The timer that drives the animation at 60 frames per second
    @State private var timer: Timer?
    
        /// For sample & hold: the current random value being held
    @State private var sampleHoldValue: Double = 0
    
        /// For sample & hold: tracks when we last took a new sample
    @State private var lastSamplePhase: Double = 0
    
        /// For sample & hold: pre-generated array of random values for smooth display
    @State private var sampleHoldValues: [Double] = []
    
        /// When true, frequency snaps to exact musical note frequencies (0 cents deviation)
    @State private var snapToNote: Bool = false
    
        /// Controls whether the LFO is running (true) or stopped (false)
    @State private var isRunning: Bool = true
    
        /// The slowest frequency we can display (0.008 Hz = 125 seconds per cycle)
    let minFrequency: Double = 0.008
    
        /// The fastest frequency we can display (261.6 Hz = middle C note)
    let maxFrequency: Double = 261.6
    
        // MARK: - Initialization
    
        /// Creates an LFO Tracer View with the given speed and shape parameters
        /// - Parameters:
        ///   - lfoSpeed: ProgramParameter that stores MIDI value 0-127 mapping to 0.008-261.6 Hz
        ///   - lfoShape: ProgramParameter that stores the LFO waveform type as a ContainedParameter
    init(lfoSpeed: ProgramParameter, lfoShape: ProgramParameter) {
        self.lfoSpeed = lfoSpeed
        self.lfoShape = lfoShape
    }
    
        // MARK: - Computed Properties
    
        /// Converts the MIDI value (0-127) to frequency in Hz (0.008-261.6)
        /// Uses exponential mapping for musical/perceptual spacing
        ///
        /// MIDI TO FREQUENCY MAPPING:
        /// ════════════════════════════════════════════════════════════════════════════
        /// We use a logarithmic (exponential) curve to map MIDI values to frequencies:
        ///
        /// MIDI 0   → 0.008 Hz  (125 second period, extremely slow)
        /// MIDI 32  → 0.046 Hz  (21.7 second period)
        /// MIDI 64  → 0.46 Hz   (2.17 second period, middle of range)
        /// MIDI 96  → 4.6 Hz    (0.217 second period)
        /// MIDI 127 → 261.6 Hz  (0.0038 second period, middle C note)
        ///
        /// Why logarithmic?
        /// - Musical intervals are logarithmic (each octave doubles frequency)
        /// - Human perception of frequency is logarithmic
        /// - Gives good control across the entire range
        /// - More resolution at lower frequencies where LFOs typically operate
//     var frequency: Double {
//        get {
//                // Map 0-127 to 0.008-261.6 Hz using exponential curve
//                // This gives more resolution at lower frequencies
//            let normalized = Double(lfoSpeed.value) / 127.0
//            let logMin = log10(minFrequency)
//            let logMax = log10(maxFrequency)
//            let logFreq = logMin + normalized * (logMax - logMin)
//            return pow(10, logFreq)
//        }
//        set {
//                // Convert frequency back to 0-127 MIDI range
//            let logMin = log10(minFrequency)
//            let logMax = log10(maxFrequency)
//            let logFreq = log10(newValue)
//            let normalized = (logFreq - logMin) / (logMax - logMin)
//            let midiValue = UInt8(max(0, min(127, normalized * 127)))
//            lfoSpeed.setValue(midiValue)
//        }
//    }
    
    
    func setFrequency(to newValue: Double) {
            // Convert frequency back to 0-127 MIDI range
        let logMin = log10(minFrequency)
        let logMax = log10(maxFrequency)
        let logFreq = log10(newValue)
        let normalized = (logFreq - logMin) / (logMax - logMin)
        let midiValue = UInt8(max(0, min(127, normalized * 127)))
        lfoSpeed.setValue(midiValue)
    }
    
    
//    func getDoubleFrequency() -> Double {
    var frequency: Double {
            // Map 0-127 to 0.008-261.6 Hz using exponential curve
            // This gives more resolution at lower frequencies
        let normalized = Double(lfoSpeed.value) / 127.0
        let logMin = log10(minFrequency)
        let logMax = log10(maxFrequency)
        let logFreq = logMin + normalized * (logMax - logMin)
        return pow(10, logFreq)
    }
    
        /// Gets the current LFO waveform type from the lfoShape parameter
    var selectedWaveform: LFOType {
        if case .lfo(let lfoType) = lfoShape.containedParameter {
            return lfoType
        }
        return .sine // Default fallback
    }
    
        /// Sets the waveform by updating the lfoShape parameter
    func setWaveform(_ waveform: LFOType) {
        lfoShape.containedParameter = .lfo(waveform)
    }
    
        // MARK: - Supporting Types
    
        /// Represents a musical note derived from a frequency
        ///
        /// MUSIC THEORY BACKGROUND:
        /// - Western music divides an octave into 12 semitones (half steps)
        /// - Each semitone is further divided into 100 cents
        /// - MIDI notes are numbered 0-127, where 69 = A4 = 440 Hz (concert pitch)
        /// - Each octave doubles the frequency: A5 = 880 Hz, A3 = 220 Hz
    struct MusicalNote {
            /// The note name (C, C♯, D, D♯, E, F, F♯, G, G♯, A, A♯, B)
        let noteName: String
        
            /// The octave number (0 = very low, 4 = middle, 8 = very high)
        let octave: Int
        
            /// How many cents (1/100th of a semitone) away from the exact note
            /// Range: -50 to +50 cents (negative = flat, positive = sharp)
        let cents: Double
        
            /// The MIDI note number (0-127, where middle C = 60, A4 = 69)
        let midiNote: Int
        
            /// Full description including cents deviation (e.g., "C4 +23¢")
        var description: String {
            let centsSign = cents >= 0 ? "+" : ""
            let centsString = String(format: "%@%.0f¢", centsSign, cents)
            return "\(noteName)\(octave) \(centsString)"
        }
        
            /// Short description without cents (e.g., "C4")
        var shortDescription: String {
            return "\(noteName)\(octave)"
        }
    }
    
        // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            waveformDisplayView
//            waveformSelectorView
            frequencyControlView
            infoDisplayView
//            Spacer()
        }
        .padding()
        .onAppear {
            initializeSampleHold()
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: lfoSpeed._value) { oldValue, newValue in
            musicalNote = frequencyToMusicalNote(frequency)
        }
    }
    
        // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Text("Low Frequency Oscillator")
                .font(.title)
                .bold()
            
            Spacer()
            
            onOffSwitch
        }
        .padding(.horizontal)
    }
    
    
    private var onOffSwitch: some View {
        HStack(spacing: 8) {
            Text(isRunning ? "ON" : "OFF")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isRunning ? .green : .gray)
            
            Toggle("", isOn: $isRunning)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .onChange(of: isRunning) { _, newValue in
                    if newValue {
                        phase = 0
                        startAnimation()
                    } else {
                        timer?.invalidate()
                        timer = nil
                    }
                }
        }
    }
    
    
    private var waveformDisplayView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(height: 250)
            
            GeometryReader { geometry in
                waveformContent(geometry: geometry)
            }
        }
        .frame(height: 250)
        .padding(.horizontal)
        .contextMenu {
            waveformContextMenu
        }
    }
    
    
    private var waveformContextMenu: some View {
        ForEach(LFOType.allCases, id: \.self) { waveform in
            Button(action: {
                setWaveform(waveform)
                if waveform == .sampleHold {
                    initializeSampleHold()
                }
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
    
    
    private func waveformContent(geometry: GeometryProxy) -> some View {
        ZStack {
            centerGridLine(geometry: geometry)
            staticWaveformPath(geometry: geometry)
            tracerDotGlow(geometry: geometry)
            tracerDotMain(geometry: geometry)
            tracerTrail(geometry: geometry)
        }
    }
    
    
    private func centerGridLine(geometry: GeometryProxy) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
            path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
        }
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
    
    
    private func staticWaveformPath(geometry: GeometryProxy) -> some View {
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
    }
    
    
    private func tracerDotGlow(geometry: GeometryProxy) -> some View {
        let tracerPosition = getTracerPosition(geometry: geometry)
        
        return Circle()
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
    }
    
    
    private func tracerDotMain(geometry: GeometryProxy) -> some View {
        let tracerPosition = getTracerPosition(geometry: geometry)
        
        return Circle()
            .fill(tracerColor)
            .frame(width: 14, height: 14)
            .position(tracerPosition)
            .shadow(color: tracerColor.opacity(0.8), radius: 8)
    }
    
    
    private func tracerTrail(geometry: GeometryProxy) -> some View {
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
    
    
    private var waveformSelectorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Waveform")
                .font(.headline)
            
            Picker("Waveform", selection: waveformBinding()) {
                ForEach(LFOType.allCases, id: \.self) { waveform in
                    Text(waveform.rawValue).tag(waveform)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
    
    
    private func waveformBinding() -> Binding<LFOType> {
        Binding(
            get: { selectedWaveform },
            set: { newValue in
                setWaveform(newValue)
                if newValue == .sampleHold {
                    initializeSampleHold()
                }
            }
        )
    }
    
    
    private var frequencyControlView: some View {
        VStack(alignment: .leading, spacing: 10) {
            frequencyHeader
            snapToNoteToggle()
            frequencySlider
//            presetButtons
        }
        .padding(.horizontal)
    }
    
    
    private var frequencyHeader: some View {
        HStack {
            Text("Frequency")
                .font(.headline)
            Spacer()
            Text(String(format: "%.3f Hz", frequency))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
        }
    }
    
    
    private func snapToNoteToggle() -> some View {
        Toggle(isOn: $snapToNote) {
            HStack(spacing: 4) {
                Text("Snap to Note")
                    .font(.subheadline)
                Image(systemName: "music.note")
                    .font(.caption)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .blue))
        .onChange(of: snapToNote) { _, newValue in
            if newValue {
                setFrequency(to: snapFrequencyToNote(frequency))
            }
        }
    }
    
    
    private var frequencySlider: some View {
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
    
    
    private func frequencySliderBinding() -> Binding<Double> {
        Binding(
            get: { log10(frequency) },
            set: { newValue in
                let newFrequency = pow(10, newValue)
                let theFrequency = snapToNote ? snapFrequencyToNote(newFrequency) : newFrequency
                setFrequency(to: theFrequency)
            }
        )
    }
    
    
    private func frequencyBinding() -> Binding<Double> {
        Binding(
            get: { frequency },
            set: { setFrequency(to: $0) }
        )
    }
    
    
    private var infoDisplayView: some View {
        VStack(spacing: 8) {
//            periodAndValueDisplay
            musicalNoteDisplay
        }
        .padding(.horizontal)
    }
    
    
    private var periodAndValueDisplay: some View {
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
    }
    
    
    private var musicalNoteDisplay: some View {
        HStack {
            Text("Musical Note:")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            HStack(spacing: 4) {
                Text(musicalNote.description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cyan)
                
                if abs(musicalNote.cents) < 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            Text("(MIDI: \(musicalNote.midiNote))")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
        // MARK: - Color and Styling
    
    var tracerColor: Color {
            // Color changes based on frequency for visual feedback
            // When LFO is stopped, dim the color to show inactive state
        let hue = min(log10(frequency / minFrequency) / log10(maxFrequency / minFrequency), 1.0)
        let baseColor = Color(hue: hue * 0.6, saturation: 0.9, brightness: 1.0) // Red to cyan
//        return isRunning ? baseColor : baseColor.opacity(0.3)
        return isRunning ? baseColor : .clear
    }
    
    func initializeSampleHold() {
        sampleHoldValues = (0..<50).map { _ in Double.random(in: -1...1) }
    }
    
        /// Converts a MIDI note number to its exact frequency in Hz
        /// - Parameter midiNote: The MIDI note number (can be negative for sub-audio frequencies)
        /// - Returns: The frequency in Hz
        ///
        /// MIDI TO FREQUENCY FORMULA:
        /// ════════════════════════════════════════════════════════════════════════════
        /// frequency = 440 × 2^((midiNote - 69) / 12)
        ///
        /// Where:
        /// - 440 Hz is A4 (MIDI note 69)
        /// - Each semitone multiplies frequency by 2^(1/12) ≈ 1.05946
        /// - Each octave (12 semitones) doubles the frequency
        ///
        /// Examples:
        /// - MIDI 69 (A4): 440 × 2^((69-69)/12) = 440 × 2^0 = 440.0 Hz
        /// - MIDI 60 (C4): 440 × 2^((60-69)/12) = 440 × 2^(-0.75) = 261.63 Hz
        /// - MIDI 0 (C-1): 440 × 2^((0-69)/12) = 440 × 2^(-5.75) ≈ 8.18 Hz
        /// - MIDI -82 (D-8): 440 × 2^((-82-69)/12) ≈ 0.0084 Hz
    func midiNoteToFrequency(_ midiNote: Int) -> Double {
        return 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }
    
        /// Snaps a frequency to the nearest exact musical note frequency
        /// - Parameter frequency: The input frequency in Hz
        /// - Returns: The frequency of the nearest musical note (with 0 cents deviation)
    func snapFrequencyToNote(_ frequency: Double) -> Double {
        let musicalNote = frequencyToMusicalNote(frequency)
        return midiNoteToFrequency(musicalNote.midiNote)
    }
    
        /// Converts a frequency in Hz to the nearest musical note
        /// - Parameter frequency: The frequency in Hz (supports 0.008 Hz to 261.6 Hz range)
        /// - Returns: A MusicalNote struct containing note name, octave, cents deviation, and MIDI note number
        ///
        /// HANDLING EXTREME FREQUENCIES:
        /// ════════════════════════════════════════════════════════════════════════════
        /// The standard MIDI range is 0-127, but LFO frequencies can go much lower:
        ///
        /// - 0.008 Hz = MIDI note -82 (C-8, far below human hearing)
        /// - 8.18 Hz = MIDI note 0 (C-1, lowest MIDI note, sub-bass)
        /// - 261.6 Hz = MIDI note 60 (C4, middle C)
        ///
        /// We need to handle negative MIDI notes carefully because:
        /// 1. Modulo with negative numbers behaves differently than expected
        /// 2. Array indexing with negative results crashes
        /// 3. Octave calculation needs adjustment for negative values
    func frequencyToMusicalNote(_ frequency: Double) -> MusicalNote {
        print("\(#function)")
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        
            // A4 = 440 Hz = MIDI note 69
            // Formula: n = 12 × log₂(f / 440) + 69
            //
            // Examples across our range:
            // 0.008 Hz: 12 × log₂(0.008/440) + 69 ≈ -82.4 → MIDI -82
            // 8.18 Hz:  12 × log₂(8.18/440) + 69 ≈ 0.0 → MIDI 0 (C-1)
            // 261.6 Hz: 12 × log₂(261.6/440) + 69 ≈ 60.0 → MIDI 60 (C4)
        let midiNoteFloat = 12.0 * log2(frequency / 440.0) + 69.0
        let midiNote = Int(round(midiNoteFloat))
        
            // Calculate cents deviation (100 cents = 1 semitone)
        let cents = (midiNoteFloat - Double(midiNote)) * 100.0
        
            // SAFE MODULO for negative numbers
            // ════════════════════════════════════════════════════════════════════════
            // Swift's % operator can return negative values:
            //   -82 % 12 = -10 (WRONG for array indexing!)
            //
            // We need the mathematical modulo that always returns 0-11:
            //   -82 mod 12 = 2 (which is D, correct!)
            //
            // Formula: ((value % divisor) + divisor) % divisor
            // This wraps negative values to positive range
        let noteIndex = ((midiNote % 12) + 12) % 12
        
            // OCTAVE CALCULATION for negative MIDI notes
            // ════════════════════════════════════════════════════════════════════════
            // Standard formula (midiNote / 12) - 1 works for positive numbers:
            //   MIDI 60: (60 / 12) - 1 = 5 - 1 = 4 (C4) ✓
            //
            // But fails for negative numbers due to integer division rounding toward zero:
            //   MIDI -82: (-82 / 12) - 1 = -6 - 1 = -7 (WRONG!)
            //   Should be: -8 (C-8)
            //
            // Fix: Use floor division for consistent behavior
        let octave = Int(floor(Double(midiNote) / 12.0)) - 1
        
        let noteName = noteNames[noteIndex]
        
        return MusicalNote(
            noteName: noteName,
            octave: octave,
            cents: cents,
            midiNote: midiNote
        )
    }
    
    func startAnimation() {
            // Clean up any existing timer before creating a new one
        timer?.invalidate()
        
            // CREATE A 60 FPS ANIMATION TIMER
            // ═══════════════════════════════════════════════════════════════════════
            // Timer.scheduledTimer creates a repeating timer that calls our closure
            // every 1/60th of a second (approximately 16.67 milliseconds)
            //
            // This gives us smooth 60 FPS animation that matches typical display refresh rates
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            
                // ONLY ADVANCE PHASE WHEN LFO IS RUNNING
                // ═══════════════════════════════════════════════════════════════════
                // When isRunning is false, the timer still fires but we skip the
                // phase advancement. This keeps the dot frozen at its current position
                // while maintaining the timer for instant resume capability.
            guard isRunning else { return }
            
                // CALCULATE PHASE ADVANCEMENT
                // ═══════════════════════════════════════════════════════════════════
                // We need to figure out: "How much should the phase increase this frame?"
                //
                // The formula: deltaPhase = 2π × frequency × (1/60)
                //
                // Breaking it down:
                // - frequency = cycles per second (Hz)
                // - (1/60) = time per frame in seconds
                // - 2π = radians per complete cycle
                //
                // Example at 1 Hz:
                //   deltaPhase = 2π × 1 × (1/60)
                //   deltaPhase = 2π / 60
                //   deltaPhase ≈ 0.1047 radians per frame
                //
                //   After 60 frames (1 second):
                //   total advance = 0.1047 × 60 ≈ 2π radians (one complete cycle!)
                //
                // Example at 10 Hz:
                //   deltaPhase = 2π × 10 × (1/60) ≈ 1.047 radians per frame
                //   After 60 frames: 1.047 × 60 ≈ 20π radians (10 complete cycles!)
            let deltaPhase = 2 * .pi * frequency * (1.0 / 60.0)
            
                // Add the advancement to our current phase
            phase += deltaPhase
            
                // KEEP PHASE IN VALID RANGE [0, 2π]
                // ═══════════════════════════════════════════════════════════════════
                // After many frames, phase could become very large (hundreds of radians)
                // We use modulo (remainder) to wrap it back to 0-2π range
                //
                // Example:
                // - phase = 7.5 radians (more than one cycle)
                // - 7.5 % 2π = 7.5 - 2π = 1.22 radians (wrapped back)
                //
                // This keeps our calculations efficient and prevents floating point
                // precision issues with very large numbers
            if phase >= 2 * .pi {
                phase = phase.truncatingRemainder(dividingBy: 2 * .pi)
            }
            
                // SAMPLE & HOLD SPECIAL BEHAVIOR
                // ═══════════════════════════════════════════════════════════════════
                // For the sample & hold waveform, we need to periodically grab new
                // random values to create the "stepped" random effect
            if selectedWaveform == .sampleHold {
                    // Sample at 1/8 the LFO frequency (or at least 0.1 Hz)
                    // This means 8 random steps per LFO cycle
                let sampleRate = max(frequency / 8, 0.1)
                let samplePhaseInterval = 2 * .pi * sampleRate * (1.0 / 60.0)
                
                    // Check if enough phase has passed since last sample
                    // OR if phase wrapped around (phase < lastSamplePhase means we crossed 2π)
                if phase - lastSamplePhase >= samplePhaseInterval || phase < lastSamplePhase {
                        // Generate a new random value between -1 and +1
                    sampleHoldValue = Double.random(in: -1...1)
                    lastSamplePhase = phase
                    
                        // Update the sample hold values array
                    sampleHoldValues.removeFirst()  // Remove oldest
                    sampleHoldValues.append(sampleHoldValue)  // Add newest
                }
            }
        }
            // NOTE: When @State variable 'phase' changes, SwiftUI automatically
            // triggers a redraw of the view, which repositions the tracer dot
    }
    
    
        // MARK: - Waveform Calculation
    
        /// Calculates the output value (-1 to +1) for a given phase in the oscillator cycle
        ///
        /// UNDERSTANDING PHASE:
        /// Phase is measured in radians from 0 to 2π (approximately 0 to 6.28)
        /// - 0 radians = 0° = start of cycle
        /// - π/2 radians = 90° = quarter way through
        /// - π radians = 180° = halfway through
        /// - 3π/2 radians = 270° = three-quarters through
        /// - 2π radians = 360° = back to start
        ///
        /// We convert phase to "progress" (0.0 to 1.0) to make the math easier:
        /// progress = phase / (2π)
        ///
        /// - Parameter phase: The current position in the cycle (0 to 2π radians)
        /// - Returns: The waveform's value at this phase, normalized from -1 to +1
    func calculateWaveform(phase: Double) -> Double {
            // Ensure phase is within 0 to 2π range using modulo arithmetic
        let normalizedPhase = phase.truncatingRemainder(dividingBy: 2 * .pi)
        
            // Convert phase (0 to 2π) into progress (0.0 to 1.0) for easier calculations
        let progress = normalizedPhase / (2 * .pi)
        
        switch selectedWaveform {
            case .sine:
                    // SINE WAVE: Smooth, natural oscillation
                    // Uses the trigonometric sine function
                    // At 0°: sin(0) = 0
                    // At 90°: sin(π/2) = 1 (peak)
                    // At 180°: sin(π) = 0
                    // At 270°: sin(3π/2) = -1 (trough)
                    // At 360°: sin(2π) = 0 (back to start)
                return sin(normalizedPhase)
                
            case .triangle:
                    // TRIANGLE WAVE: Linear ramps up and down
                    // Divided into 4 segments:
                    //
                    // Segment 1 (0% to 25%): Rising from 0 to +1
                    //   Formula: progress × 4
                    //   Example: at 12.5% progress: 0.125 × 4 = 0.5
                    //
                    // Segment 2 (25% to 75%): Falling from +1 to -1
                    //   Formula: 1 - (progress - 0.25) × 4
                    //   Example: at 50% progress: 1 - (0.5 - 0.25) × 4 = 0
                    //
                    // Segment 3 (75% to 100%): Rising from -1 to 0
                    //   Formula: -1 + (progress - 0.75) × 4
                    //   Example: at 87.5% progress: -1 + (0.875 - 0.75) × 4 = -0.5
                if progress < 0.25 {
                    return progress * 4
                } else if progress < 0.75 {
                    return 1 - (progress - 0.25) * 4
                } else {
                    return -1 + (progress - 0.75) * 4
                }
                
            case .sawtooth:
                    // SAWTOOTH WAVE: Linear ramp from -1 to +1, then instant drop
                    // Formula: (progress × 2) - 1
                    //
                    // At 0% progress: (0 × 2) - 1 = -1
                    // At 50% progress: (0.5 × 2) - 1 = 0
                    // At 100% progress: (1.0 × 2) - 1 = 1
                    // Then instantly jumps back to -1 to start the next cycle
                return (progress * 2) - 1
                
            case .pulse:
                    // PULSE/SQUARE WAVE: Alternates between +1 and -1
                    // 50% duty cycle: equal time high and low
                    //
                    // First half (0% to 50%): Output = +1
                    // Second half (50% to 100%): Output = -1
                    //
                    // Creates a "square" shape when graphed
                return progress < 0.5 ? 1.0 : -1.0
                
            case .sampleHold:
                    // SAMPLE & HOLD: Random stepped values
                    // Stays at a random value, then jumps to a new random value periodically
                    //
                    // We use a pre-generated array of random values and index into it
                    // based on the current progress through the cycle
                    //
                    // Calculate which index in the array we should use:
                    // - progress ranges from 0.0 to 1.0
                    // - multiply by (array count - 1) to get an index
                    // - convert to Int to get a valid array index
                let index = Int(progress * Double(sampleHoldValues.count - 1))
                return sampleHoldValues[index]
        }
    }
    
    
        // MARK: - Drawing Functions
    
        /// Calculates the screen position (x, y coordinates) for the tracer dot
        ///
        /// SWIFTUI COORDINATE SYSTEM:
        /// - Origin (0, 0) is at the TOP-LEFT corner
        /// - X increases going RIGHT
        /// - Y increases going DOWN (opposite of typical math graphs!)
        ///
        /// OUR WAVEFORM DISPLAY:
        /// - Width: The full width of the geometry (left to right)
        /// - Height: The full height of the geometry
        /// - Middle: height / 2 (the horizontal center line)
        /// - Amplitude: How far up/down the wave goes (40% of height)
        ///
        /// COORDINATE CALCULATION:
        /// 1. X position: Based on progress through the cycle (0 to 1)
        ///    x = progress × width
        ///    At start (0%): x = 0 (left edge)
        ///    At middle (50%): x = width/2 (center)
        ///    At end (100%): x = width (right edge)
        ///
        /// 2. Y position: Based on waveform value (-1 to +1)
        ///    y = midY - (value × amplitude)
        ///    We SUBTRACT because Y increases downward in SwiftUI
        ///    At value +1: y = midY - amplitude (top of wave)
        ///    At value 0: y = midY (center line)
        ///    At value -1: y = midY + amplitude (bottom of wave)
        ///
        /// - Parameters:
        ///   - geometry: The GeometryProxy providing the view's dimensions
        ///   - customPhase: Optional phase override (used for drawing trailing dots)
        /// - Returns: A CGPoint with the (x, y) screen coordinates
    func getTracerPosition(geometry: GeometryProxy, customPhase: Double? = nil) -> CGPoint {
        let usePhase = customPhase ?? phase
        let width = geometry.size.width
        let height = geometry.size.height
        let midY = height / 2  // The horizontal center line
        let amplitude = height * 0.4  // Wave goes 40% of height above/below center
        
            // Ensure phase is in the 0 to 2π range
        let normalizedPhase = usePhase.truncatingRemainder(dividingBy: 2 * .pi)
        
            // Convert phase to progress (0.0 to 1.0)
        let progress = normalizedPhase / (2 * .pi)
        
            // Calculate X position: progress maps to horizontal position
        let x = progress * width
        
            // Get the waveform value at this phase (-1 to +1)
        let value = calculateWaveform(phase: normalizedPhase)
        
            // Calculate Y position: value maps to vertical position
            // Subtract because SwiftUI's Y axis increases downward
        let y = midY - (value * amplitude)
        
        return CGPoint(x: x, y: y)
    }
}


#Preview {
        // Create sample parameters for preview
        // Note: In actual use, these would come from a MiniWorksProgram instance
    let speedParam = ProgramParameter(type: .LFOSpeed, initialValue: 64)
    let shapeParam = ProgramParameter(type: .LFOShape, initialValue: 0)
    
    return LFOTracerView(lfoSpeed: speedParam, lfoShape: shapeParam)
}
