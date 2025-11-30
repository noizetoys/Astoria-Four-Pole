//
//  Tag.swift
//  Check it Out
//
//  Created by James B. Majors on 11/20/25.
//
import SwiftUI


// MARK: - Value Type Models (for UI)

struct Tag: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var color: Color
    
    init(id: UUID = UUID(), name: String, color: Color) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, colorComponents
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let components = try container.decode([Double].self, forKey: .colorComponents)
        color = Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        #if os(macOS)
        let nsColor = NSColor(color)
        let components = [
            Double(nsColor.redComponent),
            Double(nsColor.greenComponent),
            Double(nsColor.blueComponent),
            Double(nsColor.alphaComponent)
        ]
        #else
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let components = [Double(red), Double(green), Double(blue), Double(alpha)]
        #endif
        try container.encode(components, forKey: .colorComponents)
    }
}

struct GlobalData: Codable, Equatable {
    var masterVolume: Double = 0.8
    var masterTuning: Double = 0.0
    var midiChannel: Int = 1
    var velocityCurve: VelocityCurve = .linear
    var transpose: Int = 0
    
    enum VelocityCurve: String, Codable, CaseIterable {
        case soft = "Soft"
        case linear = "Linear"
        case hard = "Hard"
        case fixed = "Fixed"
    }
}

struct Patch: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var tags: Set<Tag>
    var category: String
    var author: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var isFavorite: Bool
    var parameters: [String: Double]
    
    init(
        id: UUID = UUID(),
        name: String,
        tags: Set<Tag> = [],
        category: String = "Uncategorized",
        author: String = "",
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        notes: String = "",
        isFavorite: Bool = false,
        parameters: [String: Double] = [:]
    ) {
        self.id = id
        self.name = name
        self.tags = tags
        self.category = category
        self.author = author
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.notes = notes
        self.isFavorite = isFavorite
        self.parameters = parameters.isEmpty ? Self.defaultParameters() : parameters
    }
    
    static func defaultParameters() -> [String: Double] {
        return [
            "oscillator1_waveform": 0.0,
            "oscillator1_level": 0.5,
            "filter_cutoff": 0.7,
            "filter_resonance": 0.3,
            "envelope_attack": 0.01,
            "envelope_decay": 0.3,
            "envelope_sustain": 0.7,
            "envelope_release": 0.5
        ]
    }
}

struct Configuration: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var globalData: GlobalData
    var patches: [Patch?]
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        notes: String = "",
        patches: [Patch?] = Array(repeating: nil, count: 20),
        globalData: GlobalData = GlobalData()
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.globalData = globalData
        self.patches = patches
        self.notes = notes
    }
    
    var patchCount: Int {
        patches.compactMap { $0 }.count
    }
    
    mutating func setPatch(_ patch: Patch, at position: Int) {
        guard position >= 0 && position < 20 else { return }
        patches[position] = patch
        dateModified = Date()
    }
    
    mutating func clearPatch(at position: Int) {
        guard position >= 0 && position < 20 else { return }
        patches[position] = nil
        dateModified = Date()
    }
}
