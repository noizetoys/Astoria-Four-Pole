//
//  SettingsView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//
import SwiftUI
import Combine


    // MARK: - Settings View

/**
 * SettingsView - Configuration panel for MIDI monitoring parameters
 *
 * This modal sheet allows users to configure:
 * 1. MIDI input device selection
 * 2. Which Control Change (CC) number to monitor
 * 3. Which note number to monitor
 * 4. Which note message type to capture (On/Off/Both)
 *
 * The view is presented as a sheet from the main ContentView.
 * Changes are applied when the user clicks "Done".
 *
 * Layout:
 * - ScrollView wrapper for small screens
 * - Grouped sections with headers
 * - Preset buttons for common values
 * - Fixed size: 500x450 pixels
 *
 * Bindings:
 * - monitoredCC: Two-way binding to CC number (updates MIDIManager on Done)
 * - monitoredNote: Two-way binding to note number (updates MIDIManager on Done)
 * - noteType: Two-way binding to note message type (updates MIDIManager on Done)
 * - showSettings: Controls modal presentation (set to false to dismiss)
 */
struct SettingsView: View {
    var midiManager: MIDIService = .shared
//    @ObservedObject var midiManager: MIDIService
    @Binding var monitoredCC: Int
    @Binding var monitoredNote: Int
    @Binding var noteType: NoteType
    @Binding var showSettings: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                    // Header
                HStack {
                    Text("MIDI Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") {
                            // Update MIDI manager with new values
                        midiManager.monitoredCC = UInt8(monitoredCC)
                        midiManager.monitoredNote = UInt8(monitoredNote)
                        midiManager.noteType = noteType
                        showSettings = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
                
                Divider()
                
                    // MIDI Device Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("MIDI Input Device")
                        .font(.headline)
                    
                    Picker("Device", selection: Binding(
                        get: { midiManager.selectedDevice },
                        set: { midiManager.selectDevice($0) }
                    )) {
                        Text("All Devices").tag(nil as MIDIDevice?)
                        ForEach(midiManager.availableDevices) { device in
                            Text(device.name).tag(device as MIDIDevice?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button("Refresh Devices") {
                        midiManager.refreshDevices()
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                    // CC Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Control Change (CC) to Monitor")
                        .font(.headline)
                    
                    HStack {
                        TextField("CC Number", value: $monitoredCC, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Text("(0-127)")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(getCCName(monitoredCC))
                            .foregroundColor(.secondary)
                    }
                    
                        // Common CC presets
                    HStack(spacing: 8) {
                        Text("Presets:")
                            .foregroundColor(.secondary)
                        Button("Breath (2)") { monitoredCC = 2 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("Modulation (1)") { monitoredCC = 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("Volume (7)") { monitoredCC = 7 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("Expression (11)") { monitoredCC = 11 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                
                Divider()
                
                    // Note Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note to Monitor")
                        .font(.headline)
                    
                    HStack {
                        TextField("Note Number", value: $monitoredNote, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Text("(0-127)")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(getNoteName(monitoredNote))
                            .foregroundColor(.secondary)
                    }
                    
                        // Common note presets
                    HStack(spacing: 8) {
                        Text("Presets:")
                            .foregroundColor(.secondary)
                        Button("C3 (48)") { monitoredNote = 48 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("C4 (60)") { monitoredNote = 60 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("C5 (72)") { monitoredNote = 72 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                
                Divider()
                
                    // Note Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note Message Type")
                        .font(.headline)
                    
                    Picker("Note Type", selection: $noteType) {
                        ForEach(NoteType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
    
    private func getCCName(_ cc: Int) -> String {
        switch cc {
            case 0: return "Bank Select"
            case 1: return "Modulation Wheel"
            case 2: return "Breath Controller"
            case 4: return "Foot Controller"
            case 5: return "Portamento Time"
            case 7: return "Channel Volume"
            case 10: return "Pan"
            case 11: return "Expression"
            case 64: return "Sustain Pedal"
            case 65: return "Portamento"
            case 66: return "Sostenuto"
            case 67: return "Soft Pedal"
            case 71: return "Resonance"
            case 72: return "Release Time"
            case 73: return "Attack Time"
            case 74: return "Cutoff"
            default: return "CC \(cc)"
        }
    }
    
    private func getNoteName(_ noteNumber: Int) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (noteNumber / 12) - 1
        let note = notes[noteNumber % 12]
        return "\(note)\(octave)"
    }
}
