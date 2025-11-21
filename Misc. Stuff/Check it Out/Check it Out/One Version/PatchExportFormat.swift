//
//  PatchExportFormat.swift
//  Check it Out
//
//  Created by James B. Majors on 11/20/25.
//
import Foundation
import UniformTypeIdentifiers


// MARK: - Export/Import

struct PatchExportFormat: Codable {
    var version: String = "1.0"
    var patches: [Patch]
    var tags: [Tag]
    var exportDate: Date = Date()
}

struct ConfigurationExportFormat: Codable {
    var version: String = "1.0"
    var configuration: Configuration
    var patches: [Patch]
    var tags: [Tag]
    var exportDate: Date = Date()
}

extension UTType {
    static let patchLibrary = UTType(exportedAs: "com.patchmanager.patches")
    static let configurationFile = UTType(exportedAs: "com.patchmanager.configuration")
}
