// SysExCodec.swift
// Codec for encoding/decoding MIDI SysEx messages to/from patch structures
//
// ARCHITECTURE:
// UI (Patch struct) ←→ SysExCodec ←→ MIDIManager ([UInt8])
//
// RESPONSIBILITIES:
// - Encode patch structs to SysEx bytes
// - Decode SysEx bytes to patch structs
// - Validate SysEx format and checksums
// - Handle device-specific SysEx protocols

import Foundation

// MARK: - Protocol for SysEx-Compatible Patches

/// Any patch that can be converted to/from SysEx must conform to this protocol
/// This makes the codec reusable across different device types
public protocol SysExCodable {
    /// Convert patch to SysEx bytes
    func encodeSysEx() throws -> [UInt8]
    
    /// Create patch from SysEx bytes
    static func decodeSysEx(_ data: [UInt8]) throws -> Self
    
    /// Device-specific manufacturer ID
    static var manufacturerID: [UInt8] { get }
    
    /// Device-specific device ID
    static var deviceID: UInt8 { get }
}

// MARK: - SysEx Codec Errors

public enum SysExCodecError: Error, LocalizedError {
    case invalidLength(expected: Int, got: Int)
    case missingSysExStart
    case missingSysExEnd
    case invalidManufacturerID(expected: [UInt8], got: [UInt8])
    case invalidDeviceID(expected: UInt8, got: UInt8)
    case checksumMismatch(expected: UInt8, got: UInt8)
    case invalidDataFormat(String)
    case encodingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidLength(let expected, let got):
            return "Invalid SysEx length: expected \(expected) bytes, got \(got)"
        case .missingSysExStart:
            return "SysEx message must start with 0xF0"
        case .missingSysExEnd:
            return "SysEx message must end with 0xF7"
        case .invalidManufacturerID(let expected, let got):
            return "Invalid manufacturer ID: expected \(hex(expected)), got \(hex(got))"
        case .invalidDeviceID(let expected, let got):
            return "Invalid device ID: expected 0x\(String(format: "%02X", expected)), got 0x\(String(format: "%02X", got))"
        case .checksumMismatch(let expected, let got):
            return "Checksum mismatch: expected 0x\(String(format: "%02X", expected)), got 0x\(String(format: "%02X", got))"
        case .invalidDataFormat(let reason):
            return "Invalid data format: \(reason)"
        case .encodingFailed(let reason):
            return "Encoding failed: \(reason)"
        }
    }
    
    private static func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "0x%02X", $0) }.joined(separator: " ")
    }
}

// MARK: - SysEx Codec

/// Codec for encoding and decoding SysEx messages
/// Generic over patch type that conforms to SysExCodable
public struct SysExCodec<Patch: SysExCodable> {
    
    // MARK: - Encoding
    
    /// Encode a patch to SysEx bytes
    /// - Parameter patch: The patch to encode
    /// - Returns: Complete SysEx message ready to send
    public func encode(_ patch: Patch) throws -> [UInt8] {
        // Delegate to patch's own encoding logic
        let sysex = try patch.encodeSysEx()
        
        // Validate the output
        try validateSysEx(sysex)
        
        return sysex
    }
    
    // MARK: - Decoding
    
    /// Decode SysEx bytes to a patch
    /// - Parameter data: Raw SysEx bytes received from MIDI
    /// - Returns: Decoded patch structure
    public func decode(_ data: [UInt8]) throws -> Patch {
        // Validate format
        try validateSysEx(data)
        
        // Validate manufacturer and device IDs
        try validateDeviceIdentifiers(data)
        
        // Delegate to patch's decoding logic
        return try Patch.decodeSysEx(data)
    }
    
    // MARK: - Validation
    
    /// Validate basic SysEx format
    private func validateSysEx(_ data: [UInt8]) throws {
        guard !data.isEmpty else {
            throw SysExCodecError.invalidLength(expected: 1, got: 0)
        }
        
        guard data.first == 0xF0 else {
            throw SysExCodecError.missingSysExStart
        }
        
        guard data.last == 0xF7 else {
            throw SysExCodecError.missingSysExEnd
        }
    }
    
    /// Validate manufacturer and device IDs match expected values
    private func validateDeviceIdentifiers(_ data: [UInt8]) throws {
        let manuID = Patch.manufacturerID
        let deviceID = Patch.deviceID
        
        // Check manufacturer ID (can be 1 or 3 bytes)
        let headerStart = 1  // Skip 0xF0
        let manuIDLength = manuID.count
        
        guard data.count > headerStart + manuIDLength else {
            throw SysExCodecError.invalidLength(expected: headerStart + manuIDLength + 1, got: data.count)
        }
        
        let receivedManuID = Array(data[headerStart..<headerStart + manuIDLength])
        guard receivedManuID == manuID else {
            throw SysExCodecError.invalidManufacturerID(expected: manuID, got: receivedManuID)
        }
        
        // Check device ID (if applicable - some protocols don't use it)
        if deviceID != 0xFF {  // 0xFF = don't validate
            let deviceIDPos = headerStart + manuIDLength
            guard data.count > deviceIDPos else {
                throw SysExCodecError.invalidLength(expected: deviceIDPos + 1, got: data.count)
            }
            
            let receivedDeviceID = data[deviceIDPos]
            guard receivedDeviceID == deviceID else {
                throw SysExCodecError.invalidDeviceID(expected: deviceID, got: receivedDeviceID)
            }
        }
    }
}

// MARK: - Waldorf 4-Pole Implementation

/// Waldorf 4-Pole Filter patch with SysEx support
public struct Waldorf4PolePatch: SysExCodable, Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var programNumber: UInt8
    
    // 29 parameters in correct SysEx order
    public var vcfAttack: UInt8
    public var vcfDecay: UInt8
    public var vcfSustain: UInt8
    public var vcfRelease: UInt8
    
    public var vcaAttack: UInt8
    public var vcaDecay: UInt8
    public var vcaSustain: UInt8
    public var vcaRelease: UInt8
    
    public var vcfEnvCutoffAmt: UInt8
    public var vcaEnvVolumeAmt: UInt8
    
    public var lfoSpeed: UInt8
    public var lfoSpeedModAmt: UInt8
    public var lfoShape: UInt8
    public var lfoSpeedModSource: UInt8
    
    public var cutoffModAmt: UInt8
    public var resonanceModAmt: UInt8
    public var volumeModAmt: UInt8
    public var panModAmt: UInt8
    
    public var cutoff: UInt8
    public var resonance: UInt8
    public var volume: UInt8
    public var panning: UInt8
    
    public var gateTime: UInt8
    public var triggerSource: UInt8
    public var triggerMode: UInt8
    
    public var reserved1: UInt8
    public var reserved2: UInt8
    public var reserved3: UInt8
    public var reserved4: UInt8
    
    // MARK: - SysExCodable Conformance
    
    /// Waldorf manufacturer ID
    public static let manufacturerID: [UInt8] = [0x3E]
    
    /// 4-Pole device ID
    public static let deviceID: UInt8 = 0x04
    
    /// Encode patch to SysEx
    /// Format: F0 3E 04 01 00 <program#> <29 params> <checksum> F7
    public func encodeSysEx() throws -> [UInt8] {
        var sysex: [UInt8] = [
            0xF0,                    // SysEx Start
            0x3E,                    // Waldorf Manufacturer ID
            0x04,                    // Device ID (4-Pole)
            0x01,                    // Model ID
            0x00,                    // Command: Program Dump
            programNumber,           // Program Number (0-127)
        ]
        
        // Add all 29 parameters in order
        let parameters: [UInt8] = [
            vcfAttack, vcfDecay, vcfSustain, vcfRelease,
            vcaAttack, vcaDecay, vcaSustain, vcaRelease,
            vcfEnvCutoffAmt, vcaEnvVolumeAmt,
            lfoSpeed, lfoSpeedModAmt, lfoShape, lfoSpeedModSource,
            cutoffModAmt, resonanceModAmt, volumeModAmt, panModAmt,
            cutoff, resonance, volume, panning,
            gateTime, triggerSource, triggerMode,
            reserved1, reserved2, reserved3, reserved4
        ]
        
        sysex.append(contentsOf: parameters)
        
        // Calculate and append checksum
        let checksum = calculateChecksum(parameters)
        sysex.append(checksum)
        
        // SysEx End
        sysex.append(0xF7)
        
        return sysex
    }
    
    /// Decode SysEx to patch
    public static func decodeSysEx(_ data: [UInt8]) throws -> Waldorf4PolePatch {
        // Validate length (37 bytes total)
        guard data.count == 37 else {
            throw SysExCodecError.invalidLength(expected: 37, got: data.count)
        }
        
        // Validate header
        guard data[0] == 0xF0 else {
            throw SysExCodecError.missingSysExStart
        }
        
        guard data[36] == 0xF7 else {
            throw SysExCodecError.missingSysExEnd
        }
        
        guard data[1] == 0x3E else {
            throw SysExCodecError.invalidManufacturerID(expected: [0x3E], got: [data[1]])
        }
        
        guard data[2] == 0x04 else {
            throw SysExCodecError.invalidDeviceID(expected: 0x04, got: data[2])
        }
        
        // Extract program number
        let programNumber = data[5]
        
        // Extract 29 parameters (bytes 6-34)
        let parameters = Array(data[6...34])
        
        // Verify checksum
        let receivedChecksum = data[35]
        let calculatedChecksum = calculateChecksum(parameters)
        
        guard receivedChecksum == calculatedChecksum else {
            throw SysExCodecError.checksumMismatch(
                expected: calculatedChecksum,
                got: receivedChecksum
            )
        }
        
        // Build patch
        return Waldorf4PolePatch(
            id: UUID(),
            name: "Received Patch",
            programNumber: programNumber,
            vcfAttack: parameters[0],
            vcfDecay: parameters[1],
            vcfSustain: parameters[2],
            vcfRelease: parameters[3],
            
            vcaAttack: parameters[4],
            vcaDecay: parameters[5],
            vcaSustain: parameters[6],
            vcaRelease: parameters[7],
            
            vcfEnvCutoffAmt: parameters[8],
            vcaEnvVolumeAmt: parameters[9],
            
            lfoSpeed: parameters[10],
            lfoSpeedModAmt: parameters[11],
            lfoShape: parameters[12],
            lfoSpeedModSource: parameters[13],
            
            cutoffModAmt: parameters[14],
            resonanceModAmt: parameters[15],
            volumeModAmt: parameters[16],
            panModAmt: parameters[17],
            
            cutoff: parameters[18],
            resonance: parameters[19],
            volume: parameters[20],
            panning: parameters[21],
            
            gateTime: parameters[22],
            triggerSource: parameters[23],
            triggerMode: parameters[24],
            
            reserved1: parameters[25],
            reserved2: parameters[26],
            reserved3: parameters[27],
            reserved4: parameters[28]
        )
    }
    
    // MARK: - Checksum Calculation
    
    /// Calculate checksum for Waldorf 4-Pole
    /// Checksum = (sum of 29 parameter bytes) & 0x7F
    private static func calculateChecksum(_ parameters: [UInt8]) -> UInt8 {
        let sum = parameters.reduce(0) { Int($0) + Int($1) }
        return UInt8(sum & 0x7F)
    }
    
    private func calculateChecksum(_ parameters: [UInt8]) -> UInt8 {
        Self.calculateChecksum(parameters)
    }
    
    // MARK: - CC Mapping
    
    /// Get all CC messages for this patch
    public func toCCMessages() -> [(cc: UInt8, value: UInt8)] {
        [
            (16, vcfAttack), (17, vcfDecay), (18, vcfSustain), (19, vcfRelease),
            (20, vcaAttack), (21, vcaDecay), (22, vcaSustain), (23, vcaRelease),
            (24, vcfEnvCutoffAmt), (25, vcaEnvVolumeAmt),
            (26, lfoSpeed), (27, lfoSpeedModAmt), (28, lfoShape), (29, lfoSpeedModSource),
            (30, cutoffModAmt), (31, resonanceModAmt),
            (102, volumeModAmt), (103, panModAmt),
            (104, cutoff), (105, resonance), (106, volume), (107, panning),
            (108, gateTime), (109, triggerSource), (110, triggerMode)
        ]
    }
    
    /// Update patch from CC message
    public mutating func updateFromCC(cc: UInt8, value: UInt8) {
        switch cc {
        case 16: vcfAttack = value
        case 17: vcfDecay = value
        case 18: vcfSustain = value
        case 19: vcfRelease = value
        case 20: vcaAttack = value
        case 21: vcaDecay = value
        case 22: vcaSustain = value
        case 23: vcaRelease = value
        case 24: vcfEnvCutoffAmt = value
        case 25: vcaEnvVolumeAmt = value
        case 26: lfoSpeed = value
        case 27: lfoSpeedModAmt = value
        case 28: lfoShape = value
        case 29: lfoSpeedModSource = value
        case 30: cutoffModAmt = value
        case 31: resonanceModAmt = value
        case 102: volumeModAmt = value
        case 103: panModAmt = value
        case 104: cutoff = value
        case 105: resonance = value
        case 106: volume = value
        case 107: panning = value
        case 108: gateTime = value
        case 109: triggerSource = value
        case 110: triggerMode = value
        default: break
        }
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String = "Init",
        programNumber: UInt8 = 0,
        vcfAttack: UInt8 = 0,
        vcfDecay: UInt8 = 64,
        vcfSustain: UInt8 = 127,
        vcfRelease: UInt8 = 64,
        vcaAttack: UInt8 = 0,
        vcaDecay: UInt8 = 64,
        vcaSustain: UInt8 = 127,
        vcaRelease: UInt8 = 64,
        vcfEnvCutoffAmt: UInt8 = 64,
        vcaEnvVolumeAmt: UInt8 = 64,
        lfoSpeed: UInt8 = 64,
        lfoSpeedModAmt: UInt8 = 0,
        lfoShape: UInt8 = 0,
        lfoSpeedModSource: UInt8 = 0,
        cutoffModAmt: UInt8 = 0,
        resonanceModAmt: UInt8 = 0,
        volumeModAmt: UInt8 = 64,
        panModAmt: UInt8 = 64,
        cutoff: UInt8 = 64,
        resonance: UInt8 = 0,
        volume: UInt8 = 100,
        panning: UInt8 = 64,
        gateTime: UInt8 = 64,
        triggerSource: UInt8 = 0,
        triggerMode: UInt8 = 0,
        reserved1: UInt8 = 0,
        reserved2: UInt8 = 0,
        reserved3: UInt8 = 0,
        reserved4: UInt8 = 0
    ) {
        self.id = id
        self.name = name
        self.programNumber = programNumber
        self.vcfAttack = vcfAttack
        self.vcfDecay = vcfDecay
        self.vcfSustain = vcfSustain
        self.vcfRelease = vcfRelease
        self.vcaAttack = vcaAttack
        self.vcaDecay = vcaDecay
        self.vcaSustain = vcaSustain
        self.vcaRelease = vcaRelease
        self.vcfEnvCutoffAmt = vcfEnvCutoffAmt
        self.vcaEnvVolumeAmt = vcaEnvVolumeAmt
        self.lfoSpeed = lfoSpeed
        self.lfoSpeedModAmt = lfoSpeedModAmt
        self.lfoShape = lfoShape
        self.lfoSpeedModSource = lfoSpeedModSource
        self.cutoffModAmt = cutoffModAmt
        self.resonanceModAmt = resonanceModAmt
        self.volumeModAmt = volumeModAmt
        self.panModAmt = panModAmt
        self.cutoff = cutoff
        self.resonance = resonance
        self.volume = volume
        self.panning = panning
        self.gateTime = gateTime
        self.triggerSource = triggerSource
        self.triggerMode = triggerMode
        self.reserved1 = reserved1
        self.reserved2 = reserved2
        self.reserved3 = reserved3
        self.reserved4 = reserved4
    }
}

// MARK: - Usage Example

/*
 COMPLETE FLOW EXAMPLE:
 
 // 1. Initialize
 let midi = MIDIManager.shared
 let codec = SysExCodec<Waldorf4PolePatch>()
 
 // 2. Connect to device
 let sources = await midi.availableSources()
 let destinations = await midi.availableDestinations()
 
 guard let waldorf = sources.first(where: { $0.name.contains("Waldorf") }),
       let waldorfOut = destinations.first(where: { $0.name.contains("Waldorf") }) else {
     return
 }
 
 try await midi.connect(source: waldorf, destination: waldorfOut)
 
 // 3. OUTGOING: UI → Codec → MIDI
 var patch = Waldorf4PolePatch()
 patch.cutoff = 80
 patch.resonance = 40
 
 // Encode to SysEx
 let sysexBytes = try codec.encode(patch)
 
 // Send via MIDI
 try await midi.send(.sysex(sysexBytes), to: waldorfOut)
 
 // 4. INCOMING: MIDI → Codec → UI
 Task {
     for await sysexData in await midi.sysexStream(from: waldorf) {
         do {
             // Decode SysEx to patch
             let receivedPatch = try codec.decode(sysexData)
             
             // Update UI on main thread
             await MainActor.run {
                 updateUI(with: receivedPatch)
             }
         } catch {
             print("Error decoding SysEx: \(error)")
         }
     }
 }
 
 // 5. CC TRACKING
 Task {
     for await (channel, cc, value) in await midi.ccStream(from: waldorf) {
         // Update patch from CC
         patch.updateFromCC(cc: cc, value: value)
         
         await MainActor.run {
             updateUI(with: patch)
         }
     }
 }
 */
