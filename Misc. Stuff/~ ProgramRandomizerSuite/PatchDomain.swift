//
//  PatchDomain.swift
//  SynthEditor
//
//  Core data models for programs/patches and configurations.
//

import Foundation

// MARK: - Program Parameter Types

/// Enumerates every parameter in a single hardware program/patch.
/// Adjust names and add/remove cases to exactly match your device spec.
public enum ProgramParameterType: CaseIterable, Hashable, Codable {
    case VCFEnvelopeAttack
    case VCFEnvelopeDecay
    case VCFEnvelopeSustain
    case VCFEnvelopeRelease
    case VCFEnvelopeCutoffAmount

    case cutoff
    case cutoffModulationAmount
    case cutoffModulationSource

    case resonance
    case resonanceModulationAmount
    case resonanceModulationSource

    case VCAEnvelopeAttack
    case VCAEnvelopeDecay
    case VCAEnvelopeSustain
    case VCAEnvelopeRelease
    case VCAEnvelopeVolumeAmount

    case volume
    case volumeModulationAmount
    case volumeModulationSource

    case LFOSpeed
    case LFOSpeedModulationAmount
    case LFOShape
    case LFOSpeedModulationSource

    case panning
    case panningModulationAmount
    case panningModulationSource

    case gateTime
    case triggerSource
    case triggerMode
}

/// Simple value wrapper for a single parameter.
/// In a real implementation you might also store min/max, scaling,
/// curve type, and SysEx addressing here.
public struct ProgramParameter: Hashable, Codable {
    public let type: ProgramParameterType
    public var value: UInt8    // 0...127 for this device

    public init(type: ProgramParameterType, value: UInt8 = 64) {
        self.type = type
        self.value = value
    }
}

// MARK: - Synth Program (one device patch)

/// Represents a complete device program/patch including all parameters.
/// Mirrors the layout you provided.
public struct SynthProgram: Hashable, Codable {

    public var programNumber: UInt8 = 1
    public var programName: String = "New Program"

    public var vcfEnvelopeAttack = ProgramParameter(type: .VCFEnvelopeAttack)
    public var vcfEnvelopeDecay = ProgramParameter(type: .VCFEnvelopeDecay)
    public var vcfEnvelopeSustain = ProgramParameter(type: .VCFEnvelopeSustain)
    public var vcfEnvelopeRelease = ProgramParameter(type: .VCFEnvelopeRelease)
    public var vcfEnvelopeCutoffAmount = ProgramParameter(type: .VCFEnvelopeCutoffAmount)

    public var cutoff = ProgramParameter(type: .cutoff)
    public var cutoffModulationAmount = ProgramParameter(type: .cutoffModulationAmount)
    public var cutoffModulationSource = ProgramParameter(type: .cutoffModulationSource)

    public var resonance = ProgramParameter(type: .resonance)
    public var resonanceModulationAmount = ProgramParameter(type: .resonanceModulationAmount)
    public var resonanceModulationSource = ProgramParameter(type: .resonanceModulationSource)

    public var vcaEnvelopeAttack = ProgramParameter(type: .VCAEnvelopeAttack)
    public var vcaEnvelopeDecay = ProgramParameter(type: .VCAEnvelopeDecay)
    public var vcaEnvelopeSustain = ProgramParameter(type: .VCAEnvelopeSustain)
    public var vcaEnvelopeRelease = ProgramParameter(type: .VCAEnvelopeRelease)
    public var vcaEnvelopeVolumeAmount = ProgramParameter(type: .VCAEnvelopeVolumeAmount)

    public var volume = ProgramParameter(type: .volume)
    public var volumeModulationAmount = ProgramParameter(type: .volumeModulationAmount)
    public var volumeModulationSource = ProgramParameter(type: .volumeModulationSource)

    public var lfoSpeed = ProgramParameter(type: .LFOSpeed)
    public var lfoSpeedModulationAmount = ProgramParameter(type: .LFOSpeedModulationAmount)

    public var lfoShape = ProgramParameter(type: .LFOShape)
    public var lfoSpeedModulationSource = ProgramParameter(type: .LFOSpeedModulationSource)

    public var panning = ProgramParameter(type: .panning)
    public var panningModulationAmount = ProgramParameter(type: .panningModulationAmount)
    public var panningModulationSource = ProgramParameter(type: .panningModulationSource)

    public var gateTime = ProgramParameter(type: .gateTime)
    public var triggerSource = ProgramParameter(type: .triggerSource)
    public var triggerMode = ProgramParameter(type: .triggerMode)

    public init() {}

    /// Convenience: all parameters as an array for generic processing.
    public var allParameters: [ProgramParameter] {
        [
            vcfEnvelopeAttack,
            vcfEnvelopeDecay,
            vcfEnvelopeSustain,
            vcfEnvelopeRelease,
            vcfEnvelopeCutoffAmount,
            cutoff,
            cutoffModulationAmount,
            cutoffModulationSource,
            resonance,
            resonanceModulationAmount,
            resonanceModulationSource,
            vcaEnvelopeAttack,
            vcaEnvelopeDecay,
            vcaEnvelopeSustain,
            vcaEnvelopeRelease,
            vcaEnvelopeVolumeAmount,
            volume,
            volumeModulationAmount,
            volumeModulationSource,
            lfoSpeed,
            lfoSpeedModulationAmount,
            lfoShape,
            lfoSpeedModulationSource,
            panning,
            panningModulationAmount,
            panningModulationSource,
            gateTime,
            triggerSource,
            triggerMode
        ]
    }

    /// Convenience: dictionary keyed by parameter type.
    public var parameterDictionary: [ProgramParameterType: ProgramParameter] {
        Dictionary(uniqueKeysWithValues: allParameters.map { ($0.type, $0) })
    }

    /// Replace a single parameter by type.
    public mutating func setParameter(_ param: ProgramParameter) {
        switch param.type {
        case .VCFEnvelopeAttack: vcfEnvelopeAttack = param
        case .VCFEnvelopeDecay: vcfEnvelopeDecay = param
        case .VCFEnvelopeSustain: vcfEnvelopeSustain = param
        case .VCFEnvelopeRelease: vcfEnvelopeRelease = param
        case .VCFEnvelopeCutoffAmount: vcfEnvelopeCutoffAmount = param

        case .cutoff: cutoff = param
        case .cutoffModulationAmount: cutoffModulationAmount = param
        case .cutoffModulationSource: cutoffModulationSource = param

        case .resonance: resonance = param
        case .resonanceModulationAmount: resonanceModulationAmount = param
        case .resonanceModulationSource: resonanceModulationSource = param

        case .VCAEnvelopeAttack: vcaEnvelopeAttack = param
        case .VCAEnvelopeDecay: vcaEnvelopeDecay = param
        case .VCAEnvelopeSustain: vcaEnvelopeSustain = param
        case .VCAEnvelopeRelease: vcaEnvelopeRelease = param
        case .VCAEnvelopeVolumeAmount: vcaEnvelopeVolumeAmount = param

        case .volume: volume = param
        case .volumeModulationAmount: volumeModulationAmount = param
        case .volumeModulationSource: volumeModulationSource = param

        case .LFOSpeed: lfoSpeed = param
        case .LFOSpeedModulationAmount: lfoSpeedModulationAmount = param
        case .LFOShape: lfoShape = param
        case .LFOSpeedModulationSource: lfoSpeedModulationSource = param

        case .panning: panning = param
        case .panningModulationAmount: panningModulationAmount = param
        case .panningModulationSource: panningModulationSource = param

        case .gateTime: gateTime = param
        case .triggerSource: triggerSource = param
        case .triggerMode: triggerMode = param
        }
    }
}

// MARK: - Patch / Configuration domain

/// Library-level patch wrapper around a SynthProgram.
public struct Patch: Identifiable, Hashable, Codable {
    public let id: UUID
    public var program: SynthProgram

    /// Tags for searching / filtering.
    public var tags: [String]

    public var createdAt: Date
    public var modifiedAt: Date

    /// The configuration slot index this patch was last saved to, if any.
    public var originalSlotIndex: Int?

    /// User flag: is this patch a favorite?
    public var isFavorite: Bool

    /// Change-tracking flag within the library.
    public var isDirty: Bool

    /// Convenience name proxy into the underlying program.
    public var name: String {
        get { program.programName }
        set {
            program.programName = newValue
        }
    }

    public init(
        id: UUID = UUID(),
        program: SynthProgram = SynthProgram(),
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        originalSlotIndex: Int? = nil,
        isFavorite: Bool = false,
        isDirty: Bool = false
    ) {
        self.id = id
        self.program = program
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.originalSlotIndex = originalSlotIndex
        self.isFavorite = isFavorite
        self.isDirty = isDirty
    }
}

/// Per-device global settings for a configuration.
public struct DeviceGlobals: Hashable, Codable {
    public var name: String
    public var midiChannel: Int
    public var inputDeviceID: String?
    public var outputDeviceID: String?

    public init(
        name: String = "Default Globals",
        midiChannel: Int = 1,
        inputDeviceID: String? = nil,
        outputDeviceID: String? = nil
    ) {
        self.name = name
        self.midiChannel = midiChannel
        self.inputDeviceID = inputDeviceID
        self.outputDeviceID = outputDeviceID
    }

    public static var `default`: DeviceGlobals {
        DeviceGlobals()
    }
}

/// A full configuration: up to 20 patches + device globals.
public struct Configuration: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var description: String
    public var globals: DeviceGlobals

    /// Exactly 20 patch slots for this configuration (0...19).
    /// A nil entry represents an empty slot.
    public var patchSlots: [Patch?]

    public var createdAt: Date
    public var modifiedAt: Date

    /// Configuration-level dirty flag derived from patches.
    public var isDirty: Bool {
        patchSlots.contains { $0?.isDirty == true }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        globals: DeviceGlobals = .default,
        patchSlots: [Patch?]? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.globals = globals
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt

        if let patchSlots {
            self.patchSlots = Array(patchSlots.prefix(20)) + Array(repeating: nil, count: max(0, 20 - patchSlots.count))
        } else {
            self.patchSlots = Array(repeating: nil, count: 20)
        }
    }

    public static func empty(named name: String) -> Configuration {
        Configuration(
            name: name,
            description: "",
            globals: .default,
            patchSlots: Array(repeating: nil, count: 20)
        )
    }
}

/// Helper object for displaying patches in lists.
public struct PatchContext: Identifiable, Hashable {
    public let id = UUID()
    public let patch: Patch
    public let configurationID: Configuration.ID
    public let configurationName: String
    public let slotIndex: Int?

    public init(
        patch: Patch,
        configurationID: Configuration.ID,
        configurationName: String,
        slotIndex: Int?
    ) {
        self.patch = patch
        self.configurationID = configurationID
        self.configurationName = configurationName
        self.slotIndex = slotIndex
    }
}

/// Strength of variation when randomizing based on templates.
public enum RandomizeStrength: String, CaseIterable, Codable {
    case gentle
    case moderate
    case extreme
}
