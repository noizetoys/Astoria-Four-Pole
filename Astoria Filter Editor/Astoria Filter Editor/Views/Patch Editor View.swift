//
//  Patch Editor View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct Patch_Editor_View: View {
    @Binding var program: MiniWorksProgram
    
    private func intThatThing(_ proxy: GeometryProxy, width wD: Int, height hD: Int) -> String {
        "Size for:\n 1/\(wD) width: \(Int(proxy.size.width) / wD), 1/\(hD) height: \(Int(proxy.size.height) / hD)"
    }
    
    var body: some View {
//        GroupBox {
        GeometryReader { geometry in
            
            VStack{
                HStack {
                    Color.red
                        .cornerRadius(10)
                        .overlay {
                            Text(intThatThing(geometry, width: 2, height: 3))
                        }
                    
                    Color.orange
                        .cornerRadius(10)
                        .overlay {
                            Text(intThatThing(geometry, width: 2, height: 3))
                        }

//                    ADSREnvelopeEditor(attack: program.vcfEnvelopeAttack,
//                                       decay: program.vcfEnvelopeDecay,
//                                       sustain: program.vcfEnvelopeSustain,
//                                       release: program.vcfEnvelopeRelease)

//                    LowPassFilterEditor(program: program)
                }
                
                HStack {
                    Color.yellow
                        .cornerRadius(10)
                        .overlay {
                            Text(intThatThing(geometry, width: 2, height: 3))
                        }

                    
                    Color.green
                        .cornerRadius(10)
                        .overlay {
                            Text(intThatThing(geometry, width: 2, height: 3))
                        }


//                    ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
//                                       decay: program.vcaEnvelopeDecay,
//                                       sustain: program.vcaEnvelopeSustain,
//                                       release: program.vcaEnvelopeRelease)
                    
//                    LFOAnimationView(lfoSpeed: program.lfoSpeed, lfoShape: program.lfoShape)
                    
                }
                
                HStack {
                    Color.blue
                        .cornerRadius(10)
                        .overlay {
                            Text(intThatThing(geometry, width: 3, height: 3))
                        }

                    
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

//                HStack {
//                    ADSREnvelopeEditor(attack: program.vcfEnvelopeAttack,
//                                       decay: program.vcfEnvelopeDecay,
//                                       sustain: program.vcfEnvelopeSustain,
//                                       release: program.vcfEnvelopeRelease)
//                    
//                    ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
//                                       decay: program.vcaEnvelopeDecay,
//                                       sustain: program.vcaEnvelopeSustain,
//                                       release: program.vcaEnvelopeRelease)
//                    
//                }
            }
//            RoundedRectangle(cornerRadius: 8)
//                .foregroundStyle(.yellow)
        }
    }
}


#Preview {
    @Previewable @State var program = MiniWorksProgram()
    
    Patch_Editor_View(program: $program)
}
