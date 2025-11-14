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

struct ContentView: View {
    @EnvironmentObject var midiManager: MIDIManager
    @StateObject private var deviceState = VirtualDeviceState()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                Divider()
                
                // Main Content
                HSplitView {
                    // Left Panel: Controls
                    VStack(spacing: 16) {
                        MIDIPortSelector()
                        ProgramSelector(deviceState: deviceState)
                        ParameterView(deviceState: deviceState)
                        GlobalSettingsView(deviceState: deviceState)
                    }
                    .frame(minWidth: 350, idealWidth: 400, maxWidth: 500)
                    .padding()
                    
                    Divider()
                    
                    // Right Panel: MIDI Monitor
                    MIDIMonitorView()
                        .frame(minWidth: 400, idealWidth: 600)
                }
            }
            .navigationTitle("Virtual Waldorf 4 Pole Filter")
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}

struct HeaderView: View {
    @EnvironmentObject var midiManager: MIDIManager
    
    var body: some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Virtual Waldorf 4 Pole Filter")
                    .font(.headline)
                Text("MIDI Test Device")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(midiManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(midiManager.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environmentObject(MIDIManager.shared)
        .frame(width: 1000, height: 800)
}
