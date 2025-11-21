//
//  Patch Editor View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct Patch_Editor_View: View {
    @Binding var program: MiniWorksProgram
    
    
    var body: some View {
        GroupBox {
            
            VStack{
                HStack {
//                    ADSREnvelopeEditor(attack: program.vcfEnvelopeAttack,
//                                       decay: program.vcfEnvelopeDecay,
//                                       sustain: program.vcfEnvelopeSustain,
//                                       release: program.vcfEnvelopeRelease)
                    LFOAnimationView(lfoSpeed: program.lfoSpeed, lfoShape: program.lfoShape)

                    LowPassFilterEditor(program: program)
                }
                
                HStack {
                    
                    ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
                                       decay: program.vcaEnvelopeDecay,
                                       sustain: program.vcaEnvelopeSustain,
                                       release: program.vcaEnvelopeRelease)
                    
                    LFOAnimationView(lfoSpeed: program.lfoSpeed, lfoShape: program.lfoShape)
                    
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
