//
//  MIDIView.swift
//  MiniWorksMIDI
//
//  MIDI setup and monitoring interface. Displays available MIDI sources
//  and destinations, allows connection management, and shows a scrolling
//  log of all MIDI traffic with timestamps.
//
//  Features:
//  - Source/destination selection with refresh capability
//  - Checksum mode configuration
//  - Live MIDI log with color-coded message types
//  - Log clearing and auto-scroll
//

import SwiftUI

struct MIDIView: View {
    @EnvironmentObject var midiManager: MIDIManager
    
    var body: some View {
        VStack(spacing: 0) {
            // MIDI configuration
            configurationPanel
                .padding()
                .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // MIDI log
            logPanel
        }
        .navigationTitle("MIDI Setup")
        .onAppear {
            midiManager.refreshEndpoints()
        }
    }
    
    // MARK: - Configuration Panel
    
    private var configurationPanel: some View {
        VStack(spacing: 20) {
            // Source selection
            HStack {
                Text("MIDI Source:")
                    .frame(width: 120, alignment: .leading)
                
                Picker("Source", selection: $midiManager.selectedSource) {
                    Text("None").tag(nil as MIDIManager.MIDIEndpointInfo?)
                    ForEach(midiManager.sources) { source in
                        Text(source.name).tag(source as MIDIManager.MIDIEndpointInfo?)
                    }
                }
                .pickerStyle(.menu)
                
                Button("Refresh") {
                    midiManager.refreshEndpoints()
                }
                .buttonStyle(.bordered)
            }
            
            // Destination selection
            HStack {
                Text("MIDI Destination:")
                    .frame(width: 120, alignment: .leading)
                
                Picker("Destination", selection: $midiManager.selectedDestination) {
                    Text("None").tag(nil as MIDIManager.MIDIEndpointInfo?)
                    ForEach(midiManager.destinations) { dest in
                        Text(dest.name).tag(dest as MIDIManager.MIDIEndpointInfo?)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Checksum mode
            HStack {
                Text("Checksum Mode:")
                    .frame(width: 120, alignment: .leading)
                
                Picker("Checksum", selection: $midiManager.checksumMode) {
                    ForEach(ChecksumMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Connection control
            HStack {
                Button(midiManager.isConnected ? "Disconnect" : "Connect") {
                    if midiManager.isConnected {
                        midiManager.disconnect()
                    } else {
                        midiManager.connect()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(midiManager.selectedSource == nil)
                
                Circle()
                    .fill(midiManager.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(midiManager.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Log Panel
    
    private var logPanel: some View {
        VStack(spacing: 0) {
            // Log header
            HStack {
                Text("MIDI Log")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    midiManager.clearLog()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Log messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(midiManager.logMessages) { msg in
                            logMessageView(msg)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: midiManager.logMessages.count) { _ in
                    // Auto-scroll to bottom
                    if let lastMsg = midiManager.logMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private func logMessageView(_ msg: MIDIManager.LogMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(formatTimestamp(msg.timestamp))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            // Direction indicator
            Image(systemName: directionIcon(msg.direction))
                .foregroundColor(directionColor(msg.direction))
                .frame(width: 20)
            
            // Message
            Text(msg.message)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    private func directionIcon(_ direction: MIDIManager.LogMessage.Direction) -> String {
        switch direction {
        case .sent: return "arrow.up.circle.fill"
        case .received: return "arrow.down.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private func directionColor(_ direction: MIDIManager.LogMessage.Direction) -> Color {
        switch direction {
        case .sent: return .blue
        case .received: return .green
        case .error: return .red
        }
    }
}
