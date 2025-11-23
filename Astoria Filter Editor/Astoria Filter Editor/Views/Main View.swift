//
//  ContentView.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/8/25.
//

import SwiftUI


// Settings
// File manager
// Program editor
// Device Profile (Programs & Globals)
//




struct MainView: View {
    @State private var viewModel = EditorViewModel()
    @State private var program: Int = 0
    
    @State private var showConnections: Bool = false
    @State private var showGlobals: Bool = false
    @State private var showROMPrograms: Bool = false

    private func columnWidth(from proxy: GeometryProxy) -> CGFloat {
        proxy.size.width / 5
    }
    
    private func rowHeight(from proxy: GeometryProxy) -> CGFloat {
        proxy.size.height / 3
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                
                // Left Side Controls
                VStack {
                    Button {
                        withAnimation {
                            showConnections.toggle()
                        }
                    } label: {
                        Text("Connections")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding([.horizontal, .top])

                    if showConnections {
                        GroupBox {
                            ConnectionsBox(viewModel:  $viewModel)
                        }
                        .padding(.horizontal)
                    }

                    
                    // Globals
                    Button {
                        withAnimation {
                            showGlobals.toggle()
                        }
                    } label: {
                        Text("Globals")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding([.horizontal, .top])
                    
                    if showGlobals {
                        GroupBox {
                            Globals_View(globals: viewModel.configuration.globalSetup)
                        }
                        .padding(.horizontal)
                    }
                    
                    
                        // Programs
                    Button {
                        withAnimation {
                            showROMPrograms.toggle()
                        }
                    } label: {
                        Text("Show \(showROMPrograms ? "User" : "ROM") Programs")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding()
                    
                    
                    Program_Matrix(viewModel: viewModel, isROMPrograms: showROMPrograms)
                        .frame(maxHeight: rowHeight(from: geometry) * 2.5)
                        .padding([.horizontal, .bottom])
                }
                
                
                VStack {
                        HStack {
                            GroupBox {
                                Program_Title_View(program: viewModel.program)
                            }
                            
                            GroupBox {
                                File_Management_View()
                                    .frame(maxWidth: columnWidth(from: geometry))
                            }
                    }
                    .frame(width: columnWidth(from: geometry) * 4, height: rowHeight(from: geometry) / 4)
                    
                        // Edit View
                    GroupBox {
                        Program_Editor_View(editorViewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
        }
        
    }
    
    
    func slider(for parameter: ProgramParameter) -> some View {
        Slider(value: parameter.doubleBinding, in: parameter.doubleRange, step: 1) {
            Text("Current Value: \(parameter.value)")
        } onEditingChanged: { isEditing in
            viewModel.updateCC(from: parameter)
        }
    }
    
    
    var programChangeStepper: some View {
        Stepper(value: $program, in: 0...39, step: 1) {
            Text("Current Value: \(program + 1)")
        } onEditingChanged: { isEditing in
            viewModel.selectProgram(program)
        }
    }
    
}



#Preview {
    MainView()
        .frame(width: 1696, height: 1051)
}
