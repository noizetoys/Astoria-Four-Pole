//
//  ConnectionsBox.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/18/25.
//

import SwiftUI

struct ConnectionsBox: View {
    @Binding var viewModel: EditorViewModel
    
    
    var body: some View {
//        GroupBox() {
            VStack(alignment: .leading) {
                
                HStack {
                    
                    // Left side
                    VStack {
                        // Source selection
                        Text("Input:")
                        
                        Picker("", selection: $viewModel.selectedSource) {
                            Text("None").tag(nil as MIDIDevice?)
                            
                            ForEach(viewModel.availableSources) { device in
                                Text(device.name)
                                    .tag(device as MIDIDevice?)
                            }
                        }
                        
                        // Connection Button
                        Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                            Task {
                                if viewModel.isConnected {
                                    await viewModel.disconnect()
                                } else {
                                    await viewModel.connect()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    
                    
                    VStack {
                        Text("Output:")
                        
                        Picker("", selection: $viewModel.selectedDestination) {
                            Text("None").tag(nil as MIDIDevice?)
                            
                            ForEach(viewModel.availableDestinations) { device in
                                Text(device.name).tag(device as MIDIDevice?)
                            }
                        }
                        
                        // Connections
                        Button("Refresh") {
                            Task { await viewModel.refreshDevices() }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Status
                HStack {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
//        }
    }
}



#Preview {
    @Previewable @State var vm = EditorViewModel()
    
    ConnectionsBox(viewModel: $vm)
}
