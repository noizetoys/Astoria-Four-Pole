//
//  LowPassFilterEditor 2.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//
import Foundation
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

// MARK: - Main View

struct LowPassFilterEditor: View {
    // Filter parameters (0-127 MIDI-style range)
    // CUSTOMIZATION: Change initial values here
    var program: MiniWorksProgram
    
//    @State private var cutoff: UInt8 = 64      // 0 = 20Hz, 127 = 20kHz
//    @State private var resonance: UInt8 = 0       // 0 = no resonance, 127 = max resonance
    
    // Modulation amounts (0-127 mapped to -64 to +63, where 64 = 0%)
    // CUSTOMIZATION: 64 = neutral (0%), 0 = -100%, 127 = +100%
//    @State private var cutoffModAmount: UInt8 = 64  // No modulation at start
//    @State private var resonanceModAmount: UInt8 = 64  // No modulation at start
    @State private var fillStyle: FilterFillStyle = .strongGlow

    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 20) {
                    // CUSTOMIZATION: Change title text or styling here
//                Text("Low Pass Filter Editor")
//                    .fontWeight(.bold)
                
                    // Filter Visualization
                    // CUSTOMIZATION: Adjust .frame(height:) to change graph size
                FilterResponseView(program: program, fillStyle: fillStyle)
                    .frame(maxHeight: .infinity)
//                .frame(height: 250)  // CUSTOMIZATION: Graph height in points
                    .background(Color.black)  // CUSTOMIZATION: Graph background color
                    .cornerRadius(10)  // CUSTOMIZATION: Corner rounding
            }
            
                // Frequency Controls
            HStack {
                cutoffFrequency
                Spacer()
                resonanceKnob
            }
        }
        
    }
    
    
    var cutoffHeader: some View {
        Text("Cutoff Frequency")
            .font(.headline)
    }
    
    
    var cutoffModSource: some View {
        VStack {
            Text("Mod Source:")
                .font(.caption)
            
            Picker("", selection: program.cutoffModulationSource.modulationBinding) {
                ForEach(ModulationSource.allCases) { source in
                    Text(source.name).tag(source)
                }
            }
        }
    }
    
    
    var cutoffModAmount: some View {
        VStack {
            Text("Mod Amount:")
                .font(.caption)
            
            CircularFader(value: program.cutoffModulationAmount.knobBinding,
                          size: 40,
                          mode: .bidirectional(positiveColor: .green,
                                               negativeColor: .red,
                                               center: 64,
                                               positiveRange: 64..<128,
                                               negativeRange: 0..<64),
                          isActive: program.cutoffModulationSource.modulationSource?.id != 0, primaryColor: .orange)
            .frame(width: 60)
            
            Text("\(modAmountToPercentage(program.cutoffModulationAmount.value), specifier: "%.0f")%")
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 50)
            
            Text("[\(Int(program.cutoffModulationAmount.value)))]")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 40)
        }
    }
    
    
    var cutoffFrequency: some View {
        VStack {
            CircularFader(value: program.cutoff.knobBinding,
                          size: 40,
                          mode: .unidirectional(color: .blue), primaryColor: .yellow)
            .frame(width: 60)
            .padding(.top)
            .padding([.bottom, .horizontal], 10)
            
            Text("Cutoff:")
                .font(.caption)
                .padding(.bottom, 10)
            
//            Text("\(frequencyToHz(program.cutoff.value), specifier: "%.0f") Hz")
//                .font(.caption)
//                .foregroundColor(.blue)

//            Text("[\(Int(program.cutoff.value))]")
//                .font(.caption)
//                .foregroundColor(.gray)
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
    }
    
    
    var resonanceHeader: some View {
        HStack {
            Text("Resonance")
                .font(.headline)
            
            if program.resonance.value >= 80 {
                Text("⚠ Self-Osc.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
        }
    }
    
    
    var resonanceModSource: some View {
        VStack {
            Text("Mod Source:")
                .font(.caption)
            
            Picker("", selection: program.resonanceModulationSource.modulationBinding) {
                ForEach(ModulationSource.allCases) { source in
                    Text(source.name).tag(source)
                }
            }
        }
        .padding(.horizontal)
    }
    
    
    var resonanceModAmount: some View {
        VStack {
            Text("Mod Amount:")
                .font(.caption)

            CircularFader(value: program.resonanceModulationAmount.knobBinding,
                          size: 40,
                          mode: .bidirectional(positiveColor: .green,
                                               negativeColor: .red,
                                               center: 64,
                                               positiveRange: 64..<128,
                                               negativeRange: 0..<64),
                          isActive: program.resonanceModulationSource.modulationSource?.id != 0, primaryColor: .green)
            .frame(width: 60)

            Text("\(modAmountToPercentage(program.resonanceModulationAmount.value), specifier: "%.0f")%")
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 50)

            Text("[\(Int(program.resonanceModulationAmount.value))]")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 40)
        }
    }
    
    
    var resonanceKnob: some View {
        VStack {
            CircularFader(value: program.resonance.knobBinding,
                          size: 40,
                          mode: .unidirectional(color: .pink), primaryColor: .red)
            .frame(width: 60)
            .padding(.top)
            .padding([.bottom, .horizontal], 10)

            Text("Resonance:")
                .font(.caption)
                .padding(.bottom, 10)


//            Text("\(modAmountToPercentage(program.resonance.value), specifier: "%.0f")%")
//                .font(.caption)
//                .foregroundColor(.orange)
//                .frame(width: 50)

//            Text("[\(Int(program.resonance.value))]")
//                .font(.caption)
//                .foregroundColor(.gray)
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)

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
    private func frequencyToHz(_ value: UInt8) -> Double {
        let minFreq = log10(20.0)      // CUSTOMIZATION: Minimum frequency (log)
        let maxFreq = log10(20000.0)   // CUSTOMIZATION: Maximum frequency (log)
        let normalized = Double(value) / 127.0  // Normalize to 0.0-1.0
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
    private func modAmountToPercentage(_ value: UInt8) -> Double {
//        Double(abs(Double(value) - 64) / 63.5) * 100
        (abs(Double(value) - 64) / 63.5) * 100
    }
}


#Preview {
    LowPassFilterEditor(program: MiniWorksProgram())
}
