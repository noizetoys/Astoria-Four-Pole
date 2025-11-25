//
//  Settings View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import SwiftUI


struct Settings_View: View {
    let globalData: MiniWorksGlobalData
    
    @State private var autoConnectMIDI: Bool = false
    @State private var sendProgramChangeOnSelect: Bool = false
    @State private var requestProgramChangeOnSelect: Bool = false

    @State private var midiChannel: Int = 1
    @State private var midiNote: Int = 60
    @State private var deviceID: Int = 1
    @State private var startupProgram: Int = 1
    @State private var midiControl: GlobalMIDIControl = .off
    @State private var knobMode: GlobalKnobMode = .relative

    
    var body: some View {
        Form {
            Section("Globals") {
                Picker("MIDI Channel", selection: $midiChannel) {
                    ForEach(0..<17, id: \.self) { channel in
                        Text(channelString(for: channel))
                            .tag(channel)
                    }
                }
                
                
                Picker("MIDI Note", selection: $midiNote) {
                    ForEach(21..<109) { note in
                        Text(midiNoteName(note))
                            .tag(note)
                    }
                }
                
                
                Picker("Device ID", selection: $deviceID) {
                    ForEach(0..<127) { id in
                        Text("\(id)")
                            .tag(id)
                    }
                }
                
                
                Picker("Startup Program", selection: $startupProgram) {
                    ForEach(0..<40) { program in
                        Text("\(program + 1)")
                            .tag(program)
                    }
                }
                
                
                Picker("MIDI Control", selection: $midiControl) {
                    ForEach(GlobalMIDIControl.allCases) { control in
                        Text("\(control.name)")
                            .tag(control)
                    }
                }
                
                
                Picker("Knob Mode", selection: $knobMode) {
                    ForEach(GlobalKnobMode.allCases) { mode in
                        Text("\(mode.name)")
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("App Settings") {
                Toggle(isOn: $autoConnectMIDI) {
                    Text("Auto-Connect MIDI")
                }
                
                Toggle(isOn: $sendProgramChangeOnSelect) {
                    Text("Send Program Change")
                }
                
                Toggle(isOn: $requestProgramChangeOnSelect) {
                    Text("Request Program Change on Select")
                }
            }
            
        }
    }
    
    
    private func channelString(for num: Int) -> String {
//        return "\(num)"
        guard (0..<17).contains(num) else { fatalError("\(#function) error -> num = \(num)")}
        return num == 0 ? "Omni" : "\(num)"
    }
    
    
    private func midiNoteName(_ note: Int) -> String {
//        return "C3p0"
        guard
            (21..<109).contains(note)
        else { return "" }
        
        let noteNames: Array<String> = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        let name = noteNames[note % 12]
        let octave = (note / 12) - 1
        return "\(name)\(octave) (\(note))"
    }
    
    
    
}


#Preview {
    @Previewable @State var globalData: MiniWorksGlobalData = .init()
    
    Settings_View(globalData: globalData)
}
