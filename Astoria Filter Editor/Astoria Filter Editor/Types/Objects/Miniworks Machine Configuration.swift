//
//  Machine Configuration.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation


/// Reflects the current state of the device including user programs and global settings
class MachineConfiguration: Identifiable, Codable, Sendable {
    var id: Date
    
    // (20) User Programs (1...20)
    var programs: [MiniWorksProgram] = []
    
    // (20) Read Only programs (21...40)
    // Loaded from app, available to copy
    var ROMprograms: [MiniWorksProgram] = []
    
    var globalSetup: MiniWorksGlobalData = .init()
    
    
    // Pass through for 'globalSetup' object
    // TODO: - Add to User Defaults
    var midiChannel: UInt8 {
        get { globalSetup.midiChannel }
        set(newValue) { globalSetup.midiChannel = newValue }
    }
    
    var midiControl: GlobalMIDIControl {
        get { globalSetup.midiControl }
        set(newValue) { globalSetup.midiControl = newValue }
    }
    
    var deviceID: UInt8 {
        get { globalSetup.deviceID }
        set(newValue) { globalSetup.deviceID = newValue }
    }
    
    var startUpProgramID: UInt8 {
        get { globalSetup.startUpProgramID }
        set(newValue) { globalSetup.startUpProgramID = newValue }
    }
    
    var noteNumber: UInt8 {
        get { globalSetup.noteNumber }
        set(newValue) { globalSetup.noteNumber = newValue }
    }
    
    var knobMode: GlobalKnobMode {
        get { globalSetup.knobMode }
        set(newValue) { globalSetup.knobMode = newValue }
    }
    
    
    // MARK: - Lifecycle
    
    init(id: Date = .now, programs: [MiniWorksProgram], globals: MiniWorksGlobalData) {
        self.id = id
        self.programs = programs
        self.globalSetup = globals
    }
    
    
    // MARK: - Public
    
    func program(number programNumber: Int) -> MiniWorksProgram {
        programs[programNumber - 1]
    }
    
    
    func updateProgram(_ program: MiniWorksProgram, number programNumber: Int) {
        programs[programNumber - 1] = program
    }
    
    
    // MARK: - Encode
    
    func encodeToBytes() -> [UInt8] {
        var programBytes: [UInt8] = []
        
        // Seperated to make debugging easier
        for program in programs {
            programBytes.append(contentsOf: program.encodeToBytes(forAllDump: true))
        }
        
        var globalBytes: [UInt8] = []
        globalBytes.append(contentsOf: globalSetup.encodeToBytes())
        
        return programBytes + globalBytes
    }
    
}

/*
 Byte order in All Dump
 
 Header:
 
 Start of Sys Ex. = bytes[0] -> F0
 Manufacturer ID (Waldorf) = bytes[1] -> 3E
 Machine ID (4 Pole Filter) = bytes[2] -> 04
 Device ID <User Settable> = bytes[3] ->  Default = 0
 Message Type = bytes[4] -> 08 (All Dump)

 vcfEnvelopeAttack = bytes[5]
 vcfEnvelopeDecay = bytes[6]
 vcfEnvelopeSustain = bytes[7]
 vcfEnvelopeRelease = bytes[8]
 
 vcaEnvelopeAttack = bytes[9]
 vcaEnvelopeDecay = bytes[10]
 vcaEnvelopeSustain = bytes[11]
 vcaEnvelopeRelease = bytes[12]
 
 vcfEnvelopeCutoffAmount = bytes[13]
 vcaEnvelopeVolumeAmount = bytes[14]
 
 lfoSpeed = bytes[15]
 lfoSpeedModulationAmount = bytes[16]
 lfoShape = bytes[17]
 lfoSpeedModulationSource = bytes[18]
 
 cutoffModulationAmount = bytes[19]
 resonanceModulationAmount = bytes[20]
 volumeModulationAmount = bytes[21]
 panningModulationAmount = bytes[22]
 
 cutoffModulationSource bytes[23]
 resonanceModulationSource bytes[24]
 volumeModulationSource bytes[25]
 panningModulationSource bytes[26]
 
 cutoff = bytes[27]
 resonance = bytes[28]
 volume = bytes[29]
 panning = bytes[30]
 
 gateTime = bytes[31]
 triggerSource = bytes[32]
 triggerMode = bytes[33]
 
 Program 1 = 5...33
 Program 2 = 34...62
 Program 3...20 = 63...584
 
 ** Global Parameters **
 
 MIDI Channel = 585
 MIDI Control = 586
 Device ID = 587
 Start Up Program = 588
 MIDI Note Number = 589
 Knob Mode = 590
 
 Checksum (CHK) = 591 (bytes 5-590, bit 7 removed)
 
 End of Sys. Ex = bytes[592] -> F7
 */
