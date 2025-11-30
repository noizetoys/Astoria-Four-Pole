    //
    //  MiniWorksMIDIApp.swift
    //  MiniWorksMIDI
    //
    //  A universal SwiftUI app for macOS and iOS that provides a complete
    //  CoreMIDI SysEx interface for the Waldorf MiniWorks 4-Pole synthesizer.
    //
    //  This is the app entry point. It creates the MIDI manager as a shared
    //  environment object so all views can access MIDI state.
    //

import SwiftUI

@main
struct MiniWorksMIDIApp: App {
    @StateObject private var midiManager = MIDIManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(midiManager)
        }
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
#endif
    }
}
