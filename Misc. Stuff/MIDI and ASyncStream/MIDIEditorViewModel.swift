// MIDIEditorViewModel.swift
// ViewModel coordinating between UI and MIDI subsystem
//
// RESPONSIBILITIES:
// - Manage UI state (@Observable)
// - Bridge between MainActor UI and MIDIManager actor
// - Coordinate patch editing and MIDI communication
// - Handle device discovery and connection

import SwiftUI
import Observation

/// ViewModel for MIDI editor UI
/// Runs on MainActor for UI updates, bridges to MIDIManager actor for MIDI I/O
@MainActor
@Observable
final class MIDIEditorViewModel {
    
    // MARK: - Device Management
    
    /// Available MIDI input sources
    var availableSources: [MIDIDevice] = []
    
    /// Available MIDI output destinations
    var availableDestinations: [MIDIDevice] = []
    
    /// Currently selected input device
    var selectedSource: MIDIDevice?
    
    /// Currently selected output device
    var selectedDestination: MIDIDevice?
    
    /// Connection status
    var isConnected: Bool = false
    
    /// Status message for UI
    var statusMessage: String = "Not connected"
    
    // MARK: - Patch Data
    
    /// Current patch being edited
    var patch: Waldorf4PolePatch = Waldorf4PolePatch()
    
    // MARK: - Dependencies
    
    /// MIDI manager (can be injected for testing)
    private let midiManager: MIDIManager
    
    /// SysEx codec
    private let codec = SysExCodec<Waldorf4PolePatch>()
    
    /// Tasks for stream listening
    private var sysexListenerTask: Task<Void, Never>?
    private var ccListenerTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(midiManager: MIDIManager = .shared) {
        self.midiManager = midiManager
        
        // Start with device discovery
        Task {
            await refreshDevices()
        }
    }
    
    // MARK: - Device Discovery
    
    /// Refresh available MIDI devices
    func refreshDevices() async {
        availableSources = await midiManager.availableSources()
        availableDestinations = await midiManager.availableDestinations()
        
        // Auto-select first device if available
        if selectedSource == nil {
            selectedSource = availableSources.first
        }
        if selectedDestination == nil {
            selectedDestination = availableDestinations.first
        }
        
        statusMessage = "Found \(availableSources.count) inputs, \(availableDestinations.count) outputs"
    }
    
    // MARK: - Connection Management
    
    /// Connect to selected devices
    func connect() async {
        guard let source = selectedSource,
              let destination = selectedDestination else {
            statusMessage = "Please select input and output devices"
            return
        }
        
        do {
            try await midiManager.connect(source: source, destination: destination)
            isConnected = true
            statusMessage = "Connected to \(source.name)"
            
            // Start listening for incoming MIDI
            startListening(from: source)
            
        } catch {
            statusMessage = "Connection failed: \(error.localizedDescription)"
            isConnected = false
        }
    }
    
    /// Disconnect from devices
    func disconnect() async {
        guard let source = selectedSource else { return }
        
        // Stop listening
        stopListening()
        
        // Disconnect
        await midiManager.disconnect(from: source)
        
        isConnected = false
        statusMessage = "Disconnected"
    }
    
    // MARK: - Incoming MIDI Handling
    
    /// Start listening for incoming MIDI messages
    private func startListening(from device: MIDIDevice) {
        // Listen for SysEx (patch dumps)
        sysexListenerTask = Task { [weak self] in
            guard let self else { return }
            
            for await sysexData in await self.midiManager.sysexStream(from: device) {
                await self.handleIncomingSysEx(sysexData)
            }
        }
        
        // Listen for CCs (real-time parameter changes)
        ccListenerTask = Task { [weak self] in
            guard let self else { return }
            
            for await (channel, cc, value) in await self.midiManager.ccStream(from: device) {
                await self.handleIncomingCC(channel: channel, cc: cc, value: value)
            }
        }
    }
    
    /// Stop listening for incoming MIDI
    private func stopListening() {
        sysexListenerTask?.cancel()
        sysexListenerTask = nil
        
        ccListenerTask?.cancel()
        ccListenerTask = nil
    }
    
    /// Handle incoming SysEx message
    private func handleIncomingSysEx(_ data: [UInt8]) {
        do {
            // Decode SysEx to patch
            let receivedPatch = try codec.decode(data)
            
            // Update current patch (on MainActor)
            self.patch = receivedPatch
            
            statusMessage = "Received patch: \(receivedPatch.name)"
            print("✅ Received patch via SysEx")
            
        } catch {
            statusMessage = "SysEx decode error: \(error.localizedDescription)"
            print("❌ SysEx decode error: \(error)")
        }
    }
    
    /// Handle incoming CC message
    private func handleIncomingCC(channel: UInt8, cc: UInt8, value: UInt8) {
        // Update patch from CC
        patch.updateFromCC(cc: cc, value: value)
        
        // Optional: Show which parameter changed
        // statusMessage = "CC\(cc) = \(value)"
    }
    
    // MARK: - Outgoing MIDI
    
    /// Send current patch via SysEx
    func sendPatchViaSysEx() async {
        guard let destination = selectedDestination else {
            statusMessage = "No output device selected"
            return
        }
        
        do {
            // Encode patch to SysEx
            let sysexData = try codec.encode(patch)
            
            // Send via MIDI
            try await midiManager.send(.sysex(sysexData), to: destination)
            
            statusMessage = "Sent patch via SysEx (\(sysexData.count) bytes)"
            print("✅ Sent patch via SysEx")
            
        } catch {
            statusMessage = "Send failed: \(error.localizedDescription)"
            print("❌ Send error: \(error)")
        }
    }
    
    /// Send current patch via CC messages
    func sendPatchViaCCs() async {
        guard let destination = selectedDestination else {
            statusMessage = "No output device selected"
            return
        }
        
        do {
            // Get all CC messages for this patch
            let ccMessages = patch.toCCMessages()
            
            // Send each CC
            for (cc, value) in ccMessages {
                try await midiManager.send(
                    .controlChange(channel: 0, cc: cc, value: value),
                    to: destination
                )
                
                // Small delay between CCs
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            statusMessage = "Sent \(ccMessages.count) CC messages"
            print("✅ Sent patch via CCs")
            
        } catch {
            statusMessage = "Send failed: \(error.localizedDescription)"
            print("❌ Send error: \(error)")
        }
    }
    
    /// Request patch from device (send SysEx request)
    func requestPatch() async {
        guard let destination = selectedDestination else {
            statusMessage = "No output device selected"
            return
        }
        
        do {
            // Waldorf 4-Pole patch request SysEx
            // Format: F0 3E 04 01 40 00 F7
            let requestSysEx: [UInt8] = [
                0xF0,  // SysEx start
                0x3E,  // Waldorf manufacturer ID
                0x04,  // 4-Pole device ID
                0x01,  // Model ID
                0x40,  // Command: Request Program Dump
                0x00,  // Program number (0)
                0xF7   // SysEx end
            ]
            
            try await midiManager.send(.sysex(requestSysEx), to: destination)
            
            statusMessage = "Requested patch from device..."
            print("✅ Sent patch request")
            
        } catch {
            statusMessage = "Request failed: \(error.localizedDescription)"
            print("❌ Request error: \(error)")
        }
    }
    
    // MARK: - Parameter Editing
    
    /// Update a parameter value
    func updateParameter<T>(_ keyPath: WritableKeyPath<Waldorf4PolePatch, UInt8>, value: UInt8) {
        patch[keyPath: keyPath] = value
        
        // Optional: Send CC immediately for real-time control
        // (Uncomment if you want live parameter updates)
        /*
        Task {
            guard let destination = selectedDestination else { return }
            
            // Find which CC this parameter maps to
            let ccMessages = patch.toCCMessages()
            // ... send the corresponding CC ...
        }
        */
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopListening()
    }
}

// MARK: - Usage Example

/*
 COMPLETE USAGE FLOW:
 ═══════════════════════════════════════════════════════════
 
 // 1. Create ViewModel (in SwiftUI View)
 @State private var viewModel = MIDIEditorViewModel()
 
 // 2. UI bindings work automatically
 Picker("Input", selection: $viewModel.selectedSource) { ... }
 Slider(value: $viewModel.patch.cutoff) { ... }
 
 // 3. User actions trigger async methods
 Button("Connect") {
     Task { await viewModel.connect() }
 }
 
 Button("Send SysEx") {
     Task { await viewModel.sendPatchViaSysEx() }
 }
 
 // 4. Incoming MIDI updates the patch automatically
 // (ViewModel listens in background)
 
 
 DATA FLOW:
 ═══════════════════════════════════════════════════════════
 
 OUTGOING (UI → Device):
 ───────────────────────
 User adjusts slider
     ↓
 updateParameter() called
     ↓
 patch updated (SwiftUI refreshes)
     ↓
 User clicks "Send SysEx"
     ↓
 sendPatchViaSysEx() called
     ↓
 codec.encode(patch) → [UInt8]
     ↓
 midiManager.send() → CoreMIDI
     ↓
 Hardware receives patch
 
 
 INCOMING (Device → UI):
 ───────────────────────
 Hardware sends SysEx
     ↓
 CoreMIDI receives
     ↓
 MIDIManager callback fires
     ↓
 AsyncStream yields data
     ↓
 handleIncomingSysEx() called (MainActor)
     ↓
 codec.decode() → Patch
     ↓
 patch = receivedPatch
     ↓
 SwiftUI automatically refreshes UI
 
 
 ACTOR BOUNDARIES:
 ═══════════════════════════════════════════════════════════
 
 @MainActor (ViewModel)
     ↕ async/await
 Actor (MIDIManager)
     ↕ Task + callback
 CoreMIDI Thread (hardware)
 
 The ViewModel bridges the MainActor (UI) and MIDIManager (actor),
 ensuring thread-safe MIDI communication while keeping UI responsive.
 
 
 TESTING:
 ═══════════════════════════════════════════════════════════
 
 // Mock MIDI Manager for testing
 actor MockMIDIManager: MIDIManager {
     var lastSentBytes: [UInt8]?
     
     override func send(_ message: MIDIMessageType, to device: MIDIDevice) async throws {
         if case .sysex(let bytes) = message {
             lastSentBytes = bytes
         }
     }
 }
 
 // Test ViewModel
 @Test
 func testSendPatch() async {
     let mockMIDI = MockMIDIManager()
     let viewModel = MIDIEditorViewModel(midiManager: mockMIDI)
     
     await viewModel.sendPatchViaSysEx()
     
     XCTAssertNotNil(mockMIDI.lastSentBytes)
 }
 */
