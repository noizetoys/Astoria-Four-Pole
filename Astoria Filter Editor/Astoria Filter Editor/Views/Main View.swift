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
    
    @State private var showConnections: Bool = false
    @State private var showSettings: Bool = false
    
    @State private var showFileManager: Bool = false
    @State private var requestAll: Bool = false
    @State private var sendAll: Bool = false

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
                    GroupBox {
                        ConnectionsBox(viewModel:  $viewModel)
                    }
                    .padding(.horizontal)
                    
                    
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
                        .background(.gray.opacity(05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        GroupBox {
                            QuickActionsView(showSettings: $showSettings,
                                                 showFileManager: $showFileManager,
                                                 requestAll: $requestAll,
                                                 sendAll: $sendAll)
                                .frame(maxWidth: columnWidth(from: geometry))
                        }
                        .background(.gray.opacity(05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .frame(width: columnWidth(from: geometry) * 4, height: rowHeight(from: geometry) / 4)
//                    .background(.gray.opacity(05))
//                    .clipShape(RoundedRectangle(cornerRadius: 10))

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
    }
    
}



#Preview {
    @Previewable @State var deviceProfile = MiniworksDeviceProfile.newMachineConfiguration()
    
    MainView(deviceProfile: $deviceProfile)
        .frame(width: 1200, height: 800)
}
