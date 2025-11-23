//
//  Pan Editor.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/22/25.
//

import SwiftUI

struct Pan_Editor: View {
    var program: MiniWorksProgram
    
    var body: some View {
        VStack {
            Text("Panning")
                .bold()
            
//                .font(.title)
            
            PanControl(value: program.panning.knobBinding)
                .padding(.top, 30)
                .padding(.horizontal)
            
            GroupBox {
                
                ZStack {
                    HStack {
                        VStack {
                            PercentageArrowView(rawValue: program.panningModulationAmount.doubleBinding)
                                .offset(y: 5)
                            
                            Text("Modulation Amount")
                        }
                        .padding(.horizontal, -20)
                        
                        VStack(spacing: 0) {
                            ArrowPickerGlowView(selection: program.panningModulationSource.modulationBinding,
                                                direction: .left,
                                                arrowColor: .green)
                            Text("Modulation Source")
                        }
                        .padding(.horizontal, -20)
                    }
                    
                }
            }
            .foregroundStyle(.red)
            .padding()
            //            PanControl(
            //                value: program.panning.knobBinding,
            //                style: .squares,
            //                indicatorColor: .red,
            //                glowColor: .red,
            //                glowIntensity: 0.5,
            //                itemCount: 13,
            //                neighborGlowRadius: 1.2,
            //                glowFalloffExponent: 2.0
            //            )
            
//            Text("Value: \(program.panning.value)")
            
        }
    }
}


#Preview {
    @Previewable @State var program: MiniWorksProgram = .init()
    Pan_Editor(program: program)
        .frame(maxWidth: 450, maxHeight: 310)
}
