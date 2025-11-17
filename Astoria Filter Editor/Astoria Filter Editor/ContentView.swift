//
//  ContentView.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = EditorViewModel()
    
    
    var body: some View {
        ScrollView {
            connectionBox
            
            Text(viewModel.program.description)
                .multilineTextAlignment(.leading)
                .frame(maxHeight: .infinity)
                .font(.title3)
                .fontDesign(.monospaced)
        }
        .padding()
    }
    
    
    var connectionBox: some View {
        GroupBox("MIDI Connection") {
            VStack(alignment: .leading, spacing: 30) {
                    // Source selection
                HStack {
                    Text("Input:")
                        .frame(width: 60, alignment: .trailing)
                    
                    Picker("Source", selection: $viewModel.selectedSource) {
                        Text("None").tag(nil as MIDIDevice?)
                        
                        ForEach(viewModel.availableSources) { device in
                            Text(device.name)
                                .tag(device as MIDIDevice?)
                        }
                    }
                }
                
                    // Destination selection
                HStack {
                    Text("Output:")
                        .frame(width: 60, alignment: .trailing)
                    
                    Picker("Destination", selection: $viewModel.selectedDestination) {
                        Text("None").tag(nil as MIDIDevice?)
                        
                        ForEach(viewModel.availableDestinations) { device in
                            Text(device.name).tag(device as MIDIDevice?)
                        }
                    }
                }
                
                    // Connection buttons
                HStack {
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
                    
                    Button("Refresh") {
                        Task { await viewModel.refreshDevices() }
                    }
                    .buttonStyle(.bordered)
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
}



#Preview {
    ContentView()
}
