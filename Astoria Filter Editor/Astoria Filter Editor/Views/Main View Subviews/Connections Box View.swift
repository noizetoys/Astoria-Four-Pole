//
//  ConnectionsBox.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/18/25.
//

import SwiftUI


nonisolated
extension Notification.Name {
    static let midiSourceDisconnected = Notification.Name("midiSourceDisconnected")
    static let midiSourceConnected = Notification.Name("midiSourceConnected")
}


struct ConnectionsBox: View {
    @Binding var viewModel: MainViewModel
    
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                
                    // Left side
                VStack {
                        // Source selection
                    Text("Input:")
                    
                    Picker("", selection: $viewModel.selectedSource) {
                        Text("None").tag(nil as MIDIDevice?)
                            .frame(maxWidth: .infinity)
                        
                        ForEach(viewModel.availableSources) { device in
                            Text(device.name)
                                .tag(device as MIDIDevice?)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                        // Connection Button
                    Button {
                        Task {
                            if viewModel.isConnected {
                                await viewModel.disconnect()
                            }
                            else {
                                await viewModel.connect()
                            }
                        }
                    } label: {
                        Text(viewModel.isConnected ? "Disconnect" : "Connect")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                
                VStack {
                    Text("Output:")
                    
                    Picker("", selection: $viewModel.selectedDestination) {
                        Text("None").tag(nil as MIDIDevice?)
                        
                        ForEach(viewModel.availableDestinations) { device in
                            Text(device.name).tag(device as MIDIDevice?)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                        // Connections
                    Button {
                        Task { await viewModel.refreshDevices() }
                    } label: {
                        Text("Refresh")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
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
    }
}



#Preview {
    @Previewable @State var vm = MainViewModel()
    
    ConnectionsBox(viewModel: $vm)
}
