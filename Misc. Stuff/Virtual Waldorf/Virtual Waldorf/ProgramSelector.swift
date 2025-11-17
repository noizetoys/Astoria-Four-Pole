//
//  ProgramSelector.swift
//  Virtual Waldorf 4 Pole Filter
//

import SwiftUI

struct ProgramSelector: View {
    @ObservedObject var deviceState: VirtualDeviceState
    
    let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 8)
    ]
    
    var body: some View {
        GroupBox(label: Label("Program Selection", systemImage: "music.note.list")) {
            VStack(alignment: .leading, spacing: 12) {
                // Current Program Display
                HStack {
                    Text("Current Program:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(deviceState.programs[deviceState.currentProgram].name)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                
                // Program Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<20, id: \.self) { index in
                            Button(action: {
                                deviceState.currentProgram = index
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                    Text("Program")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    deviceState.currentProgram == index 
                                        ? Color.blue 
                                        : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    deviceState.currentProgram == index 
                                        ? .white 
                                        : .primary
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 200)
                
                Divider()
                
                // Quick Actions
                HStack(spacing: 8) {
                    Button(action: {
                        deviceState.sendProgramDump(deviceState.currentProgram)
                    }) {
                        Label("Send Program", systemImage: "arrow.up.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        deviceState.sendAllDump()
                    }) {
                        Label("Send All", systemImage: "arrow.up.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(8)
        }
    }
}

#Preview {
    ProgramSelector(deviceState: VirtualDeviceState())
        .padding()
        .frame(width: 400, height: 500)
}
