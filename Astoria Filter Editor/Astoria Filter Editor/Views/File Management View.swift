//
//  File Management View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct File_Management_View: View {
    var body: some View {
        GroupBox {
            HStack {
                
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        //                                        .foregroundStyle(.orange)
                        .overlay(
                            Text("Configuration")
                                .foregroundStyle(.black)
                        )
                    
                    RoundedRectangle(cornerRadius: 8)
                        //                                        .foregroundStyle(.blue)
                        .overlay(
                            Text("Patches")
                                .foregroundStyle(.black)
                        )
                    
                }
//                .frame(width: columnWidth(from: geometry) / 2)
                .frame(maxHeight: .infinity)
                
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        //                                        .foregroundStyle(.orange)
                        .overlay(
                            Text("File Manager")
                                .foregroundStyle(.black)
                        )
                    
                    RoundedRectangle(cornerRadius: 8)
                        //                                        .foregroundStyle(.blue)
                        .overlay(
                            Text("Settings")
                                .foregroundStyle(.black)
                        )
                    
                }
//                .frame(width: columnWidth(from: geometry) / 2)
                .frame(maxHeight: .infinity)
                
            }
        }    }
}

#Preview {
    File_Management_View()
}
