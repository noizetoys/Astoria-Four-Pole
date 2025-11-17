//
//  MIDIPortSelector.swift
//  Virtual Waldorf 4 Pole Filter
//

import SwiftUI
import CoreMIDI

struct MIDIPortSelector: View {
    @EnvironmentObject var midiManager: MIDIManager
    
    var body: some View {
        GroupBox(label: Label("MIDI Ports", systemImage: "cable.connector")) {
            VStack(alignment: .leading, spacing: 12) {
                // Input Port
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input Port (Receive)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { midiManager.selectedSource },
                        set: { if let source = $0 { midiManager.connectToSource(source) } }
                    )) {
                        Text("None").tag(nil as MIDIEndpointRef?)
                        ForEach(midiManager.availableSources, id: \.self) { source in
                            Text(midiManager.getName(for: source))
                                .tag(source as MIDIEndpointRef?)
                        }
                    }
                    .labelsHidden()
                }
                
                Divider()
                
                // Output Port
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output Port (Send)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { midiManager.selectedDestination },
                        set: { if let dest = $0 { midiManager.selectDestination(dest) } }
                    )) {
                        Text("None").tag(nil as MIDIEndpointRef?)
                        ForEach(midiManager.availableDestinations, id: \.self) { dest in
                            Text(midiManager.getName(for: dest))
                                .tag(dest as MIDIEndpointRef?)
                        }
                    }
                    .labelsHidden()
                }
                
                // Refresh Button
                Button(action: {
                    midiManager.refreshPorts()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Ports")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(8)
        }
    }
}

#Preview {
    MIDIPortSelector()
        .environmentObject(MIDIManager.shared)
        .padding()
        .frame(width: 400)
}
