import SwiftUI

struct LowPassFilterView: View {
    @State private var frequency: Double = 1000 // 20 to 20000 Hz
    @State private var resonance: Double = 0 // 0 to 127
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Low Pass Filter (24dB/oct)")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Filter response visualization
                FilterResponseShape(frequency: frequency, resonance: resonance)
                    .stroke(Color.blue, lineWidth: 2)
                    .background(
                        // Grid lines
                        GridLines()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                
                // Vertical resonance slider
                VStack {
                    Text("Resonance")
                        .font(.caption)
                        .rotationEffect(.degrees(-90))
                    
                    Slider(value: $resonance, in: 0...127)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 200)
                    
                    Text("\(Int(resonance))")
                        .font(.caption)
                        .frame(width: 40)
                }
                .frame(width: 60)
            }
            
            // Horizontal frequency slider
            VStack(spacing: 8) {
                HStack {
                    Text("Frequency")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(frequency)) Hz")
                        .font(.caption)
                        .monospacedDigit()
                }
                
                Slider(value: $frequency, in: 20...20000)
                    .accentColor(.blue)
                
                HStack {
                    Text("20 Hz")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("20 kHz")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FilterResponseShape: Shape {
    var frequency: Double
    var resonance: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let minFreq = 20.0
        let maxFreq = 20000.0
        let nyquist = maxFreq
        
        // Convert frequency to logarithmic position
        let cutoffPosition = logPosition(freq: frequency, minFreq: minFreq, maxFreq: maxFreq, width: rect.width)
        
        let points = 500
        
        for i in 0...points {
            let x = Double(i) / Double(points) * rect.width
            
            // Convert x position back to frequency (logarithmic scale)
            let freq = freqFromPosition(x: x, minFreq: minFreq, maxFreq: maxFreq, width: rect.width)
            
            // Calculate magnitude response for 24dB/octave (4-pole) low-pass filter
            let normalizedFreq = freq / frequency
            
            // Base response (without resonance)
            var magnitude: Double
            
            if normalizedFreq < 1.0 {
                // Passband - flat until near cutoff
                magnitude = 1.0
            } else {
                // 24dB/octave = -24dB per doubling of frequency
                // Each octave: magnitude *= 10^(-24/20) = 10^(-1.2) ≈ 0.0631
                let octaves = log2(normalizedFreq)
                let dB = -24.0 * octaves
                magnitude = pow(10.0, dB / 20.0)
            }
            
            // Add resonance peak at cutoff frequency
            if resonance > 0 {
                // Q factor increases with resonance
                // At resonance=127, Q should be quite high (narrow peak)
                let Q = 0.5 + (resonance / 127.0) * 20.0 // Q from 0.5 to 20.5
                
                // Resonance peak calculation
                let freqRatio = freq / frequency
                
                // Gaussian-like peak centered at cutoff
                let peakWidth = 1.0 / Q
                let deviation = log(freqRatio)
                let resonancePeak = exp(-pow(deviation / peakWidth, 2))
                
                // Peak gain increases with resonance
                let peakGain = (resonance / 127.0) * 3.0 // Up to 3x gain at peak
                
                // Combine base response with resonance
                magnitude = magnitude + resonancePeak * peakGain
                
                // Clamp to reasonable values
                magnitude = min(magnitude, 4.0)
            }
            
            // Convert magnitude to dB for better visualization
            let dB = 20.0 * log10(max(magnitude, 0.001))
            
            // Map dB to y position (0 dB at top, -60 dB at bottom)
            let minDB = -60.0
            let maxDB = 12.0 // Allow some headroom for resonance peaks
            let normalizedDB = (dB - minDB) / (maxDB - minDB)
            let y = rect.height * (1.0 - normalizedDB)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
    
    // Convert frequency to logarithmic x position
    func logPosition(freq: Double, minFreq: Double, maxFreq: Double, width: Double) -> Double {
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = log10(freq)
        return ((logFreq - logMin) / (logMax - logMin)) * width
    }
    
    // Convert x position back to frequency
    func freqFromPosition(x: Double, minFreq: Double, maxFreq: Double, width: Double) -> Double {
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let ratio = x / width
        let logFreq = logMin + ratio * (logMax - logMin)
        return pow(10.0, logFreq)
    }
}

struct GridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Horizontal lines (dB levels)
        for i in 0...6 {
            let y = rect.height * Double(i) / 6.0
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        // Vertical lines (frequency markers)
        let frequencies = [20.0, 50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0, 10000.0, 20000.0]
        
        for freq in frequencies {
            let logMin = log10(20.0)
            let logMax = log10(20000.0)
            let logFreq = log10(freq)
            let x = ((logFreq - logMin) / (logMax - logMin)) * rect.width
            
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        return path
    }
}

// Preview
#Preview {
    LowPassFilterView()
        .frame(width: 600, height: 500)
}
