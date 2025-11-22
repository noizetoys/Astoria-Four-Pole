//
//  Patch Editor View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct Patch_Editor_View: View {
//    @Binding var program: MiniWorksProgram
    var editorViewModel: EditorViewModel
    
    private var program: MiniWorksProgram { editorViewModel.program }

    
        // For Debugging
    private func intThatThing(_ proxy: GeometryProxy, width wD: Int, height hD: Int) -> String {
        "Size for \(proxy.size):\n 1/\(wD) width: \(Int(proxy.size.width) / wD), 1/\(hD) height: \(Int(proxy.size.height) / hD)"
    }
    
    
    private func cut(_ proxy: GeometryProxy, by div: CGFloat, isWidth: Bool = true) -> CGFloat {
        let value = isWidth ? proxy.size.width : proxy.size.height
        return value/div
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            
            VStack{
                HStack {
                    ADSREnvelopeEditor(attack: program.vcfEnvelopeAttack,
                                       decay: program.vcfEnvelopeDecay,
                                       sustain: program.vcfEnvelopeSustain,
                                       release: program.vcfEnvelopeRelease)
                    .frame(maxWidth: cut(geometry, by: 3))

                    LPF_Editor_View(program: program)
//                        .frame(maxWidth: cut(geometry, by: (3/5)))
                }
//                .frame(maxHeight: cut(geometry, by: 3, isWidth: false))

                
                
                
                HStack {
//                    ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
//                                       decay: program.vcaEnvelopeDecay,
//                                       sustain: program.vcaEnvelopeSustain,
//                                       release: program.vcaEnvelopeRelease)
//                    .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))
                    MIDIMonitorView(editorViewModel: editorViewModel)
                        .frame(maxWidth: geometry.size.width * (1/3))

                    GroupBox {
                        LFOAnimationView(lfoSpeed: program.lfoSpeed, lfoShape: program.lfoShape)
                    }
                    .background(Color.purple.opacity(0.2))
//                        .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))
//                        .frame(maxWidth: cut(geometry, by: (3/5)))

//                    Color.red
//                        .cornerRadius(10)
//                        .overlay {
//                            Text(intThatThing(geometry, width: 3, height: 3))
//                        }
//                    Color.red
//                        .cornerRadius(10)
//                        .overlay {
//                            Text(intThatThing(geometry, width: 3, height: 3))
//                        }
                    
                }
                .frame(maxHeight: cut(geometry, by: 3, isWidth: false))
                
                
                
                
                HStack {
                        //                    Color.blue
                        //                        .cornerRadius(10)
                        //                        .overlay {
                        //                            Text(intThatThing(geometry, width: 3, height: 3))
                        //                        }
//                    MIDIMonitorView(editorViewModel: editorViewModel)
                                            ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
                                                               decay: program.vcaEnvelopeDecay,
                                                               sustain: program.vcaEnvelopeSustain,
                                                               release: program.vcaEnvelopeRelease)
                                            .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))

                    
                    Color.indigo
                        .cornerRadius(10)
                        .overlay {
                            Text(intThatThing(geometry, width: 3, height: 3))
                        }
                    
                    
                    Color.purple
                        .cornerRadius(10)
                        .overlay {
                            Text(intThatThing(geometry, width: 3, height: 3))
                        }
                    
                }
                
            }
        }
    }
}


#Preview {
    @Previewable @State var editorViewModel = EditorViewModel()
        //    @Previewable @State var program = MiniWorksProgram()
    
    Patch_Editor_View(editorViewModel: editorViewModel)
        .frame(width: 1200, height: 800)
}
