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
    @State var program: MiniWorksProgram
    
//    @State private var cutoff: UInt8 = 64      // 0 = 20Hz, 127 = 20kHz
//    @State private var resonance: UInt8 = 0       // 0 = no resonance, 127 = max resonance
    
    // Modulation amounts (0-127 mapped to -64 to +63, where 64 = 0%)
    // CUSTOMIZATION: 64 = neutral (0%), 0 = -100%, 127 = +100%
//    @State private var cutoffModAmount: UInt8 = 64  // No modulation at start
//    @State private var resonanceModAmount: UInt8 = 64  // No modulation at start
    @State private var fillStyle: FilterFillStyle = .soft

    
    var body: some View {
        VStack(spacing: 20) {
            // CUSTOMIZATION: Change title text or styling here
            Text("Low Pass Filter Editor")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            // Filter Visualization
            // CUSTOMIZATION: Adjust .frame(height:) to change graph size
            FilterResponseView(program: program, fillStyle: fillStyle)
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
                        Picker("", selection: $program.cutoffModulationSource.modulationSource) {
                            ForEach(ModulationSource.allCases) { source in
                                Text(source.name).tag(source)
                            }
                        }
                        Spacer()
                    }
                    
                    if program.cutoffModulationSource.modulationSource?.id != 0 {
                        HStack {
                            Text("Mod Amount:")
                                .font(.caption)
                                .frame(width: 90, alignment: .leading)
                            Slider(value: program.cutoffModulationAmount.doubleBinding, in: 0...127, step: 1)
                                .accentColor(.orange)
                            
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
                    
                    HStack {
                        Text("Cutoff:")
                            .font(.caption)
                            .frame(width: 90, alignment: .leading)
                        
                        Slider(value: program.cutoff.doubleBinding, in: 0...127, step: 1)
                            .accentColor(.blue)
                        
                        Text("\(frequencyToHz(program.cutoff.value), specifier: "%.0f") Hz")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(width: 70)
                        
                        Text("[\(Int(program.cutoff.value))]")
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
                if program.resonance.value >= 80 {
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
                        Picker("", selection: $program.resonanceModulationSource.modulationSource) {
                            ForEach(ModulationSource.allCases) { source in
                                Text(source.name).tag(source)
                            }
                        }
                        Spacer()
                    }
                    
                    if program.resonanceModulationSource.modulationSource?.id != 0 {
                        VStack(spacing: 5) {
                            HStack {
                                Text("Mod Amount:")
                                    .font(.caption)
                                    .frame(width: 90, alignment: .leading)
                                
                                Slider(value: program.resonanceModulationAmount.doubleBinding, in: 0...127, step: 1)
                                    .accentColor(.orange)
                                
                                Text("\(modAmountToPercentage(program.resonanceModulationAmount.value), specifier: "%.0f")%")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .frame(width: 50)
                                
                                Text("[\(Int(program.resonanceModulationAmount.value))]")
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
                        Slider(value: program.resonance.doubleBinding, in: 0...127, step: 1)
                            .accentColor(program.resonance.value >= 80 ? .red : .green)
                        Text("  ")
                            .frame(width: 70)
                        Text("[\(Int(program.resonance.value))]")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 40)
                    }
                }
                .padding(.vertical, 5)
            }
            .padding(.horizontal)
            
            GroupBox(label: Text("Display").font(.headline)) {
                HStack {
                    Text("Fill Style:")
                        .font(.caption)
                        .frame(width: 90, alignment: .leading)
                    
                    Picker("", selection: $fillStyle) {
                        ForEach(FilterFillStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 6)
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
