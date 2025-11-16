//
//  Editor View Model.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/15/25.
//

import Foundation


@MainActor
@Observable
final class EditorViewModel {
    
    var availableSource: [MIDIDevice] = []
    var availableDestination: [MIDIDevice] = []
    
    var selectedSource: MIDIDevice?
    var selectedDestination: MIDIDevice?
    
    var isConnected: Bool = false
    
    var statusMessage: String = ""
    
    // Default Program
    var program: MiniWorksProgram = MiniWorksProgram()
    var configuration: MiniworksDeviceProfile = .newMachineConfiguration()
    var codec: MiniworksSysExCodec = MiniworksSysExCodec()
    
    
    private let midiService: MIDIService = .shared
    
    private var sysExListenerTask: Task<Void, Never>?
    private var ccListenerTask: Task<Void, Never>?
    
    
    // MARK: - Lifecycle
    
    init() {
        Task {
            await refreshDevices()
        }
    }
    
    
    // MARK: - Device Discovery
    
    func refreshDevices() async {
        availableSource = await midiService.availableSources()
        availableDestination = await midiService.availableDestinations()
        
        if !availableSource.isEmpty {
            selectedSource = availableSource.first
        }
        
        if !availableDestination.isEmpty {
            selectedDestination = availableDestination.first
        }
        
        statusMessage = "Found \(availableSource.count) source(s) and \(availableDestination.count) destination(s)."
    }
    
    
    // MARK: - Connection Management
    
    func connect() async {
        guard
            let source = selectedSource,
            let destination = selectedDestination
        else {
            statusMessage = "Please select a source and a destination."
            return
        }
        
        do {
            try await midiService.connect(source: source, destination: destination)
            isConnected = true
            statusMessage = "Connected to \(source.name) and \(destination.name)."
            
            startListening(from: source)
        }
        catch {
            statusMessage = "Failed to connect: \(error.localizedDescription)"
            isConnected = false
        }
    }
    
    
    func disconnect() async {
        guard let selectedSource
        else { return }
        
        stopListening()
        
        await midiService.disconnect(from: selectedSource)
        
        isConnected = false
        statusMessage = "Disconnected."
    }
    
    
    // MARK: - Incoming MIDI Handling
    
    private func startListening(from source: MIDIDevice) {
        sysExListenerTask = Task { [weak self] in
            guard let self else { return }
            
            /*
             'await sysData' -> "Wait for the data from the Stream"
             'await ...sysexStream(from: device) ->
             */
            for await sysexData in await self.midiService.sysexStream(from: source) {
                self.handleIncomingSysEx(sysexData)
            }
        }
        
        
        ccListenerTask = Task { [weak self] in
            guard let self else { return }
            
            for await (channel, cc, value) in await self.midiService.ccStream(from: source) {
                self.handleIncomingCC(channel: channel, cc: cc, value: value)
            }
        }
        
    }
    
    
    private func stopListening() {
        sysExListenerTask?.cancel()
        sysExListenerTask = nil
        
        ccListenerTask?.cancel()
        ccListenerTask = nil
    }
    
    
    private func handleIncomingSysEx(_ sysexData: [UInt8]) {
//        do {
//            let receivedPatch = try codec.decoce
//            self.patch = receivedPatch
            
//            statusMessage = "Received patch: \(receivedPatch.name)"
//        }
//        catch {
//            statusMessage = "Failed to decode SysEx: \(error.localizedDescription)"
//        }
    }
    
    
    private func handleIncomingCC(channel: UInt8, cc: UInt8, value: UInt8) {
//        patch.updateFromCC(cc, value: value, onChannel: channel))
    }
    
}
