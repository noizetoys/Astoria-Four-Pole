// CompleteMIDIIntegration.swift
// Complete example showing how MIDIManager and SysExCodec work together
//
// ARCHITECTURE OVERVIEW:
// ┌─────────────────────────────────────────────────────────────┐
// │                         UI Layer                            │
// │                      (MainActor)                            │
// │  • SwiftUI Views                                            │
// │  • @Observable ViewModels                                   │
// └────────────┬────────────────────────────┬───────────────────┘
//              │                            │
//              │ Patch struct               │ [UInt8]
//              ↓                            ↓
// ┌────────────────────────┐  ┌──────────────────────────────┐
// │    SysExCodec          │  │      MIDIManager             │
// │    (Struct)            │  │      (Actor)                 │
// │                        │  │                              │
// │  • encode(patch)       │  │  • send(sysex)               │
// │  • decode(bytes)       │  │  • sysexStream()             │
// │  • validate()          │  │  • ccStream()                │
// └────────────┬───────────┘  └──────────┬───────────────────┘
//              │                         │
//              │ [UInt8]                 │ MIDI 1.0 packets
//              └─────────────┬───────────┘
//                            ↓
//                      CoreMIDI
//                    (Hardware)

import SwiftUI


// MARK: - SwiftUI View Example

struct MIDIEditorView: View {
    @State private var viewModel = MIDIEditorViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Connection Section
            
            GroupBox("MIDI Connection") {
                VStack(alignment: .leading, spacing: 10) {
                    // Source selection
                    HStack {
                        Text("Input:")
                            .frame(width: 60, alignment: .trailing)
                        Picker("Source", selection: $viewModel.selectedSource) {
                            Text("None").tag(nil as MIDIDevice?)
                            ForEach(viewModel.availableSources) { device in
                                Text(device.name).tag(device as MIDIDevice?)
                            }
                        }
                    }
                    
                    // Destination selection
                    HStack {
                        Text("Output:")
                            .frame(width: 60, alignment: .trailing)
                        Picker("Destination", selection: $viewModel.selectedDestination) {
                            Text("None").tag(nil as MIDIDevice?)
                            ForEach(viewModel.availableDestinations) { device in
                                Text(device.name).tag(device as MIDIDevice?)
                            }
                        }
                    }
                    
                    // Connection buttons
                    HStack {
                        Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                            Task {
                                if viewModel.isConnected {
                                    await viewModel.disconnect()
                                } else {
                                    await viewModel.connect()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Refresh") {
                            Task { await viewModel.refreshDevices() }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Status
                    HStack {
                        Circle()
                            .fill(viewModel.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // MARK: - Parameter Section
            
            GroupBox("Parameters") {
                ScrollView {
                    VStack(spacing: 8) {
                        parameterRow("VCF Attack", keyPath: \.vcfAttack)
                        parameterRow("VCF Decay", keyPath: \.vcfDecay)
                        parameterRow("VCF Sustain", keyPath: \.vcfSustain)
                        parameterRow("VCF Release", keyPath: \.vcfRelease)
                        
                        Divider()
                        
                        parameterRow("VCA Attack", keyPath: \.vcaAttack)
                        parameterRow("VCA Decay", keyPath: \.vcaDecay)
                        parameterRow("VCA Sustain", keyPath: \.vcaSustain)
                        parameterRow("VCA Release", keyPath: \.vcaRelease)
                        
                        Divider()
                        
                        parameterRow("Cutoff", keyPath: \.cutoff)
                        parameterRow("Resonance", keyPath: \.resonance)
                        parameterRow("Volume", keyPath: \.volume)
                    }
                    .padding()
                }
                .frame(height: 300)
            }
            
            Divider()
            
            // MARK: - Action Buttons
            
            HStack {
                Button("Send SysEx") {
                    Task { await viewModel.sendPatchViaSysEx() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isConnected)
                
                Button("Send CCs") {
                    Task { await viewModel.sendPatchViaCCs() }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isConnected)
                
                Button("Request") {
                    Task { await viewModel.requestPatch() }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isConnected)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 600)
    }
    
    private func parameterRow(_ label: String, keyPath: WritableKeyPath<Waldorf4PolePatch, UInt8>) -> some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            
            Slider(
                value: Binding(
                    get: { Double(viewModel.patch[keyPath: keyPath]) },
                    set: { viewModel.updateParameter(keyPath, value: UInt8($0)) }
                ),
                in: 0...127,
                step: 1
            )
            
            Text("\(viewModel.patch[keyPath: keyPath])")
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Data Flow Summary

/*
 OUTGOING (UI → Device):
 ========================
 
 1. User adjusts slider in UI
    ↓
 2. updateParameter() called
    ↓
 3. Patch struct updated
    ↓
 4. User clicks "Send SysEx"
    ↓
 5. sendPatchViaSysEx() called
    ↓
 6. codec.encode(patch) → [UInt8]
    ↓
 7. midiManager.send(.sysex(bytes), to: device)
    ↓
 8. MIDIManager creates MIDI 1.0 packet
    ↓
 9. CoreMIDI sends to hardware
 
 
 INCOMING (Device → UI):
 ========================
 
 1. Hardware sends MIDI
    ↓
 2. CoreMIDI receives MIDI 1.0 packets
    ↓
 3. MIDIManager parses bytes from packets
    ↓
 4. AsyncStream yields bytes
    ↓
 5. handleIncomingSysEx() called
    ↓
 6. codec.decode(bytes) → Patch
    ↓
 7. patch = receivedPatch
    ↓
 8. UI updates automatically (@Observable)
 
 
 KEY PRINCIPLES:
 ===============
 
 ✅ MIDIManager (Actor) = Thread-safe MIDI I/O
 ✅ SysExCodec (Struct) = Pure encode/decode functions
 ✅ ViewModel (MainActor) = UI coordination
 ✅ AsyncStreams = Reactive data flow
 ✅ Separation of concerns = Easy to test and maintain
 ✅ MIDI 1.0 only = Simple, reliable, compatible
 
 
 TESTING:
 ========
 
 // Test codec independently
 let patch = Waldorf4PolePatch()
 let codec = SysExCodec<Waldorf4PolePatch>()
 let bytes = try codec.encode(patch)
 let decoded = try codec.decode(bytes)
 assert(decoded == patch)
 
 // Test ViewModel with mock MIDI
 let mockMIDI = MockMIDIManager()
 let viewModel = MIDIEditorViewModel(midiManager: mockMIDI)
 await viewModel.sendPatchViaSysEx()
 assert(mockMIDI.lastSentBytes == expectedBytes)
 */
