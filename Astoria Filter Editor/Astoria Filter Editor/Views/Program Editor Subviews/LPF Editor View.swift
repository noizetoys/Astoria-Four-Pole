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
                
                    // Cutoff Mod
                GroupBox {
                    VStack {
                        Text("Amount")
                        PercentageArrowView(rawValue: program.cutoffModulationAmount.doubleBinding)
                    }
                    .padding(.horizontal, -20)
                    
                    Text("Cutoff Mod.")
                        .bold()
                    
                    VStack(spacing: 0) {
                        ArrowPickerGlowView(selection: program.cutoffModulationSource.modulationBinding,
                                            direction: .right,
                                            arrowColor: .blue)
                        Text("Source")
                    }
                    .padding(.horizontal, -20)
                }
                .frame(maxWidth: geometry.size.width * (1/5))
                
                LowPassFilterEditor(program: program)
                
                    // Resonance Mod
                GroupBox {
                    VStack {
                        Text("Amount")
                        PercentageArrowView(rawValue: program.resonanceModulationAmount.doubleBinding)
                    }
                    .padding(.horizontal, -20)
                    
                    Text("Resonance Mod.")
                        .bold()
                    
                    VStack {
                        ArrowPickerGlowView(selection: program.resonanceModulationSource.modulationBinding,
                                            direction: .left,
                                            arrowColor: .purple)
                        Text("Source")
                    }
                    .padding(.horizontal, -20)
                }
                
                .frame(maxWidth: geometry.size.width * (1/5))
                
                
            }
            .foregroundStyle(.blue)
        } // Geo
    }
    
}


#Preview {
    @Previewable @State var program: MiniWorksProgram = MiniWorksProgram()
    
    LPF_Editor_View(program: program)
        .frame(width: 600, height: 260)
}
