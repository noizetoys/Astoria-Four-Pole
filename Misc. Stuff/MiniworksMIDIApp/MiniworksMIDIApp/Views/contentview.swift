//
//  ContentView.swift
//  MiniWorksMIDI
//
//  Main container view that provides a tabbed interface for MIDI configuration,
//  program editing, and CC mapping. On macOS, uses a sidebar-style navigation;
//  on iOS, uses a tab bar.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var midiManager: MIDIManager
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List {
                NavigationLink(destination: MIDIView()) {
                    Label("MIDI Setup", systemImage: "cable.connector")
                }
                NavigationLink(destination: ProgramEditorView()) {
                    Label("Program Editor", systemImage: "slider.horizontal.3")
                }
                NavigationLink(destination: CCMappingView()) {
                    Label("CC Mapping", systemImage: "dial.medium")
                }
            }
            .navigationTitle("MiniWorksMIDI")
        } detail: {
            MIDIView()
        }
        .frame(minWidth: 900, minHeight: 700)
        #else
        TabView {
            MIDIView()
                .tabItem {
                    Label("MIDI", systemImage: "cable.connector")
                }
            
            ProgramEditorView()
                .tabItem {
                    Label("Editor", systemImage: "slider.horizontal.3")
                }
            
            CCMappingView()
                .tabItem {
                    Label("CC Map", systemImage: "dial.medium")
                }
        }
        #endif
    }
}
