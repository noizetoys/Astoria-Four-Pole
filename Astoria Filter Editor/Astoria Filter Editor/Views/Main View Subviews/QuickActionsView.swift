//
//  QuickActionsView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct QuickActionsView: View {
//    @Binding var showSettings: Bool
//    @Binding var showFileManager: Bool
    
    @Binding var newProgram: Bool
    @Binding var sendProgram: Bool
    @Binding var requestProgram: Bool
    
    @Binding var newProfile: Bool
    @Binding var sendProfile: Bool
    @Binding var requestProfile: Bool

    
    var body: some View {
        HStack {
            button(for: "New\nProgram", property: $newProgram, color: .red.opacity(0.8), lightText: true)
            button(for: "Send\nProgram", property: $sendProgram, color: .red.opacity(0.8), lightText: true)
            button(for: "Receive\nProgram", property: $requestProgram, color: .red.opacity(0.8), lightText: true)
            
            button(for: "New\nProfile", property: $newProfile, color: .blue.opacity(0.9), lightText: true)
            button(for: "Send\nProfile", property: $sendProfile, color: .blue.opacity(0.9), lightText: true)
            button(for: "Receive\nProfile", property: $requestProfile, color: .blue.opacity(0.9), lightText: true)
            
        }
        
    }
    
    
    private func button(for title: String, property: Binding<Bool>, color: Color, lightText: Bool = false) -> some View {
        Button {
            property.wrappedValue.toggle()
        } label: {
            Text(title)
                .font(.headline)
                .bold()
                .foregroundStyle(lightText ? .white : .black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 2))

    }
    
}


#Preview {
    @Previewable @State var newProgram: Bool = false
    @Previewable @State var sendProgram: Bool = false
    @Previewable @State var requestProgram: Bool = false
    @Previewable @State var newProfile: Bool = false
    @Previewable @State var sendProfile: Bool = false
    @Previewable @State var requestProfile: Bool = false

    QuickActionsView(newProgram: $newProgram,
                     sendProgram: $sendProgram,
                     requestProgram: $requestProgram,
                     newProfile: $newProfile,
                     sendProfile: $sendProfile,
                     requestProfile: $requestProfile)
    .frame(width: 480, height: 67)
    .background(.gray.opacity(0.3))

}

