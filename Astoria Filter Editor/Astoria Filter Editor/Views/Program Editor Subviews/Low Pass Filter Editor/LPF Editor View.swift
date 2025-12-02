//
//  LPF Editor View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//

import SwiftUI



struct LPF_Editor_View: View {
    var program: MiniWorksProgram
    
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                
                    // Left Side
                VStack {
                    GroupBox {
                        VStack(spacing: 0) {
                            Text("VCF Env. Amount")
                                .bold()
                                .foregroundStyle(.white)
                            PercentageArrowView(rawValue: program.vcfEnvelopeCutoffAmount.doubleBinding)
                                .help(program.vcfEnvelopeCutoffAmount.toolTip)
                        }
                        .padding(.horizontal, -20)
                    }
                    .frame(maxHeight: geometry.size.height / 3)
                    
                        // Cutoff Mod
                    GroupBox {
                        VStack(spacing: 0) {
                            Text("Amount")
                            PercentageArrowView(rawValue: program.cutoffModulationAmount.doubleBinding)
                                .help(program.cutoffModulationAmount.toolTip)
                        }
                        .padding(.horizontal, -20)

                        Text("Cutoff Mod.")
                            .bold()
                        
                        VStack(spacing: 0) {
                            ArrowPickerGlowView(selection: program.cutoffModulationSource.modulationBinding,
                                                direction: .right,
                                                arrowColor: .yellow)
                            .help(program.cutoffModulationSource.toolTip)
                            .padding(.top, -10)
                            
                            Text("Source")
                                .padding(.trailing, 15)
                        }
                        .padding(.horizontal, -20)
                    }
                    .foregroundStyle(.yellow)
                }
                .frame(maxWidth: geometry.size.width * (1/5))
                
                    // Center
                VStack {
                    Text("Low Pass Filter")
                        .bold()
                        .foregroundStyle(.white)
                    LowPassFilterEditor(program: program)
                    
                }
                
                    // Right Side
                VStack {
                    HStack(spacing: 0) {
                        cutoffFrequency
                        resonanceKnob
                    }
                    
                    GroupBox {
                        VStack(spacing: 0) {
                            Text("Amount")
                            PercentageArrowView(rawValue: program.resonanceModulationAmount.doubleBinding)
                                .help(program.resonanceModulationAmount.toolTip)
                        }
                        .padding(.horizontal, -20)
                        
                        Text("Resonance Mod.")
                            .bold()
                        
                        VStack(spacing: 0) {
                            ArrowPickerGlowView(selection: program.resonanceModulationSource.modulationBinding,
                                                direction: .left,
                                                arrowColor: .red)
                            .help(program.resonanceModulationSource.toolTip)
                            .padding(.top, -10)
                            
                            Text("Source")
                                .padding(.leading, 15)
                        }
                        .padding(.horizontal, -20)
                    }
                    .foregroundStyle(.red)
                }
                .frame(maxWidth: geometry.size.width * (1/5))
                
                
            }
            .foregroundStyle(.blue)
        } // Geo
    }
    
    
    var cutoffFrequency: some View {
        VStack {
            CircularFader(value: program.cutoff.knobBinding,
                          size: 40,
                          mode: .unidirectional(color: .blue), primaryColor: .yellow)
            .frame(width: 60)
            .padding(.vertical)
                //            .padding([.bottom, .horizontal], 10)
            
            Text("Cutoff")
                .font(.caption)
                .foregroundStyle(.yellow)
                .bold()
                //                .padding(.bottom, 10)
            
                //            Text("\(frequencyToHz(program.cutoff.value), specifier: "%.0f") Hz")
                //                .font(.caption)
                //                .foregroundColor(.blue)
            
                //            Text("[\(Int(program.cutoff.value))]")
                //                .font(.caption)
                //                .foregroundColor(.gray)
        }
            //        .background(Color.black.opacity(0.7))
            //        .cornerRadius(10)
    }
    
    
    
    var resonanceKnob: some View {
        VStack {
            CircularFader(value: program.resonance.knobBinding,
                          size: 40,
                          mode: .unidirectional(color: .pink), primaryColor: .red)
            .frame(width: 60)
            .padding(.vertical)
                //            .padding([.bottom, .horizontal], 10)
            
            Text("Resonance")
                .font(.caption)
                .foregroundStyle(.red)
                .bold()
                //                .padding(.bottom, 10)
            
            
                //            Text("\(modAmountToPercentage(program.resonance.value), specifier: "%.0f")%")
                //                .font(.caption)
                //                .foregroundColor(.orange)
                //                .frame(width: 50)
            
                //            Text("[\(Int(program.resonance.value))]")
                //                .font(.caption)
                //                .foregroundColor(.gray)
        }
            //        .background(Color.black.opacity(0.7))
            //        .cornerRadius(10)
        
    }
    
    
}


#Preview {
    @Previewable @State var program: MiniWorksProgram = MiniWorksProgram()
    
    LPF_Editor_View(program: program)
        .frame(width: 600, height: 260)
}
