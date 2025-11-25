//
//  QuickActionsView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct QuickActionsView: View {
    @Binding var showSettings: Bool
    @Binding var showFileManager: Bool
    @Binding var requestAll: Bool
    @Binding var sendAll: Bool

    
    var body: some View {
        GroupBox {
            HStack {
                
                VStack {
                    button(for: "Get Profile", property: $requestAll, color: .orange)
                    button(for: "Send Profile", property: $sendAll, color: .purple, lightText: true)
                }

                
                VStack {
                    button(for: "Profiles", property: $showFileManager, color: .red, lightText: true)
                    button(for: "Programs", property: $showFileManager, color: .yellow)
                }

//                VStack {
//                    button(for: "Settings", property: $showSettings, color: .green)
//                    button(for: "Programs", property: $showFileManager, color: .blue, lightText: true)
//                }
                
            }
//            .padding()
        }
    }
    
    
    private func button(for title: String, property: Binding<Bool>, color: Color, lightText: Bool = false) -> some View {
        Button {
            property.wrappedValue.toggle()
        } label: {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(lightText ? .white : .black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 2))

    }
    
}


#Preview {
    @Previewable @State var showSettings: Bool = false
    @Previewable @State var showFileManager: Bool = false
    @Previewable @State var requestAll: Bool = false
    @Previewable @State var sendAll: Bool = false

    QuickActionsView(showSettings: $showSettings,
                         showFileManager: $showFileManager,
                         requestAll: $requestAll,
                         sendAll: $sendAll)
    .frame(width: 300, height: 100)
}

