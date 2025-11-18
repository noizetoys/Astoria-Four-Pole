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




struct ContentView: View {
    @State private var viewModel = EditorViewModel()
    @State private var program: Int = 0
    
    private func columnWidth(from proxy: GeometryProxy) -> CGFloat {
        proxy.size.width / 5
    }
    
    private func rowHeight(from proxy: GeometryProxy) -> CGFloat {
        proxy.size.height / 3
    }

    var body: some View {
        GeometryReader { geometry in
            HStack {
                
                VStack {
                    // Globals
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.orange)
                    
                    // Programs
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.green)
                    
                    // /ROMs
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.purple)

                }
                .frame(width: columnWidth(from: geometry))
                
                
                VStack {
                    HStack {
                        // Program Info
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.red)
                            .frame(width: columnWidth(from: geometry) * 3)

                        // Connections
                        ConnectionsBox(viewModel:  $viewModel)

                    }
                    .frame(height: rowHeight(from: geometry) * 0.5)

                    // Edit View
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.yellow)
                }
                .frame(width: columnWidth(from: geometry) * 4)
                
            }
        }
        .padding()
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
    
    
//    var connectionBox: some View {
////        GroupBox("MIDI Connection") {
//            GroupBox() {
//            VStack(alignment: .leading) {
//                
//                HStack {
//                    
//                    // Left side
//                    VStack {
//                        // Source selection
//                        Text("Input:")
//                        
//                        Picker("Source", selection: $viewModel.selectedSource) {
//                            Text("None").tag(nil as MIDIDevice?)
//                            
//                            ForEach(viewModel.availableSources) { device in
//                                Text(device.name)
//                                    .tag(device as MIDIDevice?)
//                            }
//                        }
//                        
//                        // Connection Button
//                        Button(viewModel.isConnected ? "Disconnect" : "Connect") {
//                            Task {
//                                if viewModel.isConnected {
//                                    await viewModel.disconnect()
//                                } else {
//                                    await viewModel.connect()
//                                }
//                            }
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .frame(maxWidth: .infinity)
//                    }
//                    
//                    
//                    VStack {
//                        Text("Output:")
//                        
//                        Picker("Destination", selection: $viewModel.selectedDestination) {
//                            Text("None").tag(nil as MIDIDevice?)
//                            
//                            ForEach(viewModel.availableDestinations) { device in
//                                Text(device.name).tag(device as MIDIDevice?)
//                            }
//                        }
//                        
//                        // Connections
//                        Button("Refresh") {
//                            Task { await viewModel.refreshDevices() }
//                        }
//                        .buttonStyle(.bordered)
//                        .frame(maxWidth: .infinity)
//                    }
//                }
//                
//                    // Status
//                HStack {
//                    Circle()
//                        .fill(viewModel.isConnected ? Color.green : Color.red)
//                        .frame(width: 10, height: 10)
//                    
//                    Text(viewModel.statusMessage)
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//            }
//        }
//    }
    
}



#Preview {
    ContentView()
}
