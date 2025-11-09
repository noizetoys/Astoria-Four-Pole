//
//  MiniWorks Program.swift
//  4 Pole for the Win
//
//  Created by James B. Majors on 11/6/25.
//

import Foundation


class MiniWorksProgram: Codable, Identifiable {
    var id: UUID = UUID()
    private(set) var isReadOnly: Bool = false
    
    var programNumber: Int = 0
    var programName: String = "No Name"
    
    var vcfEnvelopeAttack: UInt8 = 64
    var vcfEnvelopeDecay: UInt8 = 64
    var vcfEnvelopeSustain: UInt8 = 64
    var vcfEnvelopeRelease: UInt8 = 64
    var vcfEnvelopeCutoffAmount: UInt8 = 64
    
    var cutoff: UInt8 = 64
    var cutoffModulationAmount: UInt8 = 64
    var cutoffModulationSource: ModulationSource = .off
    
    var resonance: UInt8 = 64
    var resonanceModulationAmount: UInt8 = 64
    var resonanceModulationSource: ModulationSource = .off

    var vcaEnvelopeAttack: UInt8 = 64
    var vcaEnvelopeDecay: UInt8 = 64
    var vcaEnvelopeSustain: UInt8 = 64
    var vcaEnvelopeRelease: UInt8 = 64
    var vcaEnvelopeVolumeAmount: UInt8 = 64
    
    var volume: UInt8 = 64
    var volumeModulationAmount: UInt8 = 64
    var volumeModulationSource: ModulationSource = .off

    var lfoSpeed: UInt8 = 64
    var lfoSpeedModulationAmount: UInt8 = 64
    var lfoShape: LFOShape = .sine
    var lfoSpeedModulationSource: ModulationSource = .off
    
    var panning: UInt8 = 64
    var panningModulationAmount: UInt8 = 64
    var panningModulationSource: ModulationSource = .off
    
    var gateTime: UInt8 = 64
    var triggerSource: TriggerSource = .audio
    var triggerMode: TriggerMode = .single

    
    /// Creates 'Program' from raw dump
    convenience init?(data: Data) throws {
        let bytes = [UInt8](data)
        
        do {
            let isValid = try? SysExMessage.isValidHeader(data: data)
            
            if isValid == true {
                let programData: [UInt8] = Array(bytes[6..<bytes.count])
                
                // Adjust the program number from 0 index
                self.init(bytes: programData, number: Int(bytes[5]) + 1)
            }
            else { throw MiniWorksError.malformedMessage(data) }
        }
        catch { throw error }
    }
    
    
    /// Creates 'Program' from  'Program' related bytes
    /// - Used by 'All Dump'
    convenience
    init(bytes: [UInt8], number: Int) {
        self.init()
        
        programNumber = number
        
        vcfEnvelopeAttack = bytes[0]
        vcfEnvelopeDecay = bytes[1]
        vcfEnvelopeSustain = bytes[2]
        vcfEnvelopeRelease = bytes[3]
        
        vcaEnvelopeAttack = bytes[4]
        vcaEnvelopeDecay = bytes[5]
        vcaEnvelopeSustain = bytes[6]
        vcaEnvelopeRelease = bytes[7]
        
        vcfEnvelopeCutoffAmount = bytes[8]
        vcaEnvelopeVolumeAmount = bytes[9]
        
        lfoSpeed = bytes[10]
        lfoSpeedModulationAmount = bytes[11]
        lfoShape = LFOShape(rawValue: bytes[12]) ?? .sine
        lfoSpeedModulationSource = ModulationSource(rawValue: bytes[13]) ?? .off
        
        cutoffModulationAmount = bytes[14]
        resonanceModulationAmount = bytes[15]
        volumeModulationAmount = bytes[16]
        panningModulationAmount = bytes[17]
        
        cutoffModulationSource = ModulationSource(rawValue: bytes[18]) ?? .off
        resonanceModulationSource = ModulationSource(rawValue: bytes[19]) ?? .off
        volumeModulationSource = ModulationSource(rawValue: bytes[20]) ?? .off
        panningModulationSource = ModulationSource(rawValue: bytes[21]) ?? .off
        
        cutoff = bytes[22]
        resonance = bytes[23]
        volume = bytes[24]
        panning = bytes[25]
        
        gateTime = bytes[26]
        triggerSource = TriggerSource(rawValue: bytes[27]) ?? .audio
        triggerMode = TriggerMode(rawValue: bytes[28]) ?? .single
    }
    
    
    static func copyROM(_ data: Data) -> MiniWorksProgram {
        if let program = try? MiniWorksProgram(data: data) {
            return program
        }
        else {
            return MiniWorksProgram()
        }
    }
    
    
    func encodeToBytes(forAllDump: Bool = false) -> [UInt8] {
        var bytes: [UInt8] = [
            UInt8(programNumber),
            
            vcfEnvelopeAttack,
            vcfEnvelopeDecay,
            vcfEnvelopeSustain,
            vcfEnvelopeRelease,
            
            vcaEnvelopeAttack,
            vcaEnvelopeDecay,
            vcaEnvelopeSustain,
            vcaEnvelopeRelease,
            
            vcfEnvelopeCutoffAmount,
            vcaEnvelopeVolumeAmount,
            
            lfoSpeed,
            lfoSpeedModulationAmount,
            UInt8(lfoShape.rawValue),
            UInt8(lfoSpeedModulationSource.rawValue),
            
            cutoffModulationAmount,
            resonanceModulationAmount,
            volumeModulationAmount,
            panningModulationAmount,
            
            UInt8(cutoffModulationSource.rawValue),
            UInt8(resonanceModulationSource.rawValue),
            UInt8(volumeModulationSource.rawValue),
            UInt8(panningModulationSource.rawValue),
            
            cutoff,
            resonance,
            volume,
            panning,
            
            gateTime,
            UInt8(triggerSource.rawValue),
            UInt8(triggerMode.rawValue)
        ]
        
        if forAllDump {
            bytes.removeFirst(1)
        }
        
        return bytes
    }
    
}

/*
 Byte order in Program and Bulk Dump
 
 programNumber = bytes[5]
 
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
 */
