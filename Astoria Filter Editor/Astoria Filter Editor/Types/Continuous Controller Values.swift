//
//  Continuous Controller Values.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


enum ContinuousControllerValue: UInt8, Codable, CaseIterable {
    case modulationWheel = 0x01             // CC#1
    case breathControl = 0x02               // CC#2 - Used for Envelope Display
    
    case volumeParameter = 0x09             // CC#9
    case panningParameter = 0x0A            // CC#10
    
    case VCFEnvelopeAttack = 0x0E           // CC#14
    case VCFEnvelopeDecay = 0x0F            // CC#15
    case VCFEnvelopeSustain = 0x10          // CC#16
    case VCFEnvelopeRelease = 0x11          // CC#17
    
    case VCAEnvelopeAttack = 0x12           // CC#18
    case VCAEnvelopeDecay = 0x13            // CC#19
    case VCAEnvelopeSustain = 0x14          // CC#20
    case VCAEnvelopeRelease = 0x15          // CC#21
    
    case VCFEnvelopeCutoffAmount = 0x16     // CC#22
    case VCAEnvelopeVolumeAmount = 0x17     // CC#23
    
    case LFOSpeed = 0x18                    // CC#24
    case LFOShape = 0x19                    // CC#25
    case LFOSpeedModulationAmount = 0x1A    // CC#26
    case LFOSpeedModulationSource = 0x1B    // CC#27
    
    case sustainSwitch = 0x40               // CC#64
    
    case cutoffModulationAmount = 0x46      // CC#70
    case cutoffModulationSource = 0x47      // CC#71
    
    case resonanceModulationAmount = 0x48   // CC#72
    case resonanceModulationSource = 0x49   // CC#73
    
    case volumeModulationAmount = 0x4A      // CC#74
    case volumeModulationSource = 0x2A      // CC#75
    
    case panningModulationAmount = 0x4C     // CC#76
    case panningModulationSource = 0x4D     // CC#77
    
    case cutoff = 0x4E                      // CC#78
    case resonance = 0x4F                   // CC#79
    
    case gateTime = 0x50                    // CC#80
    case triggerSource = 0x51               // CC#81
    case triggerMode = 0x52                 // CC#82
    
    case resetAllControllers = 0x79         // CC#121
    case allnotesOff = 0x7B                 // CC#123
}
