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
import SwiftUI


struct MainView: View {
    @State private var viewModel: MainViewModel
    
//    @State private var showConnections: Bool = false
//    @State private var showSettings: Bool = false
    
    @State var newProgram: Bool = false
    @State var sendProgram: Bool = false
    @State var requestProgram: Bool = false
    @State var newProfile: Bool = false
    @State var sendProfile: Bool = false
    @State var requestProfile: Bool = false
    @State var showConnectionsBox: Bool = false
    

    @Binding var deviceProfile: MiniworksDeviceProfile
    

    private func columnWidth(from proxy: GeometryProxy) -> CGFloat {
        proxy.size.width / 5
    }
    
    
    private func rowHeight(from proxy: GeometryProxy) -> CGFloat {
        proxy.size.height / 3
    }
    
    
    // MARK: - Lifecycle
    
    init(deviceProfile: Binding<MiniworksDeviceProfile>) {
        viewModel = MainViewModel(profile: deviceProfile.wrappedValue)
        self._deviceProfile = deviceProfile
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            
            HStack {
                
                    // Left Side Controls
                VStack {
                    
                    Button {
                        showConnectionsBox.toggle()
                    } label: {
                        VStack {
                            HStack {
                                Text("Connections")
                                
//                                Image(systemName: "gear")
                            }
                            .font(.title2)
                            .bold()

                            HStack {
                                Circle()
                                    .fill(viewModel.isConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                
                                Text(viewModel.statusMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top)
                    }
                    .frame(maxHeight: rowHeight(from: geometry) / 4)
                    .padding(.horizontal, 10)
                    .popover(isPresented: $showConnectionsBox, arrowEdge: .trailing) {
                        ConnectionsBox(viewModel:  $viewModel,
                                       showConnectionsBox: $showConnectionsBox)
                            .padding()
                    }
                    
                        // Programs
                    Program_Matrix(viewModel: viewModel)
                        .padding([.horizontal, .bottom], 10)
                }
                
                
                VStack {
                    HStack {
                        GroupBox {
                            Program_Title_View(viewModel: viewModel)
                        }
                        .background(.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        GroupBox {
                            QuickActionsView(newProgram: $newProgram,
                                             sendProgram: $sendProgram,
                                             requestProgram: $requestProgram,
                                             newProfile: $newProfile,
                                             sendProfile: $sendProfile,
                                             requestProfile: $requestProfile)
                        }
                        .background(.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    // Width = 1/5, height = 1/3
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
                
            } // Stack
        } // Geometry
        .navigationTitle("Profile Name - Edited")
    }
    
}



#Preview {
    @Previewable @State var deviceProfile = MiniworksDeviceProfile.newMachineConfiguration()
    
    MainView(deviceProfile: $deviceProfile)
        .frame(width: 1200, height: 800)
}
