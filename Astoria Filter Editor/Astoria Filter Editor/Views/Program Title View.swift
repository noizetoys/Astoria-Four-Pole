//  Program Title View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI

struct Program_Title_View: View {
    let program: MiniWorksProgram
    
    // TODO: Add 'tags' to Program
    let sampleTags = ["Guitar", "Compressed", "Bright"]
    
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                
                    // Top
                HStack {
                    Text("[\(program.programNumber)] \(program.programName)")
                        .font(.title)
                    
                    Text("- Edited")
                        .font(.title)
                        .foregroundStyle(.gray)
                    
                    Spacer()
                }
                .border(.black)
                
                
                    // Bottom
                HStack {
                    
                        // Tags
                    VStack(spacing: 0) {
                        HStack {
                            ForEach(sampleTags, id: \.self) { tag in
                                tagView(for: tag)
                            }
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .border(.green)
                    
                        // Buttons (Reset/Save)
                    HStack(alignment: .center) {
                        Button {
                            
                        } label: {
                            Text("Reset")
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            
                        } label: {
                            Text("Save")
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                    }
                    .border(.orange)
                    
                    
                    HStack {
                        Button {
                            
                        } label: {
                            Text("Compare")
                        }
                        .buttonStyle(.bordered)
                    }
                    .border(.purple)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                
            } // VStack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .border(.blue)
            
        } // GroupBox
        .border(.red)
        
    }
        
    
    
    private func tagView(for text: String) -> some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.footnote)
            .bold()
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(
                Capsule()
                    .foregroundStyle(.red)
            )

    }
    
}


#Preview {
    Program_Title_View(program: MiniWorksProgram())
}
