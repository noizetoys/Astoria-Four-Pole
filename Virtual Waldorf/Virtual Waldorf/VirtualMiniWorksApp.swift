//
//  VirtualMiniWorksApp.swift
//  Virtual Waldorf 4 Pole Filter
//
//  A virtual MIDI device for testing SysEx communication
//

import SwiftUI
import CoreMIDI

@main
struct VirtualMiniWorksApp: App {
    @StateObject private var midiManager = MIDIManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(midiManager)
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(MIDIManager.shared)
        .frame(width: 1000, height: 800)
}
