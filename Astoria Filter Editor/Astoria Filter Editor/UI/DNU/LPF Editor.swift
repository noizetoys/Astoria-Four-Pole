import SwiftUI

/*
 LOW PASS FILTER EDITOR
 
 This SwiftUI component creates a professional audio filter editor with visual frequency response display.
 
 KEY CONCEPTS:
 - Filter parameters use MIDI-style 0-127 range
 - Frequency is logarithmically mapped from 20Hz to 20kHz
 - 24dB/octave slope = 4th order filter (two cascaded 2nd order biquad sections)
 - Resonance creates a peak at the cutoff frequency
 - Modulation allows external sources to dynamically change parameters
 
 CUSTOMIZATION GUIDE:
 See inline comments marked with "CUSTOMIZATION:" for easy adjustment points.
 */

// MARK: - Models

struct ModSource: Identifiable, Hashable {
    let id: Int
    let name: String
}

// MARK: - Main View

struct LowPassFilterEditor: View {
    // Filter parameters (0-127 MIDI-style range)
    // CUSTOMIZATION: Change initial values here
    @State private var frequency: Double = 64      // 0 = 20Hz, 127 = 20kHz
    @State private var resonance: Double = 0       // 0 = no resonance, 127 = max resonance
    
    // Modulation sources
    @State private var frequencyModSource: ModSource = ModSource(id: 0, name: "Off")
    @State private var resonanceModSource: ModSource = ModSource(id: 0, name: "Off")
    
    // Modulation amounts (0-127 mapped to -64 to +63, where 64 = 0%)
    // CUSTOMIZATION: 64 = neutral (0%), 0 = -100%, 127 = +100%
    @State private var frequencyModAmount: Double = 64  // No modulation at start
    @State private var resonanceModAmount: Double = 64  // No modulation at start
    
    // CUSTOMIZATION: Add or modify modulation sources here
    // First entry (id: 0, name: "Off") should always remain as the "no modulation" option
    let modulationSources = [
        ModSource(id: 0, name: "Off"),        // No modulation
        ModSource(id: 1, name: "LFO 1"),      // Low Frequency Oscillator 1
        ModSource(id: 2, name: "LFO 2"),      // Low Frequency Oscillator 2
        ModSource(id: 3, name: "Envelope 1"), // Envelope Generator 1
        ModSource(id: 4, name: "Envelope 2"), // Envelope Generator 2
        ModSource(id: 5, name: "Mod Wheel"),  // MIDI Mod Wheel
        ModSource(id: 6, name: "Aftertouch"), // MIDI Aftertouch
        ModSource(id: 7, name: "Velocity"),   // Note Velocity
        ModSource(id: 8, name: "Key Track"),  // Keyboard tracking
        ModSource(id: 9, name: "Random"),     // Random modulation
        ModSource(id: 10, name: "Sample & Hold"),
        ModSource(id: 11, name: "Sequencer"),
        ModSource(id: 12, name: "Macro 1"),
        ModSource(id: 13, name: "Macro 2"),
        ModSource(id: 14, name: "Macro 3"),
        ModSource(id: 15, name: "Macro 4")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // CUSTOMIZATION: Change title text or styling here
            Text("Low Pass Filter Editor")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            // Filter Visualization
            // CUSTOMIZATION: Adjust .frame(height:) to change graph size
            FilterResponseView(
                frequency: frequency,
                resonance: resonance,
                frequencyModSource: frequencyModSource,
                frequencyModAmount: frequencyModAmount,
                resonanceModSource: resonanceModSource,
                resonanceModAmount: resonanceModAmount
            )
            .frame(height: 300)  // CUSTOMIZATION: Graph height in points
            .background(Color.black)  // CUSTOMIZATION: Graph background color
            .cornerRadius(10)  // CUSTOMIZATION: Corner rounding
            .padding(.horizontal)
            
            // Frequency Controls
            GroupBox(label: Text("Cutoff Frequency").font(.headline)) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Mod Source:")
                            .font(.caption)
                            .frame(width: 90, alignment: .leading)
                        Picker("", selection: $frequencyModSource) {
                            ForEach(modulationSources) { source in
                                Text(source.name).tag(source)
                            }
                        }
                        Spacer()
                    }
                    
                    if frequencyModSource.id != 0 {
                        HStack {
                            Text("Mod Amount:")
                                .font(.caption)
                                .frame(width: 90, alignment: .leading)
                            Slider(value: $frequencyModAmount, in: 0...127, step: 1)
                                .accentColor(.orange)
                            Text("\(modAmountToPercentage(frequencyModAmount), specifier: "%.0f")%")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .frame(width: 50)
                            Text("[\(Int(frequencyModAmount))]")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 40)
                        }
                    }
                    
                    HStack {
                        Text("Cutoff:")
                            .font(.caption)
                            .frame(width: 90, alignment: .leading)
                        Slider(value: $frequency, in: 0...127, step: 1)
                            .accentColor(.blue)
                        Text("\(frequencyToHz(frequency), specifier: "%.0f") Hz")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(width: 70)
                        Text("[\(Int(frequency))]")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 40)
                    }
                }
                .padding(.vertical, 5)
            }
            .padding(.horizontal)
            
            // Resonance Controls
            GroupBox(label: HStack {
                Text("Resonance").font(.headline)
                if resonance >= 80 {
                    Text("⚠ Self-Oscillation")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Mod Source:")
                            .font(.caption)
                            .frame(width: 90, alignment: .leading)
                        Picker("", selection: $resonanceModSource) {
                            ForEach(modulationSources) { source in
                                Text(source.name).tag(source)
                            }
                        }
                        Spacer()
                    }
                    
                    if resonanceModSource.id != 0 {
                        VStack(spacing: 5) {
                            HStack {
                                Text("Mod Amount:")
                                    .font(.caption)
                                    .frame(width: 90, alignment: .leading)
                                Slider(value: $resonanceModAmount, in: 0...127, step: 1)
                                    .accentColor(.orange)
                                Text("\(modAmountToPercentage(resonanceModAmount), specifier: "%.0f")%")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .frame(width: 50)
                                Text("[\(Int(resonanceModAmount))]")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(width: 40)
                            }
                            Text("(+) In Phase | (-) Out of Phase")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("Resonance:")
                            .font(.caption)
                            .frame(width: 90, alignment: .leading)
                        Slider(value: $resonance, in: 0...127, step: 1)
                            .accentColor(resonance >= 80 ? .red : .green)
                        Text("  ")
                            .frame(width: 70)
                        Text("[\(Int(resonance))]")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 40)
                    }
                }
                .padding(.vertical, 5)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    /*
     FREQUENCY CONVERSION: 0-127 to 20Hz-20kHz
     
     WHY LOGARITHMIC?
     - Human hearing perceives frequency logarithmically
     - Musical octaves are logarithmic (each octave doubles the frequency)
     - This provides more resolution in the bass range where it's needed
     
     MATH EXPLANATION:
     1. Convert 20Hz and 20kHz to log10 values
     2. Normalize input (0-127) to range 0.0-1.0
     3. Interpolate in log space
     4. Convert back to linear frequency with pow(10, x)
     
     CUSTOMIZATION:
     - Change minFreq/maxFreq to adjust frequency range
     - Currently: 20Hz to 20kHz (full audio spectrum)
     */
    private func frequencyToHz(_ value: Double) -> Double {
        let minFreq = log10(20.0)      // CUSTOMIZATION: Minimum frequency (log)
        let maxFreq = log10(20000.0)   // CUSTOMIZATION: Maximum frequency (log)
        let normalized = value / 127.0  // Normalize to 0.0-1.0
        let logFreq = minFreq + normalized * (maxFreq - minFreq)
        return pow(10, logFreq)  // Convert back from log to linear
    }
    
    /*
     MODULATION AMOUNT CONVERSION
     
     Maps 0-127 to -100% to +100%
     - 0 = -100% (full negative)
     - 64 = 0% (neutral, no modulation)
     - 127 = +100% (full positive)
     
     CUSTOMIZATION: Adjust 63.5 to change the scaling
     */
    private func modAmountToPercentage(_ value: Double) -> Double {
        return ((value - 64) / 63.5) * 100
    }
}

// MARK: - Filter Response Visualization

/*
 FILTER RESPONSE VIEW
 
 This view renders the frequency response curve of a 24dB/octave low-pass filter.
 It also displays modulation arrows when modulation sources are active.
 
 VISUAL ELEMENTS:
 1. Frequency grid (logarithmic scale from 20Hz to 20kHz)
 2. Filter response curve (blue normally, red at self-oscillation)
 3. Frequency modulation arrow (horizontal, left side)
 4. Resonance modulation arrow (vertical, right of peak)
 */
/*
 UPDATED LOW PASS FILTER EDITOR – SHARPER RESPONSE LINE
 
 This version incorporates the sharper, more defined filter slope requested.
 All documentation from the prior version has been preserved and expanded.
 
 ===============================================================
 WHY THE FILTER LINE IS SHARPER NOW
 ===============================================================
 1. **Increased Sampling Resolution (500 → 1200 points)**
 - More points along the curve means the rendered line is smoother and more precise.
 - Reduces visual aliasing and makes the slope appear more realistic.
 
 2. **Stronger Visual Attenuation Mapping (160 → 90 divisor)**
 - The visual mapping compresses dB attenuation into fewer vertical pixels.
 - This makes the slope appear steeper and more "analog synth"-like.
 
 3. **Baseline Adjustment (0.50 → 0.45 of height)**
 - Moves the passband up slightly, giving more room for a dramatic curve.
 - Resonance peak stands out more clearly.
 
 4. **Curve Styling Enhancements**
 - Thicker stroke width: 2.5 → 3.0
 - Added white highlight shadow for definition
 
 ===============================================================
 ABOUT THE LOW-PASS RESPONSE MODEL (24dB/oct)
 ===============================================================
 • This view displays the frequency response of a *4th-order low‑pass filter*.
 • Implemented as two stacked biquad models.
 • Resonance is implemented by modifying Q values of each stage.
 • The response equation remains identical to the previous version.
 
 ===============================================================
 VISUALIZATION VS. TRUE AUDIO FILTERING
 ===============================================================
 The graph **does not directly compute audio**, but simulates the mathematical
 frequency response. The visual sharpness does not alter the underlying math.
 
 What changed:
 ✓ Visual mapping of dB → pixels (faster visual slope)
 ✓ Sampling resolution
 ✓ Screen placement of the line
 
 What did NOT change:
 • Actual dB computations for low‑pass response
 • Resonance-to-Q model
 • Cutoff frequency conversion logic
 
 ===============================================================
 CUSTOMIZATION NOTES (same as before, extended)
 ===============================================================
 - To make the peak *taller*: reduce maxExpectedPeak (e.g., 14 → 10).
 - To make the slope *even steeper visually*: reduce attenuation divisor further (e.g., 80 or 70).
 - To make the filter curve match real 36dB or 48dB/oct filters:
 → Add additional biquad sections in lowPassResponse24dB().
 - To make the curve more analog‑like:
 → Introduce slight asymmetry or overshoot shaping.
 
 ===============================================================
 END OF HEADER DOCUMENTATION
 ===============================================================
 */
struct FilterResponseView: View {
    let frequency: Double
    let resonance: Double
    let frequencyModSource: ModSource
    let frequencyModAmount: Double
    let resonanceModSource: ModSource
    let resonanceModAmount: Double
    

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                filterVisualization(geometry: geometry)
                
                if frequencyModSource.id != 0 && abs((frequencyModAmount - 64) / 63.5) > 0.01 {
                    frequencyModArrow(geometry: geometry)
                }
                if resonanceModSource.id != 0 && abs((resonanceModAmount - 64) / 63.5) > 0.01 {
                    resonanceModArrow(geometry: geometry)
                }
            }
        }
    }

    private func filterVisualization(geometry: GeometryProxy) -> some View {
        ZStack {
            frequencyScaleView(geometry: geometry)
            filterCurvePath(geometry: geometry)
                .stroke(resonance >= 80 ? Color.red : Color.blue, lineWidth: 3.0)
                .shadow(color: .white.opacity(0.5), radius: 1.2)
        }
    }
    

    private func frequencyModArrow(geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let percentage = ((frequencyModAmount - 64) / 63.5) * 100
        
        // Position arrow on the LEFT side of the graph area, away from resonance peak
        let xPos = width * 0.15 // Position at 15% from left
        let yPos = height * 0.12
        
        let isPositive = percentage > 0
        let absPercentage = abs(percentage)
        
        return HStack(spacing: 6) {
            if !isPositive {
                Image(systemName: "arrow.left.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 28))
            }
            
            Text("\(absPercentage, specifier: "%.0f")%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isPositive ? .green : .red)
            
            if isPositive {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 28))
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isPositive ? Color.green : Color.red, lineWidth: 2)
        )
        .position(x: xPos, y: yPos)
    }
    
    private func resonanceModArrow(geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height - 30
        let percentage = ((resonanceModAmount - 64) / 63.5) * 100
        
        // Position arrow to the RIGHT of the resonance peak
        let cutoffFreq = frequencyToHz(frequency)
        let cutoffXPos = frequencyToXPosition(cutoffFreq, width: width)
        
        // Position significantly to the right of the cutoff frequency
        let xPos = min(width - 60, cutoffXPos + 80)
        
        // Calculate peak height
        let Q = resonanceToQ(resonance)
        let peakResponse = lowPassResponse24dB(freq: cutoffFreq, cutoff: cutoffFreq, Q: Q)
        let baselineY = height * 0.5
        let topMargin: CGFloat = 30
        
        let y: CGFloat
        if peakResponse > 0 {
            let availableHeightAbove = baselineY - topMargin
            let maxExpectedPeak = 24.0
            let normalizedPeak = min(1.0, peakResponse / maxExpectedPeak)
            y = baselineY - (normalizedPeak * availableHeightAbove)
        } else {
            y = baselineY
        }
        
        let isPositive = percentage >= 0
        let absPercentage = abs(percentage)
        
        return VStack(spacing: 4) {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(isPositive ? .green : .red)
                .font(.system(size: 28))
            
            Text("\(absPercentage, specifier: "%.0f")%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isPositive ? .green : .red)
            
            Text(isPositive ? "In" : "Out")
                .font(.system(size: 10))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isPositive ? Color.green : Color.red, lineWidth: 2)
        )
        .position(x: xPos, y: y)
    }
    
    /*
     FREQUENCY SCALE AND GRID
     
     Draws the logarithmic frequency grid with major and minor gridlines and labels.
     
     CUSTOMIZATION OPTIONS:
     - majorFreqs: Main frequencies with labels (currently standard audio divisions)
     - minorFreqs: Secondary gridlines for finer detail
     - Grid line opacity: 0.15 for minor, 0.4 for major
     - Grid line width: 0.5 for minor, 1.0 for major
     - Label sizes: 9pt (top), 11pt (bottom)
     - Y positions: 25 (top margin), height-40 (bottom margin)
     */
    private func frequencyScaleView(geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        
        // CUSTOMIZATION: Add/remove frequencies to change grid density
        let majorFreqs = [20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000]
        let minorFreqs = [30, 40, 60, 70, 80, 90, 150, 300, 400, 600, 700, 800, 900,
                          1500, 3000, 4000, 6000, 7000, 8000, 9000, 15000]
        
        return ZStack(alignment: .bottom) {
            // Minor grid lines (thinner, more transparent)
            // CUSTOMIZATION: Adjust opacity and lineWidth below
            ForEach(minorFreqs, id: \.self) { freq in
                let xPos = frequencyToXPosition(Double(freq), width: width)
                
                Path { path in
                    path.move(to: CGPoint(x: xPos, y: 25))
                    path.addLine(to: CGPoint(x: xPos, y: height - 40))
                }
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)  // CUSTOMIZATION: Grid style
            }
            
            // Major grid lines
            // CUSTOMIZATION: Adjust opacity and lineWidth below
            ForEach(majorFreqs, id: \.self) { freq in
                let xPos = frequencyToXPosition(Double(freq), width: width)
                
                Path { path in
                    path.move(to: CGPoint(x: xPos, y: 25))
                    path.addLine(to: CGPoint(x: xPos, y: height - 40))
                }
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)  // CUSTOMIZATION: Grid style
            }
            
            // Top frequency labels
            // CUSTOMIZATION: Adjust font size and color
            ForEach(majorFreqs, id: \.self) { freq in
                let xPos = frequencyToXPosition(Double(freq), width: width)
                
                Text(formatFrequency(freq))
                    .font(.system(size: 9))  // CUSTOMIZATION: Label size
                    .foregroundColor(.white.opacity(0.7))  // CUSTOMIZATION: Label color
                    .position(x: xPos, y: 12)  // CUSTOMIZATION: Vertical position
            }
            
            // Bottom frequency labels (larger)
            // CUSTOMIZATION: Adjust font size and color
            ForEach(majorFreqs, id: \.self) { freq in
                let xPos = frequencyToXPosition(Double(freq), width: width)
                
                Text(formatFrequency(freq))
                    .font(.system(size: 11, weight: .medium))  // CUSTOMIZATION: Label size
                    .foregroundColor(.white)  // CUSTOMIZATION: Label color
                    .position(x: xPos, y: height - 12)  // CUSTOMIZATION: Vertical position
            }
        }
    }
    
    /*
     FILTER CURVE PATH - DRAWING THE FILTER RESPONSE
     
     This function draws the actual low-pass filter frequency response curve.
     
     HOW IT WORKS:
     1. Sample the frequency spectrum from 20Hz to 20kHz at 500 points
     2. Calculate the filter response in dB at each frequency
     3. Convert dB values to vertical pixel positions
     4. Connect the points to form a smooth curve
     5. Stop drawing when the curve reaches the bottom
     
     VISUAL LAYOUT:
     - Baseline (0dB): At 50% of height - this is where the passband sits
     - Top margin: 30 pixels - prevents resonance peak from being cut off
     - Bottom threshold: height - 35 pixels - where the line stops
     
     CUSTOMIZATION - SLOPE LENGTH:
     The slope steepness is controlled by:
     1. normalizedAttenuation calculation (line ~506)
     - Currently: abs(response) / 160.0
     - DECREASE denominator (e.g., 120.0) to make slope SHORTER/STEEPER visually
     - INCREASE denominator (e.g., 200.0) to make slope LONGER/GENTLER visually
     
     2. The actual 24dB/octave slope is in lowPassResponse24dB() function
     - That controls the TRUE mathematical slope
     - This function just visualizes it
     
     CUSTOMIZATION - GRAPH HEIGHT:
     - baselineY = height * 0.5 (currently 50%)
     - DECREASE (e.g., 0.4) to move baseline DOWN, more room for resonance peak
     - INCREASE (e.g., 0.6) to move baseline UP, more room for slope
     
     - topMargin (currently 30 pixels)
     - Controls space above resonance peak
     */
    private func filterCurvePath(geometry: GeometryProxy) -> Path {
        let width = geometry.size.width
        let height = geometry.size.height - 30
        
        var path = Path()
        
        let cutoffFreq = frequencyToHz(frequency)
        let Q = resonanceToQ(resonance)
        
        // Increased precision → sharper rendering
        let numPoints = 1200
        
        // Move baseline slightly up to exaggerate steepness
        let baselineY = height * 0.45
        let topMargin: CGFloat = 25
        let bottomThreshold = height - 30
        
        for i in 0..<numPoints {
            let x = CGFloat(i) / CGFloat(numPoints - 1) * width
            let freq = xPositionToFrequency(x, width: width)
            
            let response = lowPassResponse24dB(freq: freq, cutoff: cutoffFreq, Q: Q)
            
            let y: CGFloat
            if response > 0 {
                // resonant peak smoothing
                let availableHeightAbove = baselineY - topMargin
                let normalizedPeak = min(1.0, response / 14.0)
                y = baselineY - normalizedPeak * availableHeightAbove
            } else {
                // VISUAL SLOPE STEEPNESS CONTROL — sharper line
                let availableHeightBelow = bottomThreshold - baselineY
                let normalizedAttenuation = min(1.0, abs(response) / 90.0) // <— decreased from 160 → 90 (much sharper)
                y = baselineY + normalizedAttenuation * availableHeightBelow
            }
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
    

    // Convert 0-127 to 20Hz-20kHz (logarithmic)
    private func frequencyToHz(_ value: Double) -> Double {
        let minFreq = log10(20.0)
        let maxFreq = log10(20000.0)
        let normalized = value / 127.0
        let logFreq = minFreq + normalized * (maxFreq - minFreq)
        return pow(10, logFreq)
    }

    /*
     RESONANCE TO Q FACTOR CONVERSION
     
     Q (Quality factor) controls the sharpness of the resonance peak.
     - Low Q (0.707): Flat response, no peak (Butterworth response)
     - High Q (3.707): Sharp resonance peak at cutoff frequency
     
     CUSTOMIZATION:
     - Maximum Q value: Currently 3.0 (producing range 0.707 to 3.707)
     - INCREASE for sharper resonance peaks (e.g., 5.0 or 10.0)
     - DECREASE for gentler peaks (e.g., 1.0 or 2.0)
     - Power factor: Currently 1.2
     - INCREASE for more aggressive curve (peaks appear faster as resonance increases)
     - DECREASE for more linear response
     */
    private func resonanceToQ(_ value: Double) -> Double {
        if value < 1 { return 0.707 }
        let normalized = value / 127.0
        return 0.707 + pow(normalized, 1.2) * 3.0
    }

    /*
     24dB/OCTAVE LOW-PASS FILTER RESPONSE
     
     This calculates the frequency response of a 4th order low-pass filter.
     
     WHAT IS 24dB/OCTAVE?
     - Every time frequency doubles (one octave), amplitude decreases by 24dB
     - This is a 4th order filter (two cascaded 2nd order sections)
     - Very steep cutoff, good for sound synthesis
     
     MATH EXPLANATION:
     1. Calculate frequency ratio (input freq / cutoff freq)
     2. Apply biquad formula twice (4th order = two 2nd order stages)
     3. Each biquad: magnitude = 1 / sqrt((1-s²)² + (s/Q)²)
     4. Multiply both stages together
     5. Convert to dB: 20 * log10(magnitude)
     
     Q FACTOR SETUP:
     - butterQ1/butterQ2: Standard Butterworth Q values for flat passband
     - User Q is added on top for resonance peak
     
     CUSTOMIZATION - SLOPE STEEPNESS:
     To make the mathematical slope steeper (not just visual):
     - Increase the order (use 3 biquad sections for 6th order = 36dB/octave)
     - Adjust Q multipliers (currently 1.5 and 1.0) - higher = steeper
     
     NOTE: This function calculates the TRUE filter response.
     The visual slope length is controlled in filterCurvePath() function.
     */
    private func lowPassResponse24dB(freq: Double, cutoff: Double, Q: Double) -> Double {
        let ratio = freq / cutoff
        if ratio < 0.00001 { return 0 }
        
        let s = ratio
        let butterQ1 = 0.541
        let butterQ2 = 1.307
        
        let q1 = butterQ1 + (Q - 0.707) * 1.5
        let q2 = butterQ2 + (Q - 0.707) * 1.0
        
        let denom1 = pow(1.0 - s*s, 2) + pow(s / q1, 2)
        let denom2 = pow(1.0 - s*s, 2) + pow(s / q2, 2)
        
        let magnitude = sqrt((1.0 / denom1) * (1.0 / denom2))
        return 20 * log10(max(1e-8, magnitude))
    }

    /*
     FREQUENCY TO X POSITION CONVERSION
     
     Converts a frequency (in Hz) to a horizontal pixel position on the graph.
     Uses logarithmic scale because human hearing is logarithmic.
     
     WHY PADDING?
     - Prevents the graph line from touching the edges at 20Hz and 20kHz
     - Makes the display cleaner and more readable
     
     MATH STEPS:
     1. Convert 20Hz and 20kHz to log10 values (log space boundaries)
     2. Convert input frequency to log10
     3. Normalize to 0.0-1.0 range within log space
     4. Apply to usable width (total width minus padding)
     5. Add padding offset
     
     CUSTOMIZATION:
     - padding = width * 0.05 (currently 5% on each side)
     - INCREASE (e.g., 0.08) for more margin
     - DECREASE (e.g., 0.02) for less margin
     */
    private func frequencyToXPosition(_ freq: Double, width: CGFloat) -> CGFloat {
        let minFreq = log10(20.0)
        let maxFreq = log10(20000.0)
        let logFreq = log10(max(20.0, min(20000.0, freq)))
        let normalized = (logFreq - minFreq) / (maxFreq - minFreq)
        let padding = width * 0.05
        let usableWidth = width - padding * 2
        return padding + CGFloat(normalized) * usableWidth
    }

    /*
     X POSITION TO FREQUENCY CONVERSION
     
     Reverse operation: converts a pixel position to a frequency.
     Used when drawing the filter curve to sample frequencies across the display.
     
     MATH STEPS:
     1. Subtract padding to get position in usable area
     2. Normalize to 0.0-1.0 range
     3. Interpolate in log space
     4. Convert back to linear frequency with pow(10, x)
     */
    private func xPositionToFrequency(_ x: CGFloat, width: CGFloat) -> Double {
        let minFreq = log10(20.0)
        let maxFreq = log10(20000.0)
        let padding = width * 0.05
        let usableWidth = width - padding * 2
        let normalized = Double((x - padding) / usableWidth)
        let logFreq = minFreq + normalized * (maxFreq - minFreq)
        return pow(10, logFreq)
    }
    

    /*
     FREQUENCY FORMATTING
     
     Formats frequency values for display labels.
     - Values >= 1000 Hz shown as "Xk" (e.g., "2k" for 2000Hz)
     - Values < 1000 Hz shown as is (e.g., "50" for 50Hz)
     */
    private func formatFrequency(_ freq: Int) -> String {
        if freq >= 1000 {
            let k = freq / 1000
            if freq == 20000 { return "20k" }
            return "\(k)k"
        }
        return "\(freq)"
    }
    
}

// MARK: - Preview

struct LowPassFilterEditor_Previews: PreviewProvider {
    static var previews: some View {
        LowPassFilterEditor()
    }
}
