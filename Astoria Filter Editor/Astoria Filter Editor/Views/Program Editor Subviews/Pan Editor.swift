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
                    .padding()
//                    .frame(maxHeight: 40)
                
                
                HStack {
                    
                    Gate_Trigger_View(program: program)
                    
                    GroupBox {
                        VStack {
                            VStack {
                                PercentageArrowView(rawValue: program.panningModulationAmount.doubleBinding)
                                    .offset(y: 5)
                                
                                Text("Modulation Amount")
                            }
                            
                            VStack(spacing: 0) {
                                ArrowPickerGlowView(selection: program.panningModulationSource.modulationBinding,
                                                    direction: .left,
                                                    arrowColor: .green)
                                
                                Text("Modulation Source")
                                    .padding(.top)
                            }
                        }
                        
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: geo.size.width / 2)
                    .padding([.bottom, .trailing])
                    
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
