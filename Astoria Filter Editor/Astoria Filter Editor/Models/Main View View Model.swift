//
//  Main View View Model.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/24/25.
//

import Foundation


@MainActor
@Observable
final class MainViewModel {
    var availableSources: [MIDIDevice] = []
    var availableDestinations: [MIDIDevice] = []
    
    var selectedSource: MIDIDevice?
    var selectedDestination: MIDIDevice?
    
    var isConnected: Bool = false
    
    var statusMessage: String = ""
    
    var breathControllerValue: UInt8 = 0
    
    // Passed in from App
    var deviceProfile: MiniworksDeviceProfile
    var program: MiniWorksProgram? {
        didSet {
            if program == nil {
                self.deRegisterForNotifications()
            }
            else {
                self.registerForNotifications()
            }
        }
    }
    
        // A Default device has the ROMs copied into User Programs 1-20
    var programs: [MiniWorksProgram] = MiniworksROMPrograms.copyOfROMPrograms()
    let ROMPrograms: [MiniWorksProgram] = MiniworksROMPrograms.programs()
    
    
   // MARK: - Private
    
    private let midiService: MIDIService = .shared
    private let codec: MiniworksSysExCodec = MiniworksSysExCodec()
    
    private var sysExListenerTask: Task<Void, Never>?
    private var ccListenerTask: Task<Void, Never>?
    private var noteListenerTask: Task<Void, Never>?
    private var programChangeListenerTask: Task<Void, Never>?
    
    
        // MARK: - Lifecycle
    
    init(profile: MiniworksDeviceProfile) {
        self.deviceProfile = profile
        
        // For Testing
        do {
            program = try MiniworksROMPrograms.program(1)
        }
        catch { }
        
        Task {
            await refreshDevices()
        }
    }
    
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(forName: .programParameterUpdated,
                                               object: nil,
                                               queue: .main) { notification in
            
            debugPrint(message: "received notification: data: \(notification.userInfo?.debugDescription)", type: .info)
            guard
                let data = notification.userInfo,
                let type = data[SysExConstant.parameterType] as? MiniWorksParameter,
                let value = data[SysExConstant.parameterValue] as? UInt8
            else {
                debugPrint(message: "Issue trying to send Midi message: data: \(notification.userInfo?.debugDescription)", type: .error)
                return
            }
            
            Task {
                do {
                    try await MIDIService.shared.send(.controlChange(channel: 1,
                                                                     cc: type.ccValue,
                                                                     value: value), to: self.selectedDestination)
                }
                catch {
                    debugPrint(message: "Could not send control change message: type: \(type), value: \(value)", type: .error)
                }
            }
        }
    }
    
    
    private func deRegisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
        // MARK: - Device Discovery
    
    func refreshDevices() async {
        availableSources = await midiService.availableSources()
        availableDestinations = await midiService.availableDestinations()
        
        let sourcesDetected = !availableSources.isEmpty
        if sourcesDetected {
            selectedSource = availableSources.first
        }
        
        let destinationsDetected = !availableDestinations.isEmpty
            if destinationsDetected {
            selectedDestination = availableDestinations.first
        }
        
        if sourcesDetected && destinationsDetected {
            statusMessage = "Ready to Connect..."
        }
        else if sourcesDetected && !destinationsDetected {
            statusMessage = "No Destinations Found"
        }
        else if !sourcesDetected && destinationsDetected {
            statusMessage = "No Sources Found"
        }
        else {
            statusMessage = "Not able to connect"
        }
//        statusMessage = "Found \(availableSources.count) source(s) and \(availableDestinations.count) destination(s)."
    }
    
    
        // MARK: - Connection Management
    
    func connect() async {
        debugPrint(message: "This is as far as it goes!!!!")
        
        guard
            let destination = selectedDestination
        else {
            statusMessage = "Must choose at least destination."
            return
        }
        
        
        do {
            try await midiService.connect(source: selectedSource, destination: destination)
            isConnected = true
            statusMessage = "Connected to \(selectedSource?.name ?? "No Source") and \(destination.name)."
            
            if let selectedSource {
                startListening(from: selectedSource)
            }
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
        
        
        /* need to know which CC controller to monitor
         should default to breath.
         
         */
        
        noteListenerTask = Task { [weak self] in
            guard let self else { return }
            
            for await (isNoteOn, channel, note, velocity) in await self.midiService.noteStream(from: source) {
                debugPrint(message: "Received: \(isNoteOn ? "Note On" : "Note off"), ch: \(channel), note: \(note), vel: \(velocity)")
                
                if self.isValidChannel(channel), note == deviceProfile.noteNumber {
                    self.handingIncomingNote(isNoteOn: isNoteOn, channel: channel, note: note, velocity: velocity)
                }
            }
        }
    }
    
    
    private func stopListening() {
        sysExListenerTask?.cancel()
        sysExListenerTask = nil
        
        ccListenerTask?.cancel()
        ccListenerTask = nil
        
        noteListenerTask?.cancel()
        noteListenerTask = nil
    }
    
    
    private func handleIncomingSysEx(_ sysexData: [UInt8]) {
        debugPrint(icon: "➡️📡", message: "Attempting to decode SysEx:  size: \(sysexData.count) \n\(sysexData.hexString)", type: .info)
        
        do {
            if sysexData.count > 40 {
                let receivedConfig = try MiniworksSysExCodec.decodeAllDump(bytes: sysexData)
                deviceProfile = receivedConfig
                debugPrint(icon: "➡️📡", message: "Config (All Dump) SysEx Decoded!!!!")
            }
            else {
                let receivedProgram = try MiniworksSysExCodec.decodeProgram(from: sysexData)
                program = receivedProgram
                debugPrint(icon: "🎹", message: "Received Program: \(receivedProgram)", type: .info)
                debugPrint(icon: "➡️📡", message: "Program SysEx Decoded!!!!")
            }
        }
        catch {
            debugPrint(icon: "➡️📡❌", message: "Failed to decode SysEx: \n\(error.localizedDescription)")
        }
    }
    
    
    private func handleIncomingCC(channel: UInt8, cc: UInt8, value: UInt8) {
        debugPrint(icon: "➡️🎛️", message: "Channel: \(channel), controller: \(cc), value: \(value)")
        
        if isValidChannel(channel), isValidCC(cc) {
            if cc == ContinuousController.breathControl {
                breathControllerValue = value
            }
            
                // Program Change????
            
            program?.updateFromCC(cc, value: value, onChannel: channel)
        }
    }
    
    
    private func handingIncomingNote(isNoteOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8) {
            // Note On:  Triggers Envelope,
            // Note Off: Trigger Sequence Ends
        
        guard
            isValidChannel(channel),
            isValidNote(note)
        else {
            return
        }
        
        debugPrint(icon: "➡️♬", message: "Received: \(isNoteOn ? "Note On" : "Note off"), ch: \(channel), note: \(note), vel: \(velocity)")
    }
    
    
        // MARK: - MIDI Property Validation
    
    private func isValidCC(_ controller: UInt8) -> Bool {
        ContinuousController.allControllers.contains(controller)
    }
    
    
    private func isValidChannel(_ channel: UInt8) -> Bool {
        channel == 0 || channel == deviceProfile.midiChannel
    }
    
    
    private func isValidNote(_ note: UInt8) -> Bool {
        note == deviceProfile.noteNumber
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
                // TODO: - Update to Data Service
            self.program = try MiniworksROMPrograms.program(program + 21)
                //            try await midiService.send(.programChange(program: UInt8(program)), to: selectedDestination)
        }
    }
    
    
    func requestLoadProgram(_ number: Int, isROM: Bool) throws {
        debugPrint(icon: "👇🏻", message: "Loading \(isROM ? "ROM" : "") Program #\(number + 1)", type: .trace)
        
        guard !isROM
        else {
            program = try MiniworksROMPrograms.program(number)
            return
        }
        
        Task {
            try await midiService.send(.programChange(channel: 1, program: UInt8(number)), to: selectedDestination)
            
            do {
                let sysExData = try SysExMessageType.programDumpRequest(UInt8(number)).requestMessage()
                try await MIDIService.shared.sendSysEx(sysExData, to: selectedDestination)
            }
            catch {
                throw MIDIError.sendFailed("Status Error: \(error.localizedDescription)")
            }
            
        }
    }
    
    
    func requestLoadAllPrograms() throws {
        debugPrint(icon: "👇🏻", message: "Requestion All Dump", type: .trace)
        
        Task {
            do {
                let sysExData = try SysExMessageType.allDumpRequest.requestMessage()
                try await MIDIService.shared.sendSysEx(sysExData, to: selectedDestination)
            }
            catch {
                throw MIDIError.sendFailed("Status Error: \(error.localizedDescription)")
            }
            
        }
    }
}
