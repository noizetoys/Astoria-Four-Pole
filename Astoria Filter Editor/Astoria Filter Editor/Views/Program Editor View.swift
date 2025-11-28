//
//  Program Editor View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI


struct Program_Editor_View: View {
    var program: MiniWorksProgram
    
    
    init(program: MiniWorksProgram?) {
        guard let program
        else {
            self.program = MiniWorksProgram()
            return
        }
        
        self.program = program
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            
            VStack{
                topViews(geometry)
                
                middleViews(geometry)

                bottomViews(geometry)
            }
            .padding(.horizontal)
        }
        
    }
    
    
    private func topViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            VCF_Editor_View(program: program, showControls: true)
            .frame(maxWidth: cut(geometry, by: 1/3))
            
            LPF_Editor_View(program: program)
        }
        
    }
    
    
    private func bottomViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            MIDIMonitorView()
                .frame(maxWidth: geometry.size.width * (1/3))
            
            GroupBox {
                LFOAnimationView(program: program)
            }
            .background(Color.blue.opacity(0.2))
            
            
            Modulation_Destination_View(program: program)
                .frame(maxWidth: geometry.size.width * (1/6))
            
        }
        
    }
    
    
    private func middleViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            VCA_Editor_View(program: program, showControls: true)
            
            Volume_Editor(program: program)
            
            Pan_Editor(program: program)
                .frame(maxWidth: cut(geometry, by: 1/3))

        }
    }
    
}


#Preview {
//    @Previewable @State var editorViewModel = EditorViewModel()
    @Previewable @State var program = MiniWorksProgram()
//    program.cutoffModulationSource.modulationSource = ModulationSource.aftertouch
//    program.resonanceModulationSource.modulationSource = ModulationSource.breathControl
//    program.volumeModulationSource.modulationSource = ModulationSource.footcontroller
//    program.lfoSpeedModulationSource.modulationSource = ModulationSource.keytrack
//    program.panningModulationSource.modulationSource = ModulationSource.lfo
    
//    program.cutoffModulationSource.modulationSource = ModulationSource.lfo
//    program.resonanceModulationSource.modulationSource = ModulationSource.lfo
//    program.volumeModulationSource.modulationSource = ModulationSource.lfo_VCAEnvelope
//    program.lfoSpeedModulationSource.modulationSource = ModulationSource.keytrack
//    program.panningModulationSource.modulationSource = ModulationSource.lfo

    
    return Program_Editor_View(program: program)
        .frame(width: 1200, height: 800)
}
