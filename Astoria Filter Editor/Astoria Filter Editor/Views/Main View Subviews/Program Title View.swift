//  Program Title View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI

struct Program_Title_View: View {
    let viewModel: MainViewModel
    
    @State private var canComparePrograms: Bool = false
    @State private var programIsEdited: Bool = false
    

    // TODO: Add 'tags' to Program
    private var programText: String {
        guard
            let program = viewModel.program
        else { return "No Program Selected"}
        
        // Uses zero index, device is 1 index
        let programNumber = program.programNumber + 1
        let name = programNumber > 20
        ? "ROM Program #\(programNumber)"
        : program.programName
        
        return "[\(programNumber)] \(name)"
    }
    
    
    var programNameView: some View {
        HStack {
            Text(programText)
                .font(.title)
            
            if programIsEdited {
                Text("- Edited")
                    .font(.title)
                    .italic()
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
    }

    
    // MARK: - Lifecycle
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                programNameView
                
                tagsView
                
            }
            .padding(.leading)
            
            HStack {
                bigButton("Compare", color: .green)
            }
            
        }
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
        if viewModel.program != nil {
            HStack {
                ForEach(viewModel.program?.tags ?? [], id: \.self) { tag in
                    ProgramTagView(tagItem: tag)
                }
                Spacer()
            }
        }
        else { EmptyView() }
    }

}


#Preview {
    Program_Title_View(viewModel: MainViewModel(profile: MiniworksDeviceProfile.newMachineConfiguration()))
            .frame(width: 480, height: 67)
            .background(.gray.opacity(0.3))
            .padding()
}
