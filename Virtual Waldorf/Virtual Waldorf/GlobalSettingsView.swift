//
//  GlobalSettingsView.swift
//  Virtual Waldorf 4 Pole Filter
//

import SwiftUI

struct GlobalSettingsView: View {
    @ObservedObject var deviceState: VirtualDeviceState
    
    var body: some View {
        GroupBox(label: Label("Global Settings", systemImage: "globe")) {
            VStack(alignment: .leading, spacing: 12) {
                // Device ID
                HStack {
                    Text("Device ID")
                        .font(.caption)
                        .frame(width: 120, alignment: .leading)
                    
                    Stepper(value: Binding(
                        get: { Int(deviceState.deviceID) },
                        set: { deviceState.deviceID = UInt8($0) }
                    ), in: 0...126) {
                        Text("\(deviceState.deviceID)")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                
                Divider()
                
                // MIDI Channel
                HStack {
                    Text("MIDI Channel")
                        .font(.caption)
                        .frame(width: 120, alignment: .leading)
                    
                    Picker("", selection: Binding(
                        get: { Int(deviceState.globalMidiChannel) },
                        set: { deviceState.globalMidiChannel = UInt8($0) }
                    )) {
                        Text("Omni").tag(0)
                        ForEach(1...16, id: \.self) { channel in
                            Text("Channel \(channel)").tag(channel)
                        }
                    }
                    .labelsHidden()
                }
                
                // MIDI Control
                HStack {
                    Text("MIDI Control")
                        .font(.caption)
                        .frame(width: 120, alignment: .leading)
                    
                    Picker("", selection: Binding(
                        get: { Int(deviceState.globalMidiControl) },
                        set: { deviceState.globalMidiControl = UInt8($0) }
                    )) {
                        Text("Off").tag(0)
                        Text("CtR (Control)").tag(1)
                        Text("CtS (Signal)").tag(2)
                    }
                    .labelsHidden()
                }
                
                // Knob Mode
                HStack {
                    Text("Knob Mode")
                        .font(.caption)
                        .frame(width: 120, alignment: .leading)
                    
                    Picker("", selection: Binding(
                        get: { Int(deviceState.globalKnobMode) },
                        set: { deviceState.globalKnobMode = UInt8($0) }
                    )) {
                        Text("Jump").tag(0)
                        Text("Relative").tag(1)
                    }
                    .labelsHidden()
                }
                
                Divider()
                
                // Startup Program
                HStack {
                    Text("Startup Program")
                        .font(.caption)
                        .frame(width: 120, alignment: .leading)
                    
                    Picker("", selection: Binding(
                        get: { Int(deviceState.startupProgramID) },
                        set: { deviceState.startupProgramID = UInt8($0) }
                    )) {
                        ForEach(0..<20, id: \.self) { index in
                            Text("Program \(index + 1)").tag(index)
                        }
                    }
                    .labelsHidden()
                }
                
                // Global Note Number
                HStack {
                    Text("Note Number")
                        .font(.caption)
                        .frame(width: 120, alignment: .leading)
                    
                    Stepper(value: Binding(
                        get: { Int(deviceState.globalNoteNumber) },
                        set: { deviceState.globalNoteNumber = UInt8($0) }
                    ), in: 0...127) {
                        Text(noteNumberToName(deviceState.globalNoteNumber))
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
            .padding(8)
        }
    }
    
    private func noteNumberToName(_ note: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(note) / 12 - 1
        let noteName = noteNames[Int(note) % 12]
        return "\(noteName)\(octave) (\(note))"
    }
}

#Preview {
    GlobalSettingsView(deviceState: VirtualDeviceState())
        .padding()
        .frame(width: 400)
}
