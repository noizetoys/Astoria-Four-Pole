//  Program Title View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI

struct Program_Title_View: View {
    let program: MiniWorksProgram?
    
    @State private var canComparePrograms: Bool = false
    @State private var programIsEdited: Bool = false
    

    // TODO: Add 'tags' to Program
    let sampleTags = ["Guitar", "Compressed", "Bright"]
    
    private var programText: String {
        guard let program else { return "No Program Selected"}
        
        return "[\(program.programNumber)] \(program.programName)"
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

    
    // MARK: - Lifecycle
    
    init(program: MiniWorksProgram?) {
        self.program = program
    }
    
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                programNameView
                
                tagsView
                
//                Spacer()
            }
            .padding(.leading)
            
            HStack {
                bigButton("Compare", color: .green)
            }
            
        } // VStack
    }
    

    private func bigButton(_ text: String, color: Color) -> some View {
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
    
    
    @ViewBuilder
    private var tagsView: some View {
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
        Program_Title_View(program: MiniWorksProgram())
            .frame(width: 480, height: 67)
            .background(.gray.opacity(0.3))
            .padding()
}
