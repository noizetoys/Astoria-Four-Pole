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
    @State private var viewModel = MainViewModel()
    
    @State private var showConnections: Bool = false
    @State private var showGlobals: Bool = false
//    @State private var showROMPrograms: Bool = false

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
                    Program_Matrix(viewModel: viewModel)
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
                    if let program = viewModel.program {
                        GroupBox {
                            Program_Editor_View(program: program)
                        }
                    }
                    else {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.blue.opacity(0.5))
                            .overlay {
                                Text("Select a program to edit")
                                    .font(.title)
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
        }
        
    }
    
    
}



#Preview {
    MainView()
        .frame(width: 1200, height: 800)
}
