//
//  Volume Editor.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

// Volume
// Volume Mod Source
// Volume Mod Amount
// vca Envelope Volume Amount


struct Volume_Editor: View {
    var program: MiniWorksProgram
    
    
    var body: some View {
        VStack {
            Text("Volume")
                .bold()
            
            HStack {
                
                // VCA Env
                VStack {
                    GroupBox {
                        VStack {
                            Text("VCA Env. Amount")
                            PercentageArrowView(rawValue: program.vcaEnvelopeVolumeAmount.doubleBinding)
                                .padding(.horizontal, -20)
                                .padding(.top, -10)
                        }
                    }
                    .foregroundStyle(.orange)
                    
                    GroupBox {
                        VStack {
                            Text("Volume")
                                .bold()
                                .padding(.bottom)
                            
                            CircularFader(value: program.volume.knobBinding,
                                          size: 40,
                                          mode: .unidirectional(color: .white),
                                          primaryColor: .orange)
                            
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .foregroundStyle(.orange)
                } // VCA & Volume
                
                GroupBox {
                    VStack {
                        Text("Amount")
                        PercentageArrowView(rawValue: program.volumeModulationAmount.doubleBinding)
                    }
                    .padding(.horizontal, -20)
                    
                    Text("Volume Mod.")
                        .bold()
                    
                    VStack(spacing: 0) {
                        ArrowPickerGlowView(selection: program.volumeModulationSource.modulationBinding,
                                            direction: .left,
                                            arrowColor: .orange)
                        Text("Source")
                            .padding(.leading, 15)
                    }
                    .padding(.horizontal, -20)
                }
                .foregroundStyle(.orange)
                    //            .frame(maxWidth: geometry.size.width * (1/5))
                
            }
        }
    }
    
}


#Preview {
    @Previewable @State var program: MiniWorksProgram = MiniWorksProgram()
    
    Volume_Editor(program: program)
        .frame(maxWidth: 450, maxHeight: 300)
}
