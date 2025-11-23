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
                                .padding(.top, -10)
                        }
                        .padding(.horizontal, -20)
                    }
                    //                .tint(.orange)
                    .foregroundStyle(.orange)
                    
                    GroupBox {
                        Text("Volume")
                            .bold()
                            .padding(.bottom)
                        
                        CircularFader(value: program.volume.knobBinding,
                                      size: 40,
                                      mode: .unidirectional(color: .orange))
                        .padding(.bottom, 50)
                    }
                    //                .background(.orange)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, -20)
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
                                            arrowColor: .blue)
                        Text("Source")
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
