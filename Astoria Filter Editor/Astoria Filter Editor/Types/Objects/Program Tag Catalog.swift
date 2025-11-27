//
//  Program Tag Catalog.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/26/25.
//

import Foundation
import SwiftUI


enum TagCategory: String, CaseIterable, Identifiable {
    case timbre
    case movement
    case envelope
    case frequency
    case instruments
    case triggers
    case texture
    case spatial
    case energy
    case usage
    case modulation
    
    var id: String { rawValue }
}

struct TagLibrary {
    static let timbre: [ProgramTag] = soundDescriptionTags.filter {
        ["Warm","Bright","Dark","Mellow","Harsh","Smooth","Gritty","Crisp",
         "Metallic","Wooden","Glassy","Buzzy","Hollow","Fat","Thin","Sharp","Soft",
         "Punchy","Velvety","Rough","Airy","Nasal","Breath-like","Smoky","Resonant",
         "Muted","Piercing","Rounded","Searing","Shimmering","Chewy","Crunchy","Wet",
         "Dry","Frozen","Saturated","Clean","Dirty","Grainy","Lush","Plastic",
         "Organic","Synthetic"].contains($0.name)
    }
    
    
    static let movement = soundDescriptionTags.filter {
        ["Swirling","Pulsing","Throbbing","Evolving","Morphing","Undulating",
         "Fluttering","Warbling","Wobbling","Rippling","Thumping","Breathing",
         "Expanding","Compressing","Oscillating","Stuttering","Gliding"].contains($0.name)
    }
    
    
    static let envelope = soundDescriptionTags.filter {
        ["Plucked","Snappy","Punchy Attack","Soft Attack","Swell","Drone-like"].contains($0.name)
    }
    
    
    static let frequency = soundDescriptionTags.filter {
        ["Subby","Deep","Booming","Mid-forward","Scooped","Shimmer","Full-spectrum",
         "Formant-rich","Harmonic","Inharmonic","Noisy","Pure","Bell-like","Chirpy",
         "Sizzly","Hissing","Rumbling"].contains($0.name)
    }
    
    
    static let texture = soundDescriptionTags.filter {
        ["Grainy","Smooth","Velvet","Rough","Glassy","Metallic","Plastic","Organic"].contains($0.name)
    }
    
    
    static let energy = soundSourceTags.filter {
        ["Soft","Punchy","Aggressive","Calm","Gentle","Harsh","Epic","Subtle"].contains($0.name)
    }
    
    
    static let spatial = soundSourceTags.filter {
        ["Wide", "Narrow", "Distant", "Close", "Ambient", "Roomy", "Wet / Dry"].contains($0.name)
    }
    
    
    static let usage = soundSourceTags.filter {
        ["Lead", "Pad", "Bass", "Pluck", "FX", "Drone", "Texture", "Percussive"].contains($0.name)
    }
    
    
    static let modulation = soundSourceTags.filter {
        ["LFO-based", "Pitch-modulated", "Filter-swept", "Pulsing", "Tremolo", "Vibrato", "Rhythmic"].contains($0.name)
    }
    
    
    static let instruments = soundSourceTags
    static let triggers = triggerSourceTags
}


let tagDictionary: [TagCategory: [ProgramTag]] = [
    .timbre: TagLibrary.timbre,
    .movement: TagLibrary.movement,
    .envelope: TagLibrary.envelope,
    .frequency: TagLibrary.frequency,
    .instruments: TagLibrary.instruments,
    .triggers: TagLibrary.triggers,
    .texture: TagLibrary.texture,
    .spatial: TagLibrary.spatial,
    .energy: TagLibrary.energy,
    .usage: TagLibrary.usage,
    .modulation: TagLibrary.modulation
]


extension Color {
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.80)
    static let bronze = Color(red: 0.80, green: 0.55, blue: 0.25)
    static let gold = Color(red: 0.95, green: 0.75, blue: 0.20)
    static let deepRed = Color(red: 0.55, green: 0.00, blue: 0.05)
    static let deepBlue = Color(red: 0.05, green: 0.10, blue: 0.30)
    static let smokyGray = Color(red: 0.40, green: 0.40, blue: 0.45)
    static let neonGreen = Color(red: 0.10, green: 1.00, blue: 0.40)
    static let neonBlue = Color(red: 0.10, green: 0.60, blue: 1.00)
    static let neonPink = Color(red: 1.00, green: 0.20, blue: 0.60)
    static let sand = Color(red: 0.93, green: 0.80, blue: 0.60)
    static let coral = Color(red: 1.00, green: 0.45, blue: 0.45)
    static let midnight = Color(red: 0.05, green: 0.05, blue: 0.12)
    static let frost = Color(red: 0.75, green: 0.90, blue: 1.00)
    static let rainbow = Color(red: 1, green: 0.5, blue: 1)
    static let olive = Color(red: 0.5, green: 0.5, blue: 0.2)
    static let neonYellow = Color(red: 1.0, green: 1.0, blue: 0.1)
}


    // MARK: - Sound Descriptive Word Tags
let soundDescriptionTags: [ProgramTag] = [
    ProgramTag(name: "Warm", color: .orange),
    ProgramTag(name: "Bright", color: .yellow),
    ProgramTag(name: "Dark", color: .black),
    ProgramTag(name: "Mellow", color: .brown),
    ProgramTag(name: "Harsh", color: .red),
    ProgramTag(name: "Smooth", color: .blue),
    ProgramTag(name: "Gritty", color: .gray),
    ProgramTag(name: "Crisp", color: .white),
    ProgramTag(name: "Metallic", color: .silver),
    ProgramTag(name: "Wooden", color: .sand),
    ProgramTag(name: "Glassy", color: .frost),
    ProgramTag(name: "Buzzy", color: .neonYellow),
    ProgramTag(name: "Hollow", color: .smokyGray),
    ProgramTag(name: "Fat", color: .purple),
    ProgramTag(name: "Thin", color: .mint),
    ProgramTag(name: "Sharp", color: .teal),
    ProgramTag(name: "Soft", color: .pink),
    ProgramTag(name: "Punchy", color: .coral),
    ProgramTag(name: "Velvety", color: .indigo),
    ProgramTag(name: "Rough", color: .gray),
    ProgramTag(name: "Airy", color: .frost),
    ProgramTag(name: "Nasal", color: .olive),
    ProgramTag(name: "Breath-like", color: .cyan),
    ProgramTag(name: "Smoky", color: .smokyGray),
    ProgramTag(name: "Resonant", color: .gold),
    ProgramTag(name: "Muted", color: .brown.opacity(0.6)),
    ProgramTag(name: "Piercing", color: .neonPink),
    ProgramTag(name: "Rounded", color: .purple.opacity(0.7)),
    ProgramTag(name: "Searing", color: .red),
    ProgramTag(name: "Shimmering", color: .gold),
    ProgramTag(name: "Chewy", color: .orange.opacity(0.8)),
    ProgramTag(name: "Crunchy", color: .bronze),
    ProgramTag(name: "Wet", color: .blue),
    ProgramTag(name: "Dry", color: .sand),
    ProgramTag(name: "Frozen", color: .frost),
    ProgramTag(name: "Saturated", color: .neonBlue),
    ProgramTag(name: "Clean", color: .white),
    ProgramTag(name: "Dirty", color: .brown),
    ProgramTag(name: "Grainy", color: .gray),
    ProgramTag(name: "Lush", color: .green),
    ProgramTag(name: "Plastic", color: .mint),
    ProgramTag(name: "Organic", color: .green.opacity(0.8)),
    ProgramTag(name: "Synthetic", color: .neonBlue),
    
    // Movement
    ProgramTag(name: "Swirling", color: .purple),
    ProgramTag(name: "Pulsing", color: .red),
    ProgramTag(name: "Throbbing", color: .deepRed),
    ProgramTag(name: "Evolving", color: .indigo),
    ProgramTag(name: "Morphing", color: .blue),
    ProgramTag(name: "Undulating", color: .teal),
    ProgramTag(name: "Fluttering", color: .yellow),
    ProgramTag(name: "Warbling", color: .orange),
    ProgramTag(name: "Wobbling", color: .green),
    ProgramTag(name: "Rippling", color: .cyan),
    ProgramTag(name: "Thumping", color: .deepRed),
    ProgramTag(name: "Breathing", color: .blue.opacity(0.4)),
    ProgramTag(name: "Expanding", color: .purple),
    ProgramTag(name: "Compressing", color: .gray),
    ProgramTag(name: "Oscillating", color: .teal),
    ProgramTag(name: "Stuttering", color: .pink),
    ProgramTag(name: "Gliding", color: .mint),
    
    // Envelope / transient
    ProgramTag(name: "Plucked", color: .yellow),
    ProgramTag(name: "Snappy", color: .orange),
    ProgramTag(name: "Punchy Attack", color: .red),
    ProgramTag(name: "Soft Attack", color: .pink),
    ProgramTag(name: "Swell", color: .blue),
    ProgramTag(name: "Drone-like", color: .deepBlue),
    
    // Frequency qualities
    ProgramTag(name: "Subby", color: .deepBlue),
    ProgramTag(name: "Deep", color: .deepRed),
    ProgramTag(name: "Booming", color: .deepRed),
    ProgramTag(name: "Mid-forward", color: .orange),
    ProgramTag(name: "Scooped", color: .gray),
    ProgramTag(name: "Shimmer", color: .gold),
    ProgramTag(name: "Full-spectrum", color: .rainbow),
    ProgramTag(name: "Formant-rich", color: .purple),
    ProgramTag(name: "Harmonic", color: .gold),
    ProgramTag(name: "Inharmonic", color: .silver),
    ProgramTag(name: "Noisy", color: .gray),
    ProgramTag(name: "Pure", color: .white),
    ProgramTag(name: "Bell-like", color: .cyan),
    ProgramTag(name: "Chirpy", color: .yellow),
    ProgramTag(name: "Sizzly", color: .orange),
    ProgramTag(name: "Hissing", color: .white.opacity(0.7)),
    ProgramTag(name: "Rumbling", color: .deepRed)
]



    // MARK: - Instruments & Sound Sources
let soundSourceTags: [ProgramTag] = [
    ProgramTag(name: "Piano", color: .brown),
    ProgramTag(name: "Acoustic Guitar", color: .sand),
    ProgramTag(name: "Electric Guitar", color: .purple),
    ProgramTag(name: "Bass Guitar", color: .deepRed),
    ProgramTag(name: "Violin", color: .orange),
    ProgramTag(name: "Cello", color: .brown),
    ProgramTag(name: "Flute", color: .frost),
    ProgramTag(name: "Clarinet", color: .black),
    ProgramTag(name: "Saxophone", color: .gold),
    ProgramTag(name: "Trumpet", color: .yellow),
    ProgramTag(name: "Trombone", color: .bronze),
    ProgramTag(name: "Harp", color: .teal),
    ProgramTag(name: "Banjo", color: .sand),
    
    // Percussion
    ProgramTag(name: "Kick Drum", color: .deepRed),
    ProgramTag(name: "Snare", color: .silver),
    ProgramTag(name: "Hi-hats", color: .white),
    ProgramTag(name: "Toms", color: .brown),
    ProgramTag(name: "Cymbals", color: .gold),
    ProgramTag(name: "Shakers", color: .yellow),
    ProgramTag(name: "Cowbell", color: .silver),
    ProgramTag(name: "Drum Machine", color: .neonBlue),
    
    // Electronic
    ProgramTag(name: "Synth Oscillator", color: .neonGreen),
    ProgramTag(name: "Wavetable", color: .purple),
    ProgramTag(name: "Granular Engine", color: .cyan),
    ProgramTag(name: "Sampler", color: .brown),
    ProgramTag(name: "Modular Patch", color: .neonPink),
    
    // Foley / field
    ProgramTag(name: "Rain", color: .blue),
    ProgramTag(name: "Wind", color: .gray),
    ProgramTag(name: "Waves", color: .blue),
    ProgramTag(name: "Birds", color: .yellow),
    ProgramTag(name: "Machinery", color: .silver),
    
    // Voice
    ProgramTag(name: "Vocals", color: .pink),
    ProgramTag(name: "Whisper", color: .white.opacity(0.7)),
    ProgramTag(name: "Beatbox", color: .brown)
]



    // MARK: - Trigger / Processing Sources
let triggerSourceTags: [ProgramTag] = [
    ProgramTag(name: "MIDI Input", color: .neonBlue, shape: .capsule),
    ProgramTag(name: "CV/Gate", color: .neonGreen, shape: .roundedRectangle),
    ProgramTag(name: "Drum Trigger", color: .yellow, shape: .roundedRectangle),
    ProgramTag(name: "Envelope Follower", color: .purple, shape: .roundedRectangle),
    ProgramTag(name: "External Audio", color: .orange, shape: .roundedRectangle),
    ProgramTag(name: "Guitar Pedal Return", color: .teal, shape: .roundedRectangle),
    ProgramTag(name: "Sequencer", color: .neonPink),
    ProgramTag(name: "Arpeggiator", color: .blue),
    ProgramTag(name: "Sensor Input", color: .mint),
    ProgramTag(name: "Tape Input", color: .brown),
    ProgramTag(name: "Vinyl Input", color: .white)
]


