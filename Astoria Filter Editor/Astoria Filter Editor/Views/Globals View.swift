//
//  Globals View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import SwiftUI



struct Globals_View: View {
    let globals: MiniWorksGlobalData
    
    @State private var midiChannel: Int = 1
    @State private var midiNote: Int = 60
    @State private var deviceID: Int = 1
    @State private var startupProgram: Int = 1
    @State private var midiControl: GlobalMIDIControl = .off
    @State private var knobMode: GlobalKnobMode = .relative
    

    var body: some View {
        GroupBox {
//            Text("Globals")
//                .frame(maxWidth: .infinity, alignment: .center)
//                .font(.headline)
            
            HStack {
                Text("MIDI Channel")
                Spacer()
                Picker("", selection: $midiChannel) {
                    ForEach(0..<17) { channel in
                        Text(channelString(for: channel))
                            .tag(channel)
                    }
                }
            }

            HStack {
                Text("MIDI Note")
                Spacer()
                Picker("", selection: $midiNote) {
                    ForEach(21..<109) { note in
                        Text(midiNoteName(note))
                            .tag(note)
                    }
               }
            }
            
            HStack {
                Text("Device ID")
                Spacer()
                Picker("", selection: $deviceID) {
                    ForEach(0..<127) { id in
                        Text("\(id)")
                            .tag(id)
                    }
                }
            }
            
            HStack {
                Text("Startup Program")
                    .padding(.trailing)
                Spacer()
                Picker("", selection: $startupProgram) {
                    ForEach(0..<40) { program in
                        Text("\(program + 1)")
                            .tag(program)
                    }
                }
           }
            
            HStack {
                Text("MIDI Control")
                Spacer()
                Picker("", selection: $midiControl) {
                    ForEach(GlobalMIDIControl.allCases) { control in
                        Text("\(control.name)")
                            .tag(control)
                    }
                }

            }
            
            HStack {
                Text("Knob Mode")
                Spacer()
                Picker("", selection: $knobMode) {
                    ForEach(GlobalKnobMode.allCases) { mode in
                        Text("\(mode.name)")
                            .tag(mode)
                    }
                }

            }

            HStack {
                Button {
                    resetGlobals()
                } label: {
                    Text("Reset")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    saveGlobals()
                } label: {
                    Text("Save")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)

            }
        }
        .onAppear {
            resetGlobals()
        }
    }
    
    
    private func channelString(for num: Int) -> String {
        guard (0..<17).contains(num) else { fatalError("\(#function) error -> num = \(num)")}
        return num == 0 ? "Omni" : "\(num)"
    }
    
    
    private func midiNoteName(_ note: Int) -> String {
       guard
            (0..<127).contains(note)
        else { return "Invalid Note number" }
        
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        if note == 0 { return "C1" }
        
        let name = noteNames[note % 12]
        let octave = (note / 12) - 1
        return "\(name)\(octave) (\(note))"
    }

    
    private func resetGlobals() {
        midiChannel = Int(globals.midiChannel)
        midiNote = Int(globals.noteNumber)
        deviceID = Int(globals.deviceID)
        startupProgram = Int(globals.startUpProgramID)
        midiControl = globals.midiControl
        knobMode = globals.knobMode
    }
    
    
    private func saveGlobals() {
        globals.midiChannel = UInt8(midiChannel)
        globals.noteNumber = UInt8(midiNote)
        globals.deviceID = UInt8(deviceID)
        globals.startUpProgramID = UInt8(startupProgram)
        globals.midiControl = midiControl
        globals.knobMode = knobMode
        
        globals.saveToDefaults()
    }
        
    
}


#Preview {
    let viewModel = EditorViewModel()
    
    Globals_View(globals: viewModel.configuration.globalSetup)
}
