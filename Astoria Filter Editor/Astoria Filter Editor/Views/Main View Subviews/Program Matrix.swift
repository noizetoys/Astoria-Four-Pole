//
//  Program Matrix.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI



enum SelectedProgramType: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case user = "User"
    case ROM = "ROM"
}



    /// Holds a single Program
struct ProgramCellView: View {
    let program: MiniWorksProgram
    let backgroundColor: Color
    
    
    var body: some View {
        VStack(alignment: .center) {
            Text("\(program.programNumber)")
                .font(.title)
                .bold()
            
            Text("Info")
                .font(.footnote)
                .foregroundStyle(.gray)
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .strokeBorder(.black.opacity(0.2))
        )
    }
    
}


struct Program_Matrix: View {
    var viewModel: MainViewModel
    
    @State private var selectedProgramType = SelectedProgramType.user
    
    var showROMPrograms: Bool { selectedProgramType == SelectedProgramType.ROM }
    
    private var programSubtitle: String {
        showROMPrograms ? "Tap below to select a Program" : "Tap below to select a Program to edit"
    }
    
    
    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 0) {
                
                Picker("Programs:", selection: $selectedProgramType) {
                    ForEach(SelectedProgramType.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                            .font(.title)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(programSubtitle)
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .padding()
            }
            
            ButtonMatrix(viewModel: viewModel, showROMs: showROMPrograms)
        }
    }
    
}


struct ButtonMatrix: View {
    let viewModel: MainViewModel
    let showROMs: Bool
    
    
    private let columnCount = 2
    private let rowCount = 10
    private let backgroundColor: Color = .white
    private let borderColor: Color = .gray
    
    // MARK: - Calculated
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 1), count: columnCount)
    }
    
    private var rows: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 2), count: rowCount)
    }
    
    private var programs: [MiniWorksProgram] {
        showROMs ? viewModel.ROMPrograms : viewModel.programs
    }
    
    private var programTitle: String {
        showROMs ? "ROM Programs" : "User Programs"
    }
    
    private var programSubtitle: String {
        showROMs ? "Tap below to select a Program" : "Tap below to select a Program to edit"
    }
    
    
    private var cellColor: Color {
        showROMs ? .gray.opacity(0.3) : .white
    }

    
    
    var body: some View {
                
                Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                    // 2 X 10
                    row(range: 0..<2)
                    row(range: 2..<4)
                    row(range: 4..<6)
                    row(range: 6..<8)
                    row(range: 8..<10)
                    row(range: 10..<12)
                    row(range: 12..<14)
                    row(range: 14..<16)
                    row(range: 16..<18)
                    row(range: 18..<20)

                    // 4 X 10
//                    row(range: 0..<4)
//                    row(range: 4..<8)
//                    row(range: 8..<12)
//                    row(range: 12..<16)
//                    row(range: 16..<20)

            }
//            .frame(maxWidth: .infinity)
        
    }
    
    
    private func row(range: Range<Int>) -> some View {
        GridRow {
            ForEach(range, id: \.self) { num in
                ProgramCellView(program: programs[num], backgroundColor: cellColor)
                    .onTapGesture {
                        try? viewModel.requestLoadProgram(num, isROM: showROMs)
                    }
            }
            
        }
    }
}


#Preview {
    @Previewable @State var vm: MainViewModel = .init()
    
    VStack {
        Program_Matrix(viewModel: vm)
            .frame(width: 300, height: 1000)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
