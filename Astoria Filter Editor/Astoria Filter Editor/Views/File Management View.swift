//
//  File Management View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct File_Management_View: View {
    var body: some View {
//        GroupBox {
            HStack {
                
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .overlay(
                            Text("Something")
                                .foregroundStyle(.black)
                        )
                    
                    RoundedRectangle(cornerRadius: 8)
                        .overlay(
                            Text("Something Else")
                                .foregroundStyle(.black)
                        )
                    
                } // VStack

                
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .overlay(
                            Text("Configuration")
                                .foregroundStyle(.black)
                        )
                    
                    RoundedRectangle(cornerRadius: 8)
                        .overlay(
                            Text("Patches")
                                .foregroundStyle(.black)
                        )
                    
                } // VStack

                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .overlay(
                            Text("File Manager")
                                .foregroundStyle(.black)
                        )
                    
                    RoundedRectangle(cornerRadius: 8)
                        .overlay(
                            Text("Settings")
                                .foregroundStyle(.black)
                        )
                    
                } // VStack
                
            } // HStack
//        }
    }
    
}


#Preview {
    File_Management_View()
}
