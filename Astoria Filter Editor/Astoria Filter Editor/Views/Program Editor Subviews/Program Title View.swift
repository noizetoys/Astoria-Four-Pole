//  Program Title View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI

struct Program_Title_View: View {
    let program: MiniWorksProgram?
    
    // TODO: Add 'tags' to Program
    let sampleTags = ["Guitar", "Compressed", "Bright"]
    
    private var programText: String {
        guard let program else { return "No Program Selected"}
        
        return "[\(program.programNumber)] \(program.programName)"
    }
    
    
    init(program: MiniWorksProgram?) {
        self.program = program
    }
    
    
    
    var programNameView: some View {
        HStack {
            Text(programText)
                .font(.title)
            
            if program != nil {
                Text("- Edited")
                    .font(.title)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var tagsView: some View {
        if program != nil {
            HStack {
                ForEach(sampleTags, id: \.self) { tag in
                    tagView(for: tag)
                }
                Spacer()
            }
        }
        else {
            EmptyView()
        }
    }
    
    
    
    var body: some View {
        HStack(spacing: 0) {
                // Top
            VStack {
                programNameView
                
                tagsView
                
                Spacer()
            }
            
                // Buttons (Reset/Save)
            HStack(spacing: 20) {
                    //                    bigButton("Save", color: .blue)
                    //                    bigButton("Cancel", color: .red)
                bigButton("Compare", color: .green)
            }
            
        } // VStack
    }
    
    
    func bigButton(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title3)
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
            .padding(.vertical, 5)
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
            .frame(maxWidth: 600, maxHeight: 100)
//            .frame(maxWidth: proxy.size.width * (4/5), maxHeight: proxy.size.height * 1/6)
    }
}
