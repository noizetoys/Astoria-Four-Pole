//
//  Program Matrix.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI


    /// Holds a single Program
struct ProgramCellView: View {
    let program: MiniWorksProgram
    let backgroundColor: Color
    
    
    var body: some View {
        VStack(alignment: .center) {
            Text("\(program.programNumber)")
                //                .font(.title3)
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
    var viewModel: EditorViewModel
    
    private let columnCount = 2
    private let rowCount = 10

    private let backgroundColor: Color = .white
    private let borderColor: Color = .gray
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 1), count: columnCount)
    }
    
    private var rows: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 2), count: rowCount)
    }

    
    var isROMPrograms: Bool
    
    private var programs: [MiniWorksProgram] {
        isROMPrograms ? viewModel.ROMPrograms : viewModel.programs
    }
    
    private var programTitle: String {
        isROMPrograms ? "ROM Programs" : "User Programs"
    }
    
    private var programSubtitle: String {
        isROMPrograms ? "Tap to select a Program" : "Tap to select a Program to edit"
    }
    
    
    private var cellColor: Color {
        isROMPrograms ? .gray.opacity(0.3) : .white
    }


    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 0) {
                Text(programTitle)
                    .font(.headline)
                    .foregroundStyle(.black)
                
                Text(programSubtitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
                
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
            }
            .frame(maxWidth: .infinity)
        }
        
    }
    
    
    private func row(range: Range<Int>) -> some View {
        GridRow {
            ForEach(range, id: \.self) { num in
                ProgramCellView(program: programs[num], backgroundColor: cellColor)
                    .onTapGesture {
                        viewModel.requestLoadProgram(num, isROM: isROMPrograms)
                    }
            }
            
        }
    }
    
}


#Preview {
    @Previewable @State var vm: EditorViewModel = .init()
    
    VStack {
        Program_Matrix(viewModel: vm, isROMPrograms: false)
//        Program_Matrix(viewModel: vm, isROMPrograms: true)
            //    ProgramCellView(program: $vm.program)
    }
}
