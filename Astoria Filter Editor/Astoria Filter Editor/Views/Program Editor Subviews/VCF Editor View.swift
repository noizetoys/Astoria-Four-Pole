//
//  VCF Editor View.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

struct VCF_Editor_View: View {
    var program: MiniWorksProgram
    let showControls: Bool
    
    
    var body: some View {
        GroupBox {
            
            VStack {
                Text("Voltage Controlled Filter")
                    .bold()
                
                ADSREnvelopeEditor(attack: program.vcfEnvelopeAttack,
                                   decay: program.vcfEnvelopeDecay,
                                   sustain: program.vcfEnvelopeSustain,
                                   release: program.vcfEnvelopeRelease)
                .padding(.vertical)
                
                
                if showControls {
                    ADSR_Controls_View(attack: program.vcfEnvelopeAttack,
                                       decay: program.vcfEnvelopeDecay,
                                       sustain: program.vcfEnvelopeSustain,
                                       release: program.vcfEnvelopeRelease,
                                       size: 40)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
}


#Preview {
    @Previewable @State var progam: MiniWorksProgram = MiniWorksProgram()
    
    VStack {
        VCF_Editor_View(program: progam, showControls: true)
//            .frame(maxHeight: 267)

        VCF_Editor_View(program: progam, showControls: false)
//            .frame(maxHeight: 267)

    }
    .frame(maxWidth: 400, maxHeight: .infinity)
    
}
