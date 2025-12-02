//
//  Program Editor View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI


struct Program_Editor_View: View {
    var program: MiniWorksProgram
    @Binding var showInfoOverlay: Bool
    
    
    init(program: MiniWorksProgram?, showInfoOverlay overlay: Binding<Bool>) {
        self._showInfoOverlay = overlay
        
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
            .overlay {
                if showInfoOverlay {
                    VCFViewOverlay()
                }
            }

            
            LPF_Editor_View(program: program)
                .overlay {
                    if showInfoOverlay {
                        LowPassFilterViewOverlay()
                    }
                }

        }
        
    }
    
    
    private func bottomViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            MIDIMonitorView()
                .frame(maxWidth: geometry.size.width * (1/3))
                .overlay {
                    if showInfoOverlay {
                        EnvelopeMonitorViewOverlay()
                    }
                }

            
            GroupBox {
                LFOAnimationView(program: program)
            }
            .background(Color.blue.opacity(0.2))
            .overlay {
                if showInfoOverlay {
                    LFOViewOverlay()
                }
            }

            
            
            Modulation_Destination_View(program: program)
                .frame(maxWidth: geometry.size.width * (1/6))
                .overlay {
                    if showInfoOverlay {
                        ModulationSourcesViewOverlay()
                    }
                }
        }
        
    }
    
    
    private func middleViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            VCA_Editor_View(program: program, showControls: true)
                .overlay {
                    if showInfoOverlay {
                        VCAViewOverlay()
                    }
                }

            Volume_Editor(program: program)
                .overlay {
                    if showInfoOverlay {
                        VolumeViewOverlay()
                    }
                }

            Pan_Editor(program: program)
                .frame(maxWidth: cut(geometry, by: 1/3))
                .overlay {
                    if showInfoOverlay {
                        PanningViewOverlay()
                    }
                }

        }
    }
    
}


#Preview {
//    @Previewable @State var editorViewModel = EditorViewModel()
    @Previewable @State var program = MiniWorksProgram()
    @Previewable @State var overlay: Bool = false
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

    
    return Program_Editor_View(program: program, showInfoOverlay: $overlay)
        .frame(width: 1200, height: 800)
}
