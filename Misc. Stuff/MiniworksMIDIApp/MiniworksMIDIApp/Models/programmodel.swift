//
//  ProgramModel.swift
//  MiniWorksMIDI
//
//  Represents a complete MiniWorks program with all synthesis parameters.
//  This model is Codable for JSON serialization and includes methods to
//  convert to/from SysEx format.
//
//  SysEx format for Program Dump:
//  F0 3E 04 00 <program#> <param1> <param2> ... <paramN> <checksum> F7
//
//  Parameters are 7-bit MIDI values (0-127) representing various synthesis
//  parameters like oscillator pitch, filter cutoff, envelope times, etc.
//

import Foundation
import Combine


@MainActor
class ProgramModel: ObservableObject, Codable {
    // Oscillator parameters
    @Published var osc1Pitch: Int = 64
    @Published var osc1Fine: Int = 64
    @Published var osc2Pitch: Int = 64
    @Published var osc2Fine: Int = 64
    @Published var osc2Detune: Int = 0
    @Published var oscMix: Int = 64
    @Published var pwm: Int = 0
    @Published var pwmSource: ModSource = .off
    
    // Filter parameters (VCF)
    @Published var cutoff: Int = 64
    @Published var resonance: Int = 0
    @Published var vcfEnvAmount: Int = 64
    @Published var vcfKeytrack: Int = 0
    @Published var vcfModAmount: Int = 0
    @Published var vcfModSource: ModSource = .lfo1
    
    // VCF Envelope
    @Published var vcfAttack: Int = 0
    @Published var vcfDecay: Int = 64
    @Published var vcfSustain: Int = 100
    @Published var vcfRelease: Int = 40
    
    // Amplifier parameters (VCA)
    @Published var volume: Int = 100
    @Published var vcaModAmount: Int = 0
    @Published var vcaModSource: ModSource = .off
    
    // VCA Envelope
    @Published var vcaAttack: Int = 0
    @Published var vcaDecay: Int = 64
    @Published var vcaSustain: Int = 100
    @Published var vcaRelease: Int = 40
    
    // LFO parameters
    @Published var lfo1Rate: Int = 40
    @Published var lfo1Amount: Int = 0
    @Published var lfo2Rate: Int = 60
    @Published var lfo2Amount: Int = 0
    
    // Modulation routing
    @Published var pitchModSource: ModSource = .off
    @Published var pitchModAmount: Int = 0
    
    init() {}
    
    // MARK: - Codable conformance
    
    enum CodingKeys: CodingKey {
        case osc1Pitch, osc1Fine, osc2Pitch, osc2Fine, osc2Detune, oscMix, pwm, pwmSource
        case cutoff, resonance, vcfEnvAmount, vcfKeytrack, vcfModAmount, vcfModSource
        case vcfAttack, vcfDecay, vcfSustain, vcfRelease
        case volume, vcaModAmount, vcaModSource
        case vcaAttack, vcaDecay, vcaSustain, vcaRelease
        case lfo1Rate, lfo1Amount, lfo2Rate, lfo2Amount
        case pitchModSource, pitchModAmount
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        osc1Pitch = try container.decode(Int.self, forKey: .osc1Pitch)
        osc1Fine = try container.decode(Int.self, forKey: .osc1Fine)
        osc2Pitch = try container.decode(Int.self, forKey: .osc2Pitch)
        osc2Fine = try container.decode(Int.self, forKey: .osc2Fine)
        osc2Detune = try container.decode(Int.self, forKey: .osc2Detune)
        oscMix = try container.decode(Int.self, forKey: .oscMix)
        pwm = try container.decode(Int.self, forKey: .pwm)
        pwmSource = try container.decode(ModSource.self, forKey: .pwmSource)
        
        cutoff = try container.decode(Int.self, forKey: .cutoff)
        resonance = try container.decode(Int.self, forKey: .resonance)
        vcfEnvAmount = try container.decode(Int.self, forKey: .vcfEnvAmount)
        vcfKeytrack = try container.decode(Int.self, forKey: .vcfKeytrack)
        vcfModAmount = try container.decode(Int.self, forKey: .vcfModAmount)
        vcfModSource = try container.decode(ModSource.self, forKey: .vcfModSource)
        
        vcfAttack = try container.decode(Int.self, forKey: .vcfAttack)
        vcfDecay = try container.decode(Int.self, forKey: .vcfDecay)
        vcfSustain = try container.decode(Int.self, forKey: .vcfSustain)
        vcfRelease = try container.decode(Int.self, forKey: .vcfRelease)
        
        volume = try container.decode(Int.self, forKey: .volume)
        vcaModAmount = try container.decode(Int.self, forKey: .vcaModAmount)
        vcaModSource = try container.decode(ModSource.self, forKey: .vcaModSource)
        
        vcaAttack = try container.decode(Int.self, forKey: .vcaAttack)
        vcaDecay = try container.decode(Int.self, forKey: .vcaDecay)
        vcaSustain = try container.decode(Int.self, forKey: .vcaSustain)
        vcaRelease = try container.decode(Int.self, forKey: .vcaRelease)
        
        lfo1Rate = try container.decode(Int.self, forKey: .lfo1Rate)
        lfo1Amount = try container.decode(Int.self, forKey: .lfo1Amount)
        lfo2Rate = try container.decode(Int.self, forKey: .lfo2Rate)
        lfo2Amount = try container.decode(Int.self, forKey: .lfo2Amount)
        
        pitchModSource = try container.decode(ModSource.self, forKey: .pitchModSource)
        pitchModAmount = try container.decode(Int.self, forKey: .pitchModAmount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(osc1Pitch, forKey: .osc1Pitch)
        try container.encode(osc1Fine, forKey: .osc1Fine)
        try container.encode(osc2Pitch, forKey: .osc2Pitch)
        try container.encode(osc2Fine, forKey: .osc2Fine)
        try container.encode(osc2Detune, forKey: .osc2Detune)
        try container.encode(oscMix, forKey: .oscMix)
        try container.encode(pwm, forKey: .pwm)
        try container.encode(pwmSource, forKey: .pwmSource)
        
        try container.encode(cutoff, forKey: .cutoff)
        try container.encode(resonance, forKey: .resonance)
        try container.encode(vcfEnvAmount, forKey: .vcfEnvAmount)
        try container.encode(vcfKeytrack, forKey: .vcfKeytrack)
        try container.encode(vcfModAmount, forKey: .vcfModAmount)
        try container.encode(vcfModSource, forKey: .vcfModSource)
        
        try container.encode(vcfAttack, forKey: .vcfAttack)
        try container.encode(vcfDecay, forKey: .vcfDecay)
        try container.encode(vcfSustain, forKey: .vcfSustain)
        try container.encode(vcfRelease, forKey: .vcfRelease)
        
        try container.encode(volume, forKey: .volume)
        try container.encode(vcaModAmount, forKey: .vcaModAmount)
        try container.encode(vcaModSource, forKey: .vcaModSource)
        
        try container.encode(vcaAttack, forKey: .vcaAttack)
        try container.encode(vcaDecay, forKey: .vcaDecay)
        try container.encode(vcaSustain, forKey: .vcaSustain)
        try container.encode(vcaRelease, forKey: .vcaRelease)
        
        try container.encode(lfo1Rate, forKey: .lfo1Rate)
        try container.encode(lfo1Amount, forKey: .lfo1Amount)
        try container.encode(lfo2Rate, forKey: .lfo2Rate)
        try container.encode(lfo2Amount, forKey: .lfo2Amount)
        
        try container.encode(pitchModSource, forKey: .pitchModSource)
        try container.encode(pitchModAmount, forKey: .pitchModAmount)
    }
    
    // MARK: - SysEx conversion
    
    /// Convert program to SysEx Program Dump format
    /// - Parameters:
    ///   - programNumber: Program slot (0-127)
    ///   - checksumMode: Checksum calculation mode
    /// - Returns: Complete SysEx message including F0...F7
    func toProgramDumpSysEx(programNumber: Int, checksumMode: ChecksumMode) -> [UInt8] {
        var bytes: [UInt8] = [
            0xF0,           // SysEx start
            0x3E,           // Waldorf manufacturer ID
            0x04,           // MiniWorks device ID
            0x00,           // Program Dump command
            UInt8(programNumber & 0x7F)
        ]
        
        // Append all parameter values
        let params: [UInt8] = [
            UInt8(osc1Pitch & 0x7F),
            UInt8(osc1Fine & 0x7F),
            UInt8(osc2Pitch & 0x7F),
            UInt8(osc2Fine & 0x7F),
            UInt8(osc2Detune & 0x7F),
            UInt8(oscMix & 0x7F),
            UInt8(pwm & 0x7F),
            UInt8(pwmSource.rawValue & 0x7F),
            
            UInt8(cutoff & 0x7F),
            UInt8(resonance & 0x7F),
            UInt8(vcfEnvAmount & 0x7F),
            UInt8(vcfKeytrack & 0x7F),
            UInt8(vcfModAmount & 0x7F),
            UInt8(vcfModSource.rawValue & 0x7F),
            
            UInt8(vcfAttack & 0x7F),
            UInt8(vcfDecay & 0x7F),
            UInt8(vcfSustain & 0x7F),
            UInt8(vcfRelease & 0x7F),
            
            UInt8(volume & 0x7F),
            UInt8(vcaModAmount & 0x7F),
            UInt8(vcaModSource.rawValue & 0x7F),
            
            UInt8(vcaAttack & 0x7F),
            UInt8(vcaDecay & 0x7F),
            UInt8(vcaSustain & 0x7F),
            UInt8(vcaRelease & 0x7F),
            
            UInt8(lfo1Rate & 0x7F),
            UInt8(lfo1Amount & 0x7F),
            UInt8(lfo2Rate & 0x7F),
            UInt8(lfo2Amount & 0x7F),
            
            UInt8(pitchModSource.rawValue & 0x7F),
            UInt8(pitchModAmount & 0x7F)
        ]
        
        bytes.append(contentsOf: params)
        
        // Calculate and append checksum
        let checksum = calculateChecksum(params, mode: checksumMode)
        bytes.append(checksum)
        bytes.append(0xF7)  // SysEx end
        
        return bytes
    }
    
    /// Parse a Program Dump SysEx message and update this model
    /// - Parameters:
    ///   - data: Complete SysEx message
    ///   - checksumMode: Checksum mode to verify
    /// - Returns: true if successfully parsed and checksum valid
    func fromProgramDumpSysEx(_ data: [UInt8], checksumMode: ChecksumMode) -> Bool {
        guard data.count >= 40,  // Minimum expected length
              data[0] == 0xF0,
              data[1] == 0x3E,
              data[2] == 0x04,
              data[3] == 0x00,
              data.last == 0xF7,
              verifyChecksum(data, mode: checksumMode) else {
            return false
        }
        
        // Extract parameters starting at byte 5
        var idx = 5
        osc1Pitch = Int(data[idx]); idx += 1
        osc1Fine = Int(data[idx]); idx += 1
        osc2Pitch = Int(data[idx]); idx += 1
        osc2Fine = Int(data[idx]); idx += 1
        osc2Detune = Int(data[idx]); idx += 1
        oscMix = Int(data[idx]); idx += 1
        pwm = Int(data[idx]); idx += 1
        pwmSource = ModSource(rawValue: Int(data[idx])) ?? .off; idx += 1
        
        cutoff = Int(data[idx]); idx += 1
        resonance = Int(data[idx]); idx += 1
        vcfEnvAmount = Int(data[idx]); idx += 1
        vcfKeytrack = Int(data[idx]); idx += 1
        vcfModAmount = Int(data[idx]); idx += 1
        vcfModSource = ModSource(rawValue: Int(data[idx])) ?? .off; idx += 1
        
        vcfAttack = Int(data[idx]); idx += 1
        vcfDecay = Int(data[idx]); idx += 1
        vcfSustain = Int(data[idx]); idx += 1
        vcfRelease = Int(data[idx]); idx += 1
        
        volume = Int(data[idx]); idx += 1
        vcaModAmount = Int(data[idx]); idx += 1
        vcaModSource = ModSource(rawValue: Int(data[idx])) ?? .off; idx += 1
        
        vcaAttack = Int(data[idx]); idx += 1
        vcaDecay = Int(data[idx]); idx += 1
        vcaSustain = Int(data[idx]); idx += 1
        vcaRelease = Int(data[idx]); idx += 1
        
        lfo1Rate = Int(data[idx]); idx += 1
        lfo1Amount = Int(data[idx]); idx += 1
        lfo2Rate = Int(data[idx]); idx += 1
        lfo2Amount = Int(data[idx]); idx += 1
        
        pitchModSource = ModSource(rawValue: Int(data[idx])) ?? .off; idx += 1
        pitchModAmount = Int(data[idx])
        
        return true
    }
}
