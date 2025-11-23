//
//  VCA Editor View.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

struct VCA_Editor_View: View {
    var program: MiniWorksProgram
    
    
    var body: some View {
        GeometryReader { geometry in
            
            GroupBox {
                Text("Voltage Controlled Amplifier")
                    .bold()
                
                HStack {
                    ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
                                       decay: program.vcaEnvelopeDecay,
                                       sustain: program.vcaEnvelopeSustain,
                                       release: program.vcaEnvelopeRelease)
                    //            .frame(maxWidth: cut(geometry, by: 1/3))
                                .padding(.top, 30)
                    
                    
                    Modulation_Destination_View(type: .vcaEnvelope)
                        .frame(maxWidth: geometry.size.width / 5)
                }
            }
        }
        
    }
}


#Preview {
    @Previewable @State var progam: MiniWorksProgram = MiniWorksProgram()
    
    VCA_Editor_View(program: progam)
}
