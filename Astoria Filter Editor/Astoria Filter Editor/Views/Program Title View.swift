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
    
    
    var programNameView: some View {
        HStack {
            Text("[\(program.programNumber)] \(program.programName)")
                .font(.title)
            
            Text("- Edited")
                .font(.title)
                .foregroundStyle(.gray)
            
            Spacer()
        }
    }
    
    
    var tagsView: some View {
        HStack {
            ForEach(sampleTags, id: \.self) { tag in
                tagView(for: tag)
            }
            Spacer()
        }
    }
    
    
    
    var body: some View {
        GroupBox {
            
            HStack(spacing: 0) {
                    // Top
                VStack {
                    programNameView
                     
                        // Tags
                    tagsView
                    
                    Spacer()
                }
                
                    // Buttons (Reset/Save)
                HStack(spacing: 20) {
                    bigButton("Save", color: .blue)
                    bigButton("Cancel", color: .red)
                    bigButton("Compare", color: .green)
                }
                
            } // VStack
            
        } // GroupBox
    }
    
    
    func bigButton(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title)
            .bold()
            .padding(.horizontal)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
            )
            .frame(maxHeight: .infinity)
    }
    
    
    private func tagView(for text: String) -> some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.footnote)
            .bold()
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(.red)
            )
        
    }
    
}


#Preview {
    GeometryReader { proxy in
        Program_Title_View(program: MiniWorksProgram())
            .frame(maxWidth: proxy.size.width * (4/5), maxHeight: proxy.size.height * 1/6)
    }
}
