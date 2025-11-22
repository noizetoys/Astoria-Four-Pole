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
//        GroupBox {
        GeometryReader { geometry in
            
            VStack{
                HStack {
                    ADSREnvelopeEditor(attack: program.vcfEnvelopeAttack,
                                       decay: program.vcfEnvelopeDecay,
                                       sustain: program.vcfEnvelopeSustain,
                                       release: program.vcfEnvelopeRelease)
                    .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))


                    LowPassFilterEditor(program: program)
                        .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))
                }
                
                HStack {
                    ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
                                       decay: program.vcaEnvelopeDecay,
                                       sustain: program.vcaEnvelopeSustain,
                                       release: program.vcaEnvelopeRelease)
                        .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))

                    LFOAnimationView(lfoSpeed: program.lfoSpeed, lfoShape: program.lfoShape)
                        .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))

                }
                
                HStack {
//                    Color.blue
//                        .cornerRadius(10)
//                        .overlay {
//                            Text(intThatThing(geometry, width: 3, height: 3))
//                        }
                    MIDIMonitorView(editorViewModel: editorViewModel)

                    
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
}
