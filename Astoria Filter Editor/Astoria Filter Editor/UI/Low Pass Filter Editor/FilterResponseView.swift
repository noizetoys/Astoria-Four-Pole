//
//  FilterResponseView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//
import Foundation
import SwiftUI






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
struct FilterResponseView: View {
    let program: MiniWorksProgram
    let fillStyle: FilterFillStyle   // 👈 NEW
    

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Filter response curve and grid
                filterVisualization(geometry: geometry)
                
                // Frequency modulation arrow (horizontal, just above the line)
                let cutoffModAmount = abs(program.cutoffModulationAmount.doubleValue - 64) / 63.5
                let _ = debugPrint(message: "cutoffModAmount == \(cutoffModAmount)")
                if program.cutoffModulationSource.modulationSource?.id != 0 && cutoffModAmount > 0.01 {
                    frequencyModArrow(geometry: geometry)
                }
                
                // Resonance modulation arrow (vertical, to the right of peak)
                let resModAmount = abs(program.resonanceModulationAmount.doubleValue - 64) / 63.5
                let _ = debugPrint(message: "resModAmount == \(resModAmount)")
                    if program.resonanceModulationSource.modulationSource?.id != 0 && resModAmount > 0.01 {
                    resonanceModArrow(geometry: geometry)
                }
            }
        }
    }
    
    
    private func filterVisualization(geometry: GeometryProxy) -> some View {
        let curveColor: Color = program.resonance.value >= 80 ? .red : .blue
        let size = geometry.size
        
        return ZStack {
            // Grid
            frequencyScaleView(geometry: geometry)
            
            // FILL AREA under the curve, style based on enum
            switch fillStyle {
                case .none:
                    EmptyView()
                    
                case .soft:
                    filterFillPath(geometry: geometry)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    curveColor.opacity(0.35),
                                    .clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                case .strong:
                    filterFillPath(geometry: geometry)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: curveColor.opacity(0.8), location: 0.0),
                                    .init(color: curveColor.opacity(0.3), location: 0.5),
                                    .init(color: .clear,               location: 1.0),
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                case .cutoffGlow:
                    let cutoffFreq = frequencyToHz(program.cutoff.value)
                    let cutoffX = frequencyToXPosition(cutoffFreq, width: size.width)
                    let center = UnitPoint(x: cutoffX / size.width, y: 0.45)
                    
                    filterFillPath(geometry: geometry)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    curveColor.opacity(0.8),
                                    curveColor.opacity(0.3),
                                    .clear
                                ]),
                                center: center,
                                startRadius: 0,
                                endRadius: min(size.width, size.height) * 0.7
                            )
                        )
                    
                case .strongGlow:    // 👈 NEW COMBINED STYLE
                    let cutoffFreq = frequencyToHz(program.cutoff.value)
                    let cutoffX = frequencyToXPosition(cutoffFreq, width: size.width)
                    let center = UnitPoint(x: cutoffX / size.width, y: 0.45)
                    
                    ZStack {
                        // Base strong linear fill
                        filterFillPath(geometry: geometry)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: curveColor.opacity(0.85), location: 0.0),
                                        .init(color: curveColor.opacity(0.4),  location: 0.5),
                                        .init(color: .clear,                  location: 1.0),
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Cutoff-centered glow layered on top
                        filterFillPath(geometry: geometry)
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        curveColor.opacity(0.9),
                                        curveColor.opacity(0.4),
                                        .clear
                                    ]),
                                    center: center,
                                    startRadius: 0,
                                    endRadius: min(size.width, size.height) * 0.7
                                )
                            )
                            .blendMode(.screen)
                            .opacity(0.9)
                    }
            }
            
            // Curve line on top
            filterCurvePath(geometry: geometry)
                .stroke(curveColor, lineWidth: 3.0)
                .shadow(color: .white.opacity(0.5), radius: 1.2)
        }
    }

    
    private func filterFillPath(geometry: GeometryProxy) -> Path {
        let width = geometry.size.width
        let height = geometry.size.height - 30
        
        var path = Path()
        
        let cutoffFreq = frequencyToHz(program.cutoff.value)
        let Q = resonanceToQ(program.resonance.value)
        
        let numPoints = 1200
        
        let baselineY = height * 0.45
        let topMargin: CGFloat = 25
        let bottomThreshold = height - 30
        
        // Track horizontal extents and whether we drew anything
        var firstX: CGFloat? = nil
        var lastX: CGFloat? = nil
        var hasHitBottom = false
        
        for i in 0..<numPoints {
            let x = CGFloat(i) / CGFloat(numPoints - 1) * width
            let freq = xPositionToFrequency(x, width: width)
            
            let response = lowPassResponse24dB(freq: freq, cutoff: cutoffFreq, Q: Q)
            
            var y: CGFloat
            if response > 0 {
                // Resonance peak (above baseline)
                let availableHeightAbove = baselineY - topMargin
                let normalizedPeak = min(1.0, response / 14.0)
                y = baselineY - normalizedPeak * availableHeightAbove
            } else {
                // Attenuation / slope (below baseline)
                let availableHeightBelow = bottomThreshold - baselineY
                let normalizedAttenuation = min(1.0, abs(response) / 90.0) // same as your sharper curve
                y = baselineY + normalizedAttenuation * availableHeightBelow
            }
            
            // Clamp at bottom and mark that we've hit it
            if y >= bottomThreshold {
                y = bottomThreshold
                hasHitBottom = true
            }
            
            if firstX == nil { firstX = x }
            lastX = x
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            // If we've hit the bottom and we're already at max attenuation, we can early–out
            if hasHitBottom && response <= -90 {
                break
            }
        }
        
        // Close the shape down to the bottom to make it a solid area
        if let startX = firstX, let endX = lastX {
            path.addLine(to: CGPoint(x: endX, y: bottomThreshold))
            path.addLine(to: CGPoint(x: startX, y: bottomThreshold))
            path.closeSubpath()
        }
        
        return path
    }

    
    private func frequencyModArrow(geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let percentage = ((Double(program.cutoffModulationAmount.value) - 64) / 63.5) * 100
        
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
        let percentage = ((Double(program.resonanceModulationAmount.value) - 64) / 63.5) * 100
        
        // Position arrow to the RIGHT of the resonance peak
        let cutoffFreq = frequencyToHz(program.cutoff.value)
        let cutoffXPos = frequencyToXPosition(cutoffFreq, width: width)
        
        // Position significantly to the right of the cutoff frequency
        let xPos = min(width - 60, cutoffXPos + 80)
        
        // Calculate peak height
        let Q = resonanceToQ(program.resonance.value)
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
        
        let cutoffFreq = frequencyToHz(program.cutoff.value)
        let Q = resonanceToQ(program.resonance.value)
        
        // Increased precision → sharper rendering
        let numPoints = 1200
        
        // Baseline and margins
        let baselineY = height * 0.45
        let topMargin: CGFloat = 25
        let bottomThreshold = height - 30
        
        // NEW: track whether we've already hit the bottom
        var hasHitBottom = false
        
        for i in 0..<numPoints {
            let x = CGFloat(i) / CGFloat(numPoints - 1) * width
            let freq = xPositionToFrequency(x, width: width)
            
            let response = lowPassResponse24dB(freq: freq, cutoff: cutoffFreq, Q: Q)
            
            // Compute y from dB response
            var y: CGFloat
            if response > 0 {
                // Resonance peak (above baseline)
                let availableHeightAbove = baselineY - topMargin
                let normalizedPeak = min(1.0, response / 14.0)
                y = baselineY - normalizedPeak * availableHeightAbove
            } else {
                // Attenuation / slope (below baseline)
                let availableHeightBelow = bottomThreshold - baselineY
                
                // Sharper visual slope (90.0 instead of 160.0)
                let normalizedAttenuation = min(1.0, abs(response) / 90.0)
                y = baselineY + normalizedAttenuation * availableHeightBelow
            }
            
            // If we've reached or passed the bottom, clamp once and stop
            if y >= bottomThreshold {
                // Clamp to bottom
                let clampedY = bottomThreshold
                
                if !hasHitBottom {
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: clampedY))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: clampedY))
                    }
                    hasHitBottom = true
                }
                
                // Stop drawing any further points → no horizontal line to the right
                break
            }
            
            // Normal drawing while above bottomThreshold
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }

    // Convert 0-127 to 20Hz-20kHz (logarithmic)
//    private func frequencyToHz(_ value: Double) -> Double {
    private func frequencyToHz(_ value: UInt8) -> Double {
        let minFreq = log10(20.0)
        let maxFreq = log10(20000.0)
        let normalized = Double(value) / 127.0
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
//    private func resonanceToQ(_ value: Double) -> Double {
    private func resonanceToQ(_ value: UInt8) -> Double {
        if value < 1 {
            return 0.707  // Minimum Q (Butterworth response)
        }
        let normalized = Double(value) / 127.0  // Convert to 0.0-1.0 range
        // CUSTOMIZATION: Change 3.0 to adjust maximum Q factor
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
        
        if ratio < 0.00001 {
            return 0  // DC (0 Hz) - no attenuation
        }
        
        // 4th order Butterworth-style low-pass filter
        // 24dB/octave = 4th order = two cascaded 2nd order (biquad) sections
        
        let s = ratio  // Normalized frequency (freq/cutoff)
        
        // Standard Butterworth Q values for 4th order filter
        // These create a maximally flat passband response
        let butterQ1 = 0.541  // First biquad Q
        let butterQ2 = 1.307  // Second biquad Q
        
        // Add user resonance on top of Butterworth response
        // CUSTOMIZATION: Adjust multipliers (1.5, 1.0) to change resonance distribution
        let q1 = butterQ1 + (Q - 0.707) * 1.5  // More resonance in first stage
        let q2 = butterQ2 + (Q - 0.707) * 1.0  // Less resonance in second stage
        
        // First biquad section
        // Formula: H(s) = 1 / ((1-s²)² + (s/Q)²)
        let denom1 = pow(1.0 - s * s, 2) + pow(s / q1, 2)
        let mag1Sq = 1.0 / denom1
        
        // Second biquad section  
        let denom2 = pow(1.0 - s * s, 2) + pow(s / q2, 2)
        let mag2Sq = 1.0 / denom2
        
        // Combined 4th order magnitude (multiply the two 2nd order responses)
        let magnitude = sqrt(mag1Sq * mag2Sq)
        
        // Convert to decibels
        let dB = 20 * log10(max(0.00000001, magnitude))  // Prevent log(0)
        
        return dB
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
        let minFreq = log10(20.0)      // Log of 20Hz
        let maxFreq = log10(20000.0)   // Log of 20kHz
        let logFreq = log10(max(20.0, min(20000.0, freq)))  // Clamp and convert to log
        let normalized = (logFreq - minFreq) / (maxFreq - minFreq)  // 0.0 to 1.0
        
        // CUSTOMIZATION: Adjust padding percentage here
        let padding: CGFloat = width * 0.05  // 5% padding on each side
        let usableWidth = width - (2 * padding)
        return padding + (CGFloat(normalized) * usableWidth)
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
        
        // Account for padding
        let padding: CGFloat = width * 0.05  // Must match padding above
        let usableWidth = width - (2 * padding)
        let adjustedX = x - padding
        let normalized = Double(adjustedX / usableWidth)
        
        let logFreq = minFreq + normalized * (maxFreq - minFreq)
        return pow(10, logFreq)  // Convert from log back to linear
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
            if freq == 20000 {
                return "20k"
            }
            return "\(k)k"
        }
        return "\(freq)"
    }
}



#Preview {
    FilterResponseView(program: MiniWorksProgram(), fillStyle: .cutoffGlow)
}
