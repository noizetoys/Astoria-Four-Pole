//
//  Gate Trigger View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/24/25.
//

import SwiftUI


struct Gate_Trigger_View: View {
    let program: MiniWorksProgram
    
    
    var body: some View {
        GroupBox {
            
            VStack {
                Text("GateTime")
                
                Slider(value: program.gateTime.doubleBinding, in: 0...127)
                    .padding(.horizontal, 10)
                    .padding(.bottom)

                Text("Trigger")
                    .frame(maxWidth: .infinity)
                
                Picker("Source", selection: program.triggerSource.triggerSourceBinding) {
                    ForEach(TriggerSource.allCases, id: \.self) { source in
                        Text(source.name)
                            .tag(source.rawValue)
                        
                    }
                }
                .padding(.bottom)
                
                Picker("Mode", selection: program.triggerMode.triggerModeBinding) {
                    ForEach(TriggerMode.allCases, id: \.self) { mode in
                        Text(mode.name)
                            .tag(mode.rawValue)
                    }
                }
                
            } // VStack
            .frame(maxHeight: .infinity)
        }
    }
    
}


#Preview {
    @Previewable @State var program: MiniWorksProgram = .init()
    
    Gate_Trigger_View(program: program)
        .frame(maxWidth: 200, maxHeight: 200)
}
