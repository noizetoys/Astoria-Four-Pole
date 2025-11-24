//
//  VCA Editor View.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

struct VCA_Editor_View: View {
    var program: MiniWorksProgram
    let showControls: Bool

    
    var body: some View {
        GroupBox {
            
            VStack {
            Text("Voltage Controlled Amplifier")
                .bold()
            
                ADSREnvelopeEditor(attack: program.vcaEnvelopeAttack,
                                   decay: program.vcaEnvelopeDecay,
                                   sustain: program.vcaEnvelopeSustain,
                                   release: program.vcaEnvelopeRelease)
                .padding(.vertical)
                
                
                if showControls {
                    ADSR_Controls_View(attack: program.vcaEnvelopeAttack,
                                       decay: program.vcaEnvelopeDecay,
                                       sustain: program.vcaEnvelopeSustain,
                                       release: program.vcaEnvelopeRelease,
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
        VCA_Editor_View(program: progam, showControls: true)
//            .frame(maxHeight: 267)
        
        VCA_Editor_View(program: progam, showControls: false)
//            .frame(maxHeight: 267)
    }
    .frame(maxWidth: 400, maxHeight: .infinity)
}
