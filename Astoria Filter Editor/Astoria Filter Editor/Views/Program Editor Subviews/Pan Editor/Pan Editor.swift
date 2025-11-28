//
//  Pan Editor.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/22/25.
//

import SwiftUI

struct Pan_Editor: View {
    let program: MiniWorksProgram
    
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("Panning")
                    .bold()
                
                PanControl(value: program.panning.knobBinding)
                    .padding(10)
                
                
                HStack {
                    Gate_Trigger_View(program: program)
                    
                    // Panning Modulation
                    GroupBox {
                        VStack(spacing: 0) {
                            Text("Amount")
                            PercentageArrowView(rawValue: program.panningModulationAmount.doubleBinding)
                        }
                        .padding(.horizontal, -20)
                        
                        Text("Panning Mod.")
                            .bold()
                        
                        VStack(spacing: 0) {
                            ArrowPickerGlowView(selection: program.panningModulationSource.modulationBinding,
                                                direction: .left,
                                                arrowColor: .blue)
                            .padding(.top, -10)
                            
                            Text("Source")
                                .padding(.leading, 15)
                        }
                        .padding(.horizontal, -20)
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: geo.size.width / 3, maxHeight: .infinity)
//                    .padding([.bottom, .trailing])
                    
                }
            } // HStack
        }
        
    }
    
    
    
    
}


#Preview {
    @Previewable @State var program: MiniWorksProgram = .init()
    Pan_Editor(program: program)
        .frame(maxWidth: 400, maxHeight: 260)
}
