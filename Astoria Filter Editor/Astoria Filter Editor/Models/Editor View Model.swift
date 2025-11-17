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
    
    var availableSources: [MIDIDevice] = []
    var availableDestinations: [MIDIDevice] = []
    
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
        availableSources = await midiService.availableSources()
        availableDestinations = await midiService.availableDestinations()
        
        if !availableSources.isEmpty {
            selectedSource = availableSources.first
        }
        
        if !availableDestinations.isEmpty {
            selectedDestination = availableDestinations.first
        }
        
        statusMessage = "Found \(availableSources.count) source(s) and \(availableDestinations.count) destination(s)."
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
            debugPrint(icon: "❌", message: "Error: \(error)")
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
             'await midiService.sysexStream(from: device) ->
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
        debugPrint(icon: "📡", message: "Attempting to decode SysEx:  size: \(sysexData.count) \n\(sysexData.hexString)")
        
        do {
            if sysexData.count > 40 {
                let receivedConfig = try MiniworksSysExCodec.decodeAllDump(bytes: sysexData)
                configuration = receivedConfig
                debugPrint(icon: "📡", message: "Config (All Dump) SysEx Decoded!!!!")
            }
            else {
                let receivedProgram = try MiniworksSysExCodec.decodeProgram(from: sysexData)
                program = receivedProgram
                debugPrint(icon: "📡", message: "Program SysEx Decoded!!!!")
            }
        }
        catch {
            debugPrint(icon: "📡", message: "Failed to decode SysEx: \n\(error.localizedDescription)")
        }
    }
    
    
    private func handleIncomingCC(channel: UInt8, cc: UInt8, value: UInt8) {
        program.updateFromCC(cc, value: value, onChannel: channel)
    }
    
    
    // MARK: - Updates from UI
    
    func updateCC(from parameter: ProgramParameter) {
        debugPrint(icon: "🎛️", message: "Update \(parameter.type.rawValue), CC: \(parameter.ccValue), Value: \(parameter.value)")

        Task {
            try await midiService.send(.controlChange(channel: 1, cc: parameter.ccValue, value: parameter.value), to: selectedDestination)
        }
    }
    
    
    func selectProgram(_ program: Int) {
        debugPrint(icon: "🎛️", message: "Selecting program: \(program)")
        
        Task {
            try await midiService.send(.programChange(program: UInt8(program)), to: selectedDestination)
        }
    }
    
}
