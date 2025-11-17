//
//  VirtualDeviceState.swift
//  Virtual Waldorf 4 Pole Filter
//

import Foundation
import Combine

class VirtualDeviceState: ObservableObject {
    @Published var currentProgram: Int = 0 // 0-19 for programs 1-20
    @Published var deviceID: UInt8 = 0x01
    @Published var programs: [ProgramData] = []
    
    // Global settings
    @Published var globalMidiChannel: UInt8 = 0x01
    @Published var globalMidiControl: UInt8 = 0x01
    @Published var startupProgramID: UInt8 = 0x00
    @Published var globalNoteNumber: UInt8 = 0x3C
    @Published var globalKnobMode: UInt8 = 0x01
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadProgramsFromDump()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .programDumpRequested)
            .sink { [weak self] notification in
                if let programNumber = notification.userInfo?["programNumber"] as? UInt8 {
                    self?.sendProgramDump(Int(programNumber))
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .programBulkDumpRequested)
            .sink { [weak self] notification in
                if let programNumber = notification.userInfo?["programNumber"] as? UInt8 {
                    self?.sendProgramBulkDump(Int(programNumber))
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .allDumpRequested)
            .sink { [weak self] _ in
                self?.sendAllDump()
            }
            .store(in: &cancellables)
    }
    
    private func loadProgramsFromDump() {
        // Parse the all dump sample data
        programs = []
        
        let programData = Array(allDumpSample[5..<585]) // Programs data only
        
        for i in 0..<20 {
            let startIndex = i * 29
            let endIndex = startIndex + 29
            
            guard endIndex <= programData.count else { break }
            
            let bytes = Array(programData[startIndex..<endIndex])
            programs.append(ProgramData(programNumber: UInt8(i), bytes: bytes))
        }
        
        // Load globals
        if allDumpSample.count >= 591 {
            globalMidiChannel = allDumpSample[585]
            globalMidiControl = allDumpSample[586]
            deviceID = allDumpSample[587]
            startupProgramID = allDumpSample[588]
            globalNoteNumber = allDumpSample[589]
            globalKnobMode = allDumpSample[590]
        }
    }
    
    func sendProgramDump(_ programNumber: Int) {
        guard programNumber >= 0 && programNumber < programs.count else { return }
        
        let program = programs[programNumber]
        
        var sysex: [UInt8] = [
            0xF0,           // Start
            0x3E,           // Waldorf
            0x04,           // MiniWorks
            deviceID,       // Device ID
            0x00,           // Program Dump
            UInt8(programNumber) // Program number
        ]
        
        sysex.append(contentsOf: program.bytes)
        
        // Calculate checksum
        let checksum = calculateChecksum(Array(sysex[4..<sysex.count]))
        sysex.append(checksum)
        
        sysex.append(0xF7) // End
        
        MIDIManager.shared.sendSysEx(Data(sysex))
    }
    
    func sendProgramBulkDump(_ programNumber: Int) {
        guard programNumber >= 0 && programNumber < programs.count else { return }
        
        let program = programs[programNumber]
        
        var sysex: [UInt8] = [
            0xF0,           // Start
            0x3E,           // Waldorf
            0x04,           // MiniWorks
            deviceID,       // Device ID
            0x01,           // Program Bulk Dump
            UInt8(programNumber) // Program number
        ]
        
        sysex.append(contentsOf: program.bytes)
        
        // Calculate checksum
        let checksum = calculateChecksum(Array(sysex[4..<sysex.count]))
        sysex.append(checksum)
        
        sysex.append(0xF7) // End
        
        MIDIManager.shared.sendSysEx(Data(sysex))
    }
    
    func sendAllDump() {
        var sysex: [UInt8] = [
            0xF0,           // Start
            0x3E,           // Waldorf
            0x04,           // MiniWorks
            deviceID,       // Device ID
            0x08            // All Dump
        ]
        
        // Add all programs
        for program in programs {
            sysex.append(contentsOf: program.bytes)
        }
        
        // Add globals
        sysex.append(globalMidiChannel)
        sysex.append(globalMidiControl)
        sysex.append(deviceID)
        sysex.append(startupProgramID)
        sysex.append(globalNoteNumber)
        sysex.append(globalKnobMode)
        
        // Calculate checksum (from index 5 to 590)
        let checksum = calculateChecksum(Array(sysex[5..<sysex.count]))
        sysex.append(checksum)
        
        sysex.append(0xF7) // End
        
        MIDIManager.shared.sendSysEx(Data(sysex))
    }
    
    func updateParameter(_ parameter: MiniWorksParameter, value: UInt8) {
        guard currentProgram >= 0 && currentProgram < programs.count else { return }
        
        let byteIndex = parameter.rawValue - 6 // Parameters start at byte 6 in message
        
        guard byteIndex >= 0 && byteIndex < programs[currentProgram].bytes.count else { return }
        
        programs[currentProgram].bytes[byteIndex] = value
        objectWillChange.send()
    }
    
    private func calculateChecksum(_ bytes: [UInt8]) -> UInt8 {
        let sum = bytes.reduce(0) { $0 &+ Int($1) }
        return UInt8((128 - (sum % 128)) & 0x7F)
    }
}

struct ProgramData: Identifiable {
    let id = UUID()
    let programNumber: UInt8
    var bytes: [UInt8]
    
    var name: String {
        "Program \(programNumber + 1)"
    }
    
    subscript(parameter: MiniWorksParameter) -> UInt8 {
        get {
            let index = parameter.rawValue - 6
            guard index >= 0 && index < bytes.count else { return 0 }
            return bytes[index]
        }
        set {
            let index = parameter.rawValue - 6
            guard index >= 0 && index < bytes.count else { return }
            bytes[index] = newValue
        }
    }
}
