//
//  ADSR Controls View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/24/25.
//

import SwiftUI

struct ADSR_Controls_View: View {
    var attack: ProgramParameter
    var decay: ProgramParameter
    var sustain: ProgramParameter   // level (vertical)
    var release: ProgramParameter
    
    let size: CGFloat
    
    
    var body: some View {
        HStack(spacing: size) {
            ZStack {
                VStack(alignment: .center, spacing: 10) {
                    CircularFader(value: attack.knobBinding,
                                  size: size,
                                  mode: .unidirectional(color: ADSRStageColors.attack),
                                  primaryColor: ADSRStageColors.attack)
//                    Text("Attack")
                }
                
            }
            
            VStack(alignment: .center, spacing: 10) {
                    //                    Text("\(decay.value)")
                CircularFader(value: decay.knobBinding,
                              size: size,
                              mode: .unidirectional(color: ADSRStageColors.decay),
                              primaryColor: ADSRStageColors.decay)
//                Text("Decay")
//                    .foregroundStyle(ADSRStageColors.decay)
            }
            
            VStack(alignment: .center, spacing: 10) {
                    //                    Text("\(sustain.value)")
                CircularFader(value: sustain.knobBinding,
                              size: size,
                              mode: .unidirectional(color: ADSRStageColors.sustain),
                              primaryColor: ADSRStageColors.sustain)
//                Text("Sustain")
//                    .foregroundStyle(ADSRStageColors.sustain)
            }
            
            VStack(alignment: .center, spacing: 10) {
                    //                    Text("\(release.value)")
                CircularFader(value: release.knobBinding,
                              size: size,
                              mode: .unidirectional(color: ADSRStageColors.release),
                              primaryColor: ADSRStageColors.release)
//                Text("Release")
//                    .foregroundStyle(ADSRStageColors.release)
            }
            
        }
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var program: MiniWorksProgram = .init()
    
    ADSR_Controls_View(attack: program.vcfEnvelopeAttack,
                       decay: program.vcfEnvelopeDecay,
                       sustain: program.vcfEnvelopeSustain,
                       release: program.vcfEnvelopeRelease,
                       size: 40)
    .frame(maxHeight: 80)
    
}
