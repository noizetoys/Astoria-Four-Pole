//
//  MIDIMonitorView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//
import SwiftUI


    // MARK: - Note Type Enum

/**
 * Defines which type of MIDI note messages to monitor.
 *
 * Cases:
 * - noteOn: Only monitor Note On messages (0x90-0x9F)
 * - noteOff: Only monitor Note Off messages (0x80-0x8F)
 * - both: Monitor both Note On and Note Off messages
 *
 * Note: Some MIDI devices send Note On with velocity 0 instead of Note Off.
 * This is handled automatically in the MIDI packet parser.
 */
enum NoteType: String, CaseIterable, Identifiable {
    case noteOn = "Note On"
    case noteOff = "Note Off"
    case both = "Both"
    
    var id: String { rawValue }
}


    // MARK: - Main Monitor View

/**
 * ContentView - Main application interface
 *
 * This is the root view of the application, displaying:
 * 1. Header with app title and current monitoring parameters
 * 2. Device info bar showing connected MIDI device
 * 3. Legend explaining the graph visualization
 * 4. Real-time scrolling graph (MIDIGraphView)
 * 5. Settings button (gear icon) to open configuration
 *
 * State Management:
 * - @StateObject midiManager: Manages MIDI communication (lifecycle tied to view)
 * - @StateObject graphViewModel: Manages graph data (lifecycle tied to view)
 * - @State showSettings: Controls settings sheet presentation
 * - @State monitoredCC: Currently monitored CC number (synced with MIDIManager)
 * - @State monitoredNote: Currently monitored note number (synced with MIDIManager)
 * - @State noteType: Note message type filter (synced with MIDIManager)
 *
 * Lifecycle:
 * - onAppear: Configures MIDIManager and starts GraphViewModel
 * - onDisappear: Stops GraphViewModel
 *
 * UI Layout (top to bottom):
 * 1. Black header bar with title, parameters, values, and settings button
 * 2. Device connection status bar
 * 3. Legend showing visualization elements
 * 4. Scrolling graph (fills remaining space)
 *
 * Settings Integration:
 * - Gear button opens SettingsView as a sheet
 * - Settings changes are applied to MIDIManager when user clicks "Done"
 * - UI updates automatically via @Published properties
 */
struct MIDIMonitorView: View {
//    @State private var viewModel: GraphViewModel
    
    @State private var showSettings = false
    @State private var monitoredCC: Int = 2       // Default: Breath Control (CC2)
    @State private var monitoredNote: Int = 48    // Default: C3
    @State private var noteType: NoteType = .both // Default: Monitor both On and Off
    
    @State private var isOn: Bool = true
    @State private var showVelocity: Bool = true
    @State private var showNotes: Bool = true

    
    init() {
        debugPrint(icon: "🔥1️⃣", message: "1 Creating MIDIMonitorView...", type: .trace)
//        viewModel = GraphViewModel()
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            
            Text("Envelope Monitor")
                .bold()
            
            HStack {
                onOffButton
                
                velocityButton

                notesButton
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.6))
            
                // Graph
            MIDIGraphView(ccNumber: ContinuousController.breathControl,
                          channel: 1,
                          isOn: $isOn,
                          showVelocity: $showVelocity,
                          showNotes: $showNotes)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .onReceive(NotificationCenter.default.publisher(for: .midiSourceConnected)) { _ in
            isOn = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .midiSourceDisconnected)) { _ in
            isOn = false
            
        }

    }
    
    
    private var onOffButton: some View {
        Button {
            withAnimation {
                isOn.toggle()
            }
        } label: {
            HStack {
                Image(systemName: isOn ? "power.circle" : "power.circle.fill")
                    .frame(width: 30, height: 3)
                    .foregroundColor(isOn ? .green : .red)
                
                Text("\(isOn ? "On" : "Off")")
                    .font(.system(size: 12))
                    .foregroundColor(isOn ? .green : .red)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)

    }
    
    
    private var velocityButton: some View {
        Button {
            withAnimation {
                showVelocity.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(showVelocity ? Color.red : Color.gray)
                    .frame(width: 10, height: 10)
                
                Text("Velocity")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    
    private var notesButton: some View {
        Button {
            withAnimation {
                showNotes.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(showNotes ? Color.orange : Color.gray )
                    .frame(width: 8, height: 8)
                
                Text("Note On/Off")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)

    }
    
    
    private var clearButton: some View {
        Button {
//            viewModel.dataPoints = []
        } label: {
            Text("Clear")
        }
    }
    
//    private func getCCName(_ cc: Int) -> String {
//        switch cc {
//            case 1: return "Modulation"
//            case 2: return "Breath"
//            case 7: return "Volume"
//            case 11: return "Expression"
//            default: return "CC\(cc)"
//        }
//    }
    
//    private func getNoteName(_ noteNumber: Int) -> String {
//        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
//        let octave = (noteNumber / 12) - 1
//        let note = notes[noteNumber % 12]
//        return "\(note)\(octave)"
//    }
}
