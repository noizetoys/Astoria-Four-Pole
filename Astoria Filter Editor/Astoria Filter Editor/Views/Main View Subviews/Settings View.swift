//
//  Settings View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import SwiftUI

struct Settings_View: View {
    let globalData: MiniWorksGlobalData
    
    @State private var autoConnectMIDI: Bool = false
    @State private var sendProgramChangeOnSelect: Bool = false
    @State private var requestProgramChangeOnSelect: Bool = false

    
    
    var body: some View {
        VStack {
//            Globals_View(globals: globalData)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)

//            GroupBox {
//                Toggle(isOn: $autoConnectMIDI) {
//                    Text("Auto-Connect MIDI")
//                }
//                
//                Toggle(isOn: $sendProgramChangeOnSelect) {
//                    Text("Send Program Change")
//                }
//                
//                Toggle(isOn: $requestProgramChangeOnSelect) {
//                    Text("Request pro Program Change")
//                }
//            }
            
        }
    }
    
}


#Preview {
    @Previewable @State var globalData: MiniWorksGlobalData = .init()
    
    Settings_View(globalData: globalData)
}
