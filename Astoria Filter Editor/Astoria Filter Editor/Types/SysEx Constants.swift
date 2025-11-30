//
//  SysExConstants.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/7/25.
//

import Foundation


nonisolated
enum SysExConstant {
//    static let appName: String = ""
    
    static let messageStart: UInt8 = 0xF0   // [0]
    static let manufacturerID: UInt8 = 0x3E // [1]
    static let machineID: UInt8 = 0x04      // [2]
    
    // Type of Response
    static let programDumpMessage: UInt8 = 0x00    // [4]
    static let programBulkDumpMessage: UInt8 = 0x01// [4]
    static let allDumpMessage: UInt8 = 0x08        // [4]

    // Type of Request
    static let programDumpRequest: UInt8 = 0x40
    static let programBulkDumpRequest: UInt8 = 0x41
    static let allDumpRequest: UInt8 = 0x48
    
    static let endOfMessage: UInt8 = 0xF7   // [36 or 592]
    
    static let header: [UInt8] = [messageStart, manufacturerID, machineID]
    
    
    // Globals User Defaults
    static let midiChannelKey = "MIDI_CHANNEL"
    static let midiControlKey = "MIDI_CONTROL"
    static let deviceIDKey = "DEVICE_ID"
    static let startUpProgramIDKey = "START_UP_PROGRAM_ID"
    static let noteNumberKey = "NOTE_NUMBER"
    static let knobModeKey = "KNOB_MODE"
    
    // Notification
    static let parameterType = "parameterType"
    static let parameterValue = "parameterValue"

}


nonisolated
enum ContinuousController {
    static let modulationWheel: UInt8 = 0x01             // CC#1
    static let breathControl: UInt8 = 0x02               // CC#2 - Used for Envelope Display
    
    static let volume: UInt8 = 0x09                      // CC#9
    static let panning: UInt8 = 0x0A                     // CC#10

    static let VCFEnvelopeAttack: UInt8 = 0x0E           // CC#14
    static let VCFEnvelopeDecay: UInt8 = 0x0F            // CC#15
    static let VCFEnvelopeSustain: UInt8 = 0x10          // CC#16
    static let VCFEnvelopeRelease: UInt8 = 0x11          // CC#17
    
    static let VCAEnvelopeAttack: UInt8 = 0x12           // CC#18
    static let VCAEnvelopeDecay: UInt8 = 0x13            // CC#19
    static let VCAEnvelopeSustain: UInt8 = 0x14          // CC#20
    static let VCAEnvelopeRelease: UInt8 = 0x15          // CC#21
    
    static let VCFEnvelopeCutoffAmount: UInt8 = 0x16     // CC#22
    static let VCAEnvelopeVolumeAmount: UInt8 = 0x17     // CC#23
    
    static let LFOSpeed: UInt8 = 0x18                    // CC#24
    static let LFOShape: UInt8 = 0x19                    // CC#25
    static let LFOSpeedModulationAmount: UInt8 = 0x1A    // CC#26
    static let LFOSpeedModulationSource: UInt8 = 0x1B    // CC#27
    
    static let sustainSwitch: UInt8 = 0x40               // CC#64
    
    static let cutoffModulationAmount: UInt8 = 0x46      // CC#70
    static let cutoffModulationSource: UInt8 = 0x47      // CC#71
    
    static let resonanceModulationAmount: UInt8 = 0x48   // CC#72
    static let resonanceModulationSource: UInt8 = 0x49   // CC#73
    
// Manual state '2B', it should be '4B'
    static let volumeModulationSource: UInt8 = 0x4B      // CC#75
    static let volumeModulationAmount: UInt8 = 0x4A      // CC#74
    
    static let panningModulationAmount: UInt8 = 0x4C     // CC#76
    static let panningModulationSource: UInt8 = 0x4D     // CC#77
    
    static let cutoff: UInt8 = 0x4E                      // CC#78
    static let resonance: UInt8 = 0x4F                   // CC#79
    
    static let gateTime: UInt8 = 0x50                    // CC#80
    static let triggerSource: UInt8 = 0x51               // CC#81
    static let triggerMode: UInt8 = 0x52                 // CC#82
    
    static let resetAllControllers: UInt8 = 0x79         // CC#121
    static let allNotesOff: UInt8 = 0x7B                 // CC#123
    
    
    static var allControllers: [UInt8] {
        [modulationWheel, breathControl,
        volume, panning,
        VCFEnvelopeAttack, VCFEnvelopeDecay, VCFEnvelopeSustain, VCFEnvelopeRelease,
        VCAEnvelopeAttack, VCAEnvelopeDecay, VCAEnvelopeSustain, VCAEnvelopeRelease,
        VCFEnvelopeCutoffAmount, VCAEnvelopeVolumeAmount,
        LFOSpeed, LFOShape, LFOSpeedModulationAmount, LFOSpeedModulationSource,
        sustainSwitch,
        cutoffModulationAmount, resonanceModulationAmount, volumeModulationAmount, panningModulationAmount,
        cutoffModulationSource, resonanceModulationSource, volumeModulationSource, panningModulationSource,
        cutoff, resonance,
        gateTime, triggerSource, triggerMode,
        resetAllControllers, allNotesOff]
    }
}

