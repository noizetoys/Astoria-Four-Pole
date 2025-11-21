//
//  PatchRandomizerEngine.swift
//  SynthEditor
//
//  High-level patch randomizer that can:
//
//  - Generate patches from a descriptive "character profile"
//  - Analyze two or more template patches and create new patches
//    with a similar overall feel
//  - Communicate with the patch manager by returning Patch values
//    that can be added to configurations
//

import Foundation

// MARK: - High-level patch characteristics

/// A descriptive, human-friendly way of specifying how a patch should feel.
/// Values are all 0.0...1.0 and are interpreted heuristically.
public struct PatchCharacteristicProfile: Codable, Hashable {
    /// Perceived brightness / openness of the sound.
    /// 0.0 = very dark / closed filter, 1.0 = very bright.
    public var brightness: ClosedRange<Double>

    /// Amount of motion over time (LFO depth, modulation).
    /// 0.0 = static, 1.0 = highly animated.
    public var motion: ClosedRange<Double>

    /// How snappy or percussive envelopes feel.
    /// 0.0 = slow, pad-like, 1.0 = very plucky.
    public var snappiness: ClosedRange<Double>

    /// Stereo width / panning movement.
    /// 0.0 = mono & centered, 1.0 = wide and moving.
    public var stereoWidth: ClosedRange<Double>

    /// Gate tightness / staccato behaviour.
    /// 0.0 = legato, 1.0 = very short gates.
    public var gateTightness: ClosedRange<Double>

    /// Optional tags to assign to generated patches.
    public var tagHints: [String]

    public init(
        brightness: ClosedRange<Double> = 0.3...0.7,
        motion: ClosedRange<Double> = 0.0...0.5,
        snappiness: ClosedRange<Double> = 0.2...0.6,
        stereoWidth: ClosedRange<Double> = 0.0...0.4,
        gateTightness: ClosedRange<Double> = 0.2...0.6,
        tagHints: [String] = []
    ) {
        self.brightness = brightness
        self.motion = motion
        self.snappiness = snappiness
        self.stereoWidth = stereoWidth
        self.gateTightness = gateTightness
        self.tagHints = tagHints
    }

    public static var warmPad: PatchCharacteristicProfile {
        PatchCharacteristicProfile(
            brightness: 0.3...0.6,
            motion: 0.2...0.5,
            snappiness: 0.0...0.2,
            stereoWidth: 0.3...0.7,
            gateTightness: 0.0...0.3,
            tagHints: ["Pad", "Warm"]
        )
    }

    public static var brightPluck: PatchCharacteristicProfile {
        PatchCharacteristicProfile(
            brightness: 0.7...1.0,
            motion: 0.2...0.6,
            snappiness: 0.6...1.0,
            stereoWidth: 0.2...0.6,
            gateTightness: 0.5...1.0,
            tagHints: ["Pluck", "Bright"]
        )
    }
}

// MARK: - Template analysis

/// Per-parameter range and histogram derived from a set of templates.
public struct TemplateAnalysis {
    public struct ParameterStats {
        public var min: UInt8
        public var max: UInt8
        public var histogram: [UInt8: Int]

        public func randomValue(strength: RandomizeStrength, rng: inout SystemRandomNumberGenerator) -> UInt8 {
            let range = Int(max) - Int(min)
            if range <= 0 {
                return min
            }
            // Narrow the range for gentler variations.
            let effectiveRange: ClosedRange<Int>
            switch strength {
            case .gentle:
                let center = (Int(min) + Int(max)) / 2
                    let half = Swift.max(1, range / 4)
                effectiveRange = (center - half)...(center + half)
            case .moderate:
                effectiveRange = Int(min)...Int(max)
            case .extreme:
                // Allow slight expansion beyond observed range.
                    let lower = Swift.max(0, Int(min) - Swift.min(10, range / 2))
                    let upper = Swift.min(127, Int(max) + Swift.min(10, range / 2))
                effectiveRange = lower...upper
            }
            let value = Int.random(in: effectiveRange, using: &rng)
            return UInt8(clamping: value)
        }
    }

    public var perParameter: [ProgramParameterType: ParameterStats]
    public var combinedTags: [String]

    public init(perParameter: [ProgramParameterType: ParameterStats], combinedTags: [String]) {
        self.perParameter = perParameter
        self.combinedTags = combinedTags
    }
}

// MARK: - Randomizer Engine

/// Engine responsible for generating new patches either from a
/// high-level characteristic profile or from template patches.
public final class PatchRandomizerEngine {

    public init() {}

    // MARK: - Public surface

    /// Generate N new patches from a descriptive profile.
    public func generatePatches(
        fromProfile profile: PatchCharacteristicProfile,
        count: Int,
        baseName: String = "Random",
        startingProgramNumber: UInt8 = 1,
        rng: inout SystemRandomNumberGenerator
    ) -> [Patch] {
        let c = max(0, count)
        return (0..<c).map { index in
            var program = SynthProgram()
            program.programNumber = UInt8(clamping: Int(startingProgramNumber) + index)
            program.programName = String(format: "%@ %02d", baseName, index + 1)

            applyProfile(profile, to: &program, rng: &rng)

            var patch = Patch(program: program)
            patch.tags = profile.tagHints
            patch.isDirty = true
            patch.modifiedAt = Date()
            return patch
        }
    }

    /// Generate N new patches by analyzing two or more template patches and
    /// randomizing within their observed parameter ranges.
    public func generatePatches(
        fromTemplates templates: [Patch],
        count: Int,
        strength: RandomizeStrength,
        baseName: String = "Hybrid",
        startingProgramNumber: UInt8 = 1,
        rng: inout SystemRandomNumberGenerator
    ) -> [Patch] {
        guard !templates.isEmpty else { return [] }

        let analysis = analyzeTemplates(templates)
        let tagHints = analysis.combinedTags

        let c = max(0, count)
        return (0..<c).compactMap { index in
            // Pick a random base program to start from, then randomize around it.
            guard let base = templates.randomElement(using: &rng) else { return nil }
            var program = base.program
            program.programNumber = UInt8(clamping: Int(startingProgramNumber) + index)
            program.programName = String(format: "%@ %02d", baseName, index + 1)

            randomizeProgram(&program, with: analysis, strength: strength, rng: &rng)

            var patch = Patch(program: program)
            patch.tags = Array(Set(base.tags + tagHints)).sorted()
            patch.isDirty = true
            patch.modifiedAt = Date()
            return patch
        }
    }

    /// Analyze templates and return the per-parameter stats.
    public func analyzeTemplates(_ templates: [Patch]) -> TemplateAnalysis {
        var paramStats: [ProgramParameterType: TemplateAnalysis.ParameterStats] = [:]
        var tagSet = Set<String>()

        for patch in templates {
            let dict = patch.program.parameterDictionary
            tagSet.formUnion(patch.tags)

            for (type, param) in dict {
                if var stats = paramStats[type] {
                    stats.min = min(stats.min, param.value)
                    stats.max = max(stats.max, param.value)
                    stats.histogram[param.value, default: 0] += 1
                    paramStats[type] = stats
                } else {
                    paramStats[type] = TemplateAnalysis.ParameterStats(
                        min: param.value,
                        max: param.value,
                        histogram: [param.value: 1]
                    )
                }
            }
        }

        return TemplateAnalysis(
            perParameter: paramStats,
            combinedTags: Array(tagSet).sorted()
        )
    }

    // MARK: - Profile -> Program mapping

    /// Map the high-level profile to parameter values in a program.
    private func applyProfile(
        _ profile: PatchCharacteristicProfile,
        to program: inout SynthProgram,
        rng: inout SystemRandomNumberGenerator
    ) {
        func sample(_ range: ClosedRange<Double>) -> Double {
            let clamped = range.clamped(to: 0.0...1.0)
            let t = Double.random(in: clamped, using: &rng)
            return t
        }

        // Brightness -> cutoff, cutoff envelope, resonance (inverse).
        let brightness = sample(profile.brightness)
        let cutoffValue = UInt8(clamping: Int(brightness * 100.0) + 20) // 20...120 approx
        program.cutoff.value = cutoffValue
        program.vcfEnvelopeCutoffAmount.value = UInt8(clamping: Int(brightness * 127.0))
        program.resonance.value = UInt8(clamping: Int((1.0 - brightness) * 96.0) + 16)

        // Motion -> LFO speed and modulation depths.
        let motion = sample(profile.motion)
        program.lfoSpeed.value = UInt8(clamping: Int(motion * 100.0) + 10)
        program.lfoSpeedModulationAmount.value = UInt8(clamping: Int(motion * 127.0))
        program.cutoffModulationAmount.value = UInt8(clamping: Int(motion * 96.0))
        program.panningModulationAmount.value = UInt8(clamping: Int(motion * 96.0))

        // Snappiness -> envelope times (attack/decay/release).
        let snap = sample(profile.snappiness)
        // Invert: snappier = shorter times.
        let attackBase = (1.0 - snap)
        program.vcaEnvelopeAttack.value = UInt8(clamping: Int(attackBase * 80.0))
        program.vcfEnvelopeAttack.value = UInt8(clamping: Int(attackBase * 80.0))

        // Sustain more stable for pads, lower for plucks.
        let sustain = UInt8(clamping: Int((1.0 - snap * 0.7) * 127.0))
        program.vcaEnvelopeSustain.value = sustain
        program.vcfEnvelopeSustain.value = sustain

        let decay = UInt8(clamping: Int((0.4 + (1.0 - snap) * 0.6) * 127.0))
        program.vcaEnvelopeDecay.value = decay
        program.vcfEnvelopeDecay.value = decay
        program.vcaEnvelopeRelease.value = decay
        program.vcfEnvelopeRelease.value = decay

        // StereoWidth -> panning and panning LFO amount.
        let width = sample(profile.stereoWidth)
        program.panning.value = 64 // center
        program.panningModulationAmount.value = UInt8(clamping: Int(width * 127.0))

        // Gate tightness.
        let gate = sample(profile.gateTightness)
        program.gateTime.value = UInt8(clamping: Int((1.0 - gate) * 100.0) + 10)
    }

    // MARK: - Template randomization

    private func randomizeProgram(
        _ program: inout SynthProgram,
        with analysis: TemplateAnalysis,
        strength: RandomizeStrength,
        rng: inout SystemRandomNumberGenerator
    ) {
        var updated = program

        for type in ProgramParameterType.allCases {
            guard let stats = analysis.perParameter[type] else {
                continue
            }
            var param = (updated.parameterDictionary[type] ?? ProgramParameter(type: type))
            param.value = stats.randomValue(strength: strength, rng: &rng)
            updated.setParameter(param)
        }

        program = updated
    }
}

// MARK: - Convenience helpers for manager integration

public extension PatchRandomizerEngine {

    /// Create a brand new configuration filled with random patches from a profile.
    func makeRandomConfiguration(
        name: String,
        description: String = "",
        profile: PatchCharacteristicProfile,
        count: Int,
        rng: inout SystemRandomNumberGenerator
    ) -> Configuration {
        let limitedCount = max(0, min(20, count))
        let patches = generatePatches(
            fromProfile: profile,
            count: limitedCount,
            baseName: name,
            startingProgramNumber: 1,
            rng: &rng
        )
        var slots: [Patch?] = Array(repeating: nil, count: 20)
        for (index, patch) in patches.enumerated() {
            slots[index] = patch
        }
        return Configuration(
            name: name,
            description: description,
            globals: .default,
            patchSlots: slots
        )
    }

    /// Fill available slots of an existing configuration with random patches
    /// generated from a profile.
    func addRandomPatches(
        to configuration: inout Configuration,
        profile: PatchCharacteristicProfile,
        count: Int,
        rng: inout SystemRandomNumberGenerator
    ) {
        let emptyIndices = configuration.patchSlots.enumerated()
            .filter { $0.element == nil }
            .map { $0.offset }
        guard !emptyIndices.isEmpty else { return }

        let maxCount = min(count, emptyIndices.count)
        let patches = generatePatches(
            fromProfile: profile,
            count: maxCount,
            baseName: configuration.name + " Rand",
            startingProgramNumber: configuration.patchSlots.compactMap { $0?.program.programNumber }.max() ?? 1,
            rng: &rng
        )

        for (i, patch) in patches.enumerated() {
            let slotIndex = emptyIndices[i]
            var p = patch
            p.originalSlotIndex = slotIndex
            configuration.patchSlots[slotIndex] = p
        }
        configuration.modifiedAt = Date()
    }

    /// Create a new configuration by hybridizing two or more template patches.
    public func makeHybridConfiguration(
        name: String,
        description: String = "",
        templates: [Patch],
        strength: RandomizeStrength,
        count: Int,
        rng: inout SystemRandomNumberGenerator
    ) -> Configuration {
        let limitedCount = max(0, min(20, count))
        let patches = generatePatches(
            fromTemplates: templates,
            count: limitedCount,
            strength: strength,
            baseName: name,
            startingProgramNumber: 1,
            rng: &rng
        )
        var slots: [Patch?] = Array(repeating: nil, count: 20)
        for (index, patch) in patches.enumerated() {
            slots[index] = patch
        }
        return Configuration(
            name: name,
            description: description,
            globals: .default,
            patchSlots: slots
        )
    }

    /// Add hybridized patches into the first available slots of an existing configuration.
    public func addHybridPatches(
        to configuration: inout Configuration,
        templates: [Patch],
        strength: RandomizeStrength,
        count: Int,
        rng: inout SystemRandomNumberGenerator
    ) {
        let emptyIndices = configuration.patchSlots.enumerated()
            .filter { $0.element == nil }
            .map { $0.offset }
        guard !emptyIndices.isEmpty else { return }

        let maxCount = min(count, emptyIndices.count)
        let patches = generatePatches(
            fromTemplates: templates,
            count: maxCount,
            strength: strength,
            baseName: configuration.name + " Hybrid",
            startingProgramNumber: configuration.patchSlots.compactMap { $0?.program.programNumber }.max() ?? 1,
            rng: &rng
        )

        for (i, patch) in patches.enumerated() {
            let slotIndex = emptyIndices[i]
            var p = patch
            p.originalSlotIndex = slotIndex
            configuration.patchSlots[slotIndex] = p
        }
        configuration.modifiedAt = Date()
    }
}
