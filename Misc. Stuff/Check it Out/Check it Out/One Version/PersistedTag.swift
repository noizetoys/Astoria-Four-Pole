//
//  PersistedTag.swift
//  Check it Out
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftData
import Foundation
import AppKit
import SwiftUI

// MARK: - SwiftData Models

@Model
final class PersistedTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorRed: Double
    var colorGreen: Double
    var colorBlue: Double
    var colorAlpha: Double
    
    init(id: UUID, name: String, colorRed: Double, colorGreen: Double, colorBlue: Double, colorAlpha: Double) {
        self.id = id
        self.name = name
        self.colorRed = colorRed
        self.colorGreen = colorGreen
        self.colorBlue = colorBlue
        self.colorAlpha = colorAlpha
    }
    
    convenience init(from tag: Tag) {
        #if os(macOS)
        let nsColor = NSColor(tag.color)
        self.init(
            id: tag.id,
            name: tag.name,
            colorRed: Double(nsColor.redComponent),
            colorGreen: Double(nsColor.greenComponent),
            colorBlue: Double(nsColor.blueComponent),
            colorAlpha: Double(nsColor.alphaComponent)
        )
        #else
        let uiColor = UIColor(tag.color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(
            id: tag.id,
            name: tag.name,
            colorRed: Double(red),
            colorGreen: Double(green),
            colorBlue: Double(blue),
            colorAlpha: Double(alpha)
        )
        #endif
    }
    
    func toTag() -> Tag {
        Tag(
            id: id,
            name: name,
            color: Color(red: colorRed, green: colorGreen, blue: colorBlue, opacity: colorAlpha)
        )
    }
}

@Model
final class PersistedPatch {
    @Attribute(.unique) var id: UUID
    var name: String
    var tagIDs: [UUID]
    var category: String
    var author: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var isFavorite: Bool
    var parametersData: Data?
    
    init(id: UUID, name: String, tagIDs: [UUID], category: String, author: String,
         dateCreated: Date, dateModified: Date, notes: String, isFavorite: Bool, parametersData: Data?) {
        self.id = id
        self.name = name
        self.tagIDs = tagIDs
        self.category = category
        self.author = author
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.notes = notes
        self.isFavorite = isFavorite
        self.parametersData = parametersData
    }
    
    convenience init(from patch: Patch) {
        let parametersData = try? JSONEncoder().encode(patch.parameters)
        self.init(
            id: patch.id,
            name: patch.name,
            tagIDs: patch.tags.map { $0.id },
            category: patch.category,
            author: patch.author,
            dateCreated: patch.dateCreated,
            dateModified: patch.dateModified,
            notes: patch.notes,
            isFavorite: patch.isFavorite,
            parametersData: parametersData
        )
    }
    
    func toPatch(availableTags: [Tag]) -> Patch {
        let tags = Set(availableTags.filter { tagIDs.contains($0.id) })
        let parameters: [String: Double]
        if let data = parametersData,
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            parameters = decoded
        } else {
            parameters = Patch.defaultParameters()
        }
        
        return Patch(
            id: id,
            name: name,
            tags: tags,
            category: category,
            author: author,
            dateCreated: dateCreated,
            dateModified: dateModified,
            notes: notes,
            isFavorite: isFavorite,
            parameters: parameters
        )
    }
}

@Model
final class PersistedConfiguration {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var patchIDs: [UUID?]  // Array of 20 optional patch IDs
    
    // Global data
    var masterVolume: Double
    var masterTuning: Double
    var midiChannel: Int
    var velocityCurveRaw: String
    var transpose: Int
    
    init(id: UUID, name: String, dateCreated: Date, dateModified: Date, notes: String,
         patchIDs: [UUID?], masterVolume: Double, masterTuning: Double, midiChannel: Int,
         velocityCurveRaw: String, transpose: Int) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.notes = notes
        self.patchIDs = patchIDs
        self.masterVolume = masterVolume
        self.masterTuning = masterTuning
        self.midiChannel = midiChannel
        self.velocityCurveRaw = velocityCurveRaw
        self.transpose = transpose
    }
    
    convenience init(from config: Configuration) {
        self.init(
            id: config.id,
            name: config.name,
            dateCreated: config.dateCreated,
            dateModified: config.dateModified,
            notes: config.notes,
            patchIDs: config.patches.map { $0?.id },
            masterVolume: config.globalData.masterVolume,
            masterTuning: config.globalData.masterTuning,
            midiChannel: config.globalData.midiChannel,
            velocityCurveRaw: config.globalData.velocityCurve.rawValue,
            transpose: config.globalData.transpose
        )
    }
    
    func toConfiguration(availablePatches: [Patch]) -> Configuration {
        let patchDict = Dictionary(uniqueKeysWithValues: availablePatches.map { ($0.id, $0) })
        let patches = patchIDs.map { id -> Patch? in
            guard let id = id else { return nil }
            return patchDict[id]
        }
        
        let globalData = GlobalData(
            masterVolume: masterVolume,
            masterTuning: masterTuning,
            midiChannel: midiChannel,
            velocityCurve: GlobalData.VelocityCurve(rawValue: velocityCurveRaw) ?? .linear,
            transpose: transpose
        )
        
        return Configuration(
            id: id,
            name: name,
            dateCreated: dateCreated,
            dateModified: dateModified,
            notes: notes,
            patches: patches,
            globalData: globalData
        )
    }
}
