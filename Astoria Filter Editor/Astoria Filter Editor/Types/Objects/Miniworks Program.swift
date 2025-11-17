//
//  MiniWorks Program.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


@Observable
class MiniWorksProgram: Identifiable, Sendable {
    var id: UUID = UUID()
    private(set) var isReadOnly: Bool = false
    
    var programNumber: UInt8 = 0
    var programName: String = "No Name"
    
    var vcfEnvelopeAttack = ProgramParameter(type: .VCFEnvelopeAttack)
    var vcfEnvelopeDecay = ProgramParameter(type: .VCFEnvelopeDecay)
    var vcfEnvelopeSustain = ProgramParameter(type: .VCFEnvelopeSustain)
    var vcfEnvelopeRelease = ProgramParameter(type: .VCFEnvelopeRelease)
    var vcfEnvelopeCutoffAmount = ProgramParameter(type: .VCFEnvelopeCutoffAmount)
    
    var cutoff = ProgramParameter(type: .cutoff)
    var cutoffModulationAmount = ProgramParameter(type: .cutoffModulationAmount)
    var cutoffModulationSource = ProgramParameter(type: .cutoffModulationSource)
    
    var resonance = ProgramParameter(type: .resonance)
    var resonanceModulationAmount = ProgramParameter(type: .resonanceModulationAmount)
    var resonanceModulationSource = ProgramParameter(type: .resonanceModulationSource)
    
    var vcaEnvelopeAttack = ProgramParameter(type: .VCAEnvelopeAttack)
    var vcaEnvelopeDecay = ProgramParameter(type: .VCAEnvelopeDecay)
    var vcaEnvelopeSustain = ProgramParameter(type: .VCAEnvelopeSustain)
    var vcaEnvelopeRelease = ProgramParameter(type: .VCAEnvelopeRelease)
    var vcaEnvelopeVolumeAmount = ProgramParameter(type: .VCAEnvelopeVolumeAmount)
    
    var volume = ProgramParameter(type: .volume)
    var volumeModulationAmount = ProgramParameter(type: .volumeModulationAmount)
    var volumeModulationSource = ProgramParameter(type: .volumeModulationSource)
    
    var lfoSpeed = ProgramParameter(type: .LFOSpeed)
    var lfoSpeedModulationAmount = ProgramParameter(type: .LFOSpeedModulationAmount)
    
    var lfoShape = ProgramParameter(type: .LFOShape)
    var lfoSpeedModulationSource = ProgramParameter(type: .LFOSpeedModulationSource)
    
    var panning = ProgramParameter(type: .panning)
    var panningModulationAmount = ProgramParameter(type: .panningModulationAmount)
    var panningModulationSource = ProgramParameter(type: .panningModulationSource)
    
    var gateTime = ProgramParameter(type: .gateTime)
    var triggerSource = ProgramParameter(type: .triggerSource)
    var triggerMode = ProgramParameter(type: .triggerMode)
    
    
    private var properties: [ProgramParameter] {
        [
            vcfEnvelopeAttack, vcfEnvelopeDecay, vcfEnvelopeSustain, vcfEnvelopeRelease,
            vcaEnvelopeAttack, vcaEnvelopeDecay, vcaEnvelopeSustain, vcaEnvelopeRelease,
            
            vcfEnvelopeCutoffAmount, vcaEnvelopeVolumeAmount,
            
            lfoSpeed, lfoSpeedModulationAmount, lfoShape, lfoSpeedModulationSource,
            
            cutoffModulationAmount, resonanceModulationAmount,
            volumeModulationAmount, panningModulationAmount,
            
            cutoffModulationSource, resonanceModulationSource,
            volumeModulationSource, panningModulationSource,
            
            cutoff, resonance, volume, panning,
            gateTime, triggerSource, triggerMode
        ]
    }
    
    
    func updateFromCC(_ cc: UInt8, value: UInt8, onChannel: UInt8) {
        debugPrint(icon: "🎛️", message: "Update from CC: \(cc), Value: \(value)")
        // TODO: Needs to check channel against device's channel
        
        if let parameter = properties.first(where: { $0.ccValue == cc}) {
            parameter.setValue(value)
        }
        else {
            debugPrint(icon: "❌", message: "No parameter found for CC: \(cc)")
        }
    }
    
}


extension MiniWorksProgram {
    
        /// Creates 'Program' from raw dump
    convenience init?(bytes: [UInt8]) throws {
        try MiniworksSysExCodec.validate(sysEx: bytes)
        
        let programData: [UInt8] = Array(bytes[6..<bytes.count])
        
            // Adjust the program number from 0 index
        self.init(bytes: programData, number: bytes[5])
    }
    
    
        /// Creates 'Program' from  'Program' related bytes
        /// - Used by 'All Dump'
    convenience init(bytes: [UInt8], number: UInt8) {
        self.init()
        
        programNumber = number
        
        properties.forEach { $0.use(bytes: bytes) }
    }
    
    
    
    static func copyROM(_ data: [UInt8]) -> MiniWorksProgram {
        if let program = try? MiniWorksProgram(bytes: data) {
            return program
        }
        else {
            return MiniWorksProgram()
        }
    }
    
    
    func encodeToBytes(forAllDump: Bool = false) -> [UInt8] {
        var bytes = properties.map { $0.value }
        
        if forAllDump {
            bytes.removeFirst(1)
        }
        
        return bytes
    }
    
}


extension MiniWorksProgram: CustomStringConvertible {
    var description: String {
        let num = "\(programNumber)"
        let props = "\(properties.map(\.description).joined(separator: "\n"))"
        
        return "\nMiniWorksProgram #\(num)\n\n\(props)"
    }
}


/*
 Byte order in Program and Bulk Dump
 
 Start of SysEx = bytes[0] (0xF0)
 Waldorf ID = bytes[1] (0x3E)
 Miniworks Model ID = bytes[2] (0x04)
 Device ID = bytes[3] (0x?? - User Set)
 Dump Type = bytes[4] (0x00 or 01) = Program, (0x08) = All
 
 -> Program <-
 
 programNumber = bytes[5]
 
 -> ??? Add Dump ??? <-
 -> Subtract 1 from index below <-
 
 vcfEnvelopeAttack = bytes[6]
 vcfEnvelopeDecay = bytes[7]
 vcfEnvelopeSustain = bytes[8]
 vcfEnvelopeRelease = bytes[9]
 
 vcaEnvelopeAttack = bytes[10]
 vcaEnvelopeDecay = bytes[11]
 vcaEnvelopeSustain = bytes[12]
 vcaEnvelopeRelease = bytes[13]
 
 vcfEnvelopeCutoffAmount = bytes[14]
 vcaEnvelopeVolumeAmount = bytes[15]
 
 lfoSpeed = bytes[16]
 lfoSpeedModulationAmount = bytes[17]
 lfoShape = LFOShape(rawValue: bytes[18]) ?? .sine
 lfoSpeedModulationSource = ModulationSource(rawValue: bytes[19]) ?? .off
 
 cutoffModulationAmount = bytes[20]
 resonanceModulationAmount = bytes[21]
 volumeModulationAmount = bytes[22]
 panningModulationAmount = bytes[23]
 
 cutoffModulationSource = ModulationSource(rawValue: bytes[24]) ?? .off
 resonanceModulationSource = ModulationSource(rawValue: bytes[25]) ?? .off
 volumeModulationSource = ModulationSource(rawValue: bytes[26]) ?? .off
 panningModulationSource = ModulationSource(rawValue: bytes[27]) ?? .off
 
 cutoff = bytes[28]
 resonance = bytes[29]
 volume = bytes[30]
 panning = bytes[31]
 
 gateTime = bytes[32]
 triggerSource = TriggerSource(rawValue: bytes[33]) ?? .audio
 triggerMode = TriggerMode(rawValue: bytes[34]) ?? .single
 
 
 -> Program Dump <-
 Checksum = bytes[35]
 End of SysEx = bytes[36] (0xF7)

 */
