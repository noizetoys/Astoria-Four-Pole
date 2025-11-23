//
//  VCF Editor View.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

struct VCF_Editor_View: View {
    var program: MiniWorksProgram
    
    var body: some View {
        GeometryReader { geometry in
            GroupBox {
                Text("Voltage Controlled Filter")
                    .bold()
                
                HStack {
                    ADSREnvelopeEditor(attack: program.vcfEnvelopeAttack,
                                       decay: program.vcfEnvelopeDecay,
                                       sustain: program.vcfEnvelopeSustain,
                                       release: program.vcfEnvelopeRelease)
//                                .frame(maxWidth: cut(geometry, by: 1/3))
                                .padding(.top, 30)
                    
                    
                    Modulation_Destination_View()
                        .frame(maxWidth: geometry.size.width / 5)
                }
            }
        }
            
    }
}


#Preview {
    @Previewable @State var progam: MiniWorksProgram = MiniWorksProgram()
    
    VCF_Editor_View(program: progam)
}
