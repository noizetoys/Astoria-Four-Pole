//
//  PresetStore.swift
//  MiniWorksMIDI
//
//  Manages preset storage and retrieval. Presets are saved as JSON files
//  in the Documents/MiniWorksPresets directory. Each preset contains a
//  complete ProgramModel serialized to JSON.
//
//  Also supports exporting All Dump SysEx (.syx) files containing all
//  programs for backup or transfer to hardware.
//

import Foundation

@MainActor
class PresetStore: ObservableObject {
    @Published var presets: [PresetInfo] = []
    
    private let presetsDirectory: URL
    
    struct PresetInfo: Identifiable {
        let id: UUID
        let name: String
        let url: URL
        let modifiedDate: Date
    }
    
    init() {
        // Create presets directory in Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        presetsDirectory = documentsPath.appendingPathComponent("MiniWorksPresets", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
        
        loadPresetList()
    }
    
    /// Reload the list of available presets from disk
    func loadPresetList() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: presetsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" }
            
            presets = urls.compactMap { url in
                guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let modDate = attrs[.modificationDate] as? Date else {
                    return nil
                }
                
                return PresetInfo(
                    id: UUID(),
                    name: url.deletingPathExtension().lastPathComponent,
                    url: url,
                    modifiedDate: modDate
                )
            }.sorted { $0.modifiedDate > $1.modifiedDate }
            
        } catch {
            print("Error loading presets: \(error)")
        }
    }
    
    /// Save a program as a preset
    /// - Parameters:
    ///   - program: The program model to save
    ///   - name: Preset name
    func savePreset(_ program: ProgramModel, name: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(program)
        let url = presetsDirectory.appendingPathComponent("\(name).json")
        try data.write(to: url)
        
        loadPresetList()
    }
    
    /// Load a preset from disk
    /// - Parameter info: Preset info containing the file URL
    /// - Returns: Loaded program model
    func loadPreset(_ info: PresetInfo) throws -> ProgramModel {
        let data = try Data(contentsOf: info.url)
        let decoder = JSONDecoder()
        return try decoder.decode(ProgramModel.self, from: data)
    }
    
    /// Delete a preset from disk
    /// - Parameter info: Preset to delete
    func deletePreset(_ info: PresetInfo) throws {
        try FileManager.default.removeItem(at: info.url)
        loadPresetList()
    }
    
    /// Export an All Dump SysEx file containing the current program repeated
    /// for all 128 program slots (for demonstration purposes)
    /// - Parameters:
    ///   - program: Program to export
    ///   - url: Destination file URL
    ///   - checksumMode: Checksum algorithm to use
    func exportAllDumpSysEx(_ program: ProgramModel, to url: URL, checksumMode: ChecksumMode) throws {
        var sysexData = Data()
        
        // Create 128 program dumps (All Dump format: multiple Program Dumps concatenated)
        for programNumber in 0..<128 {
            let dumpData = program.toProgramDumpSysEx(programNumber: programNumber, checksumMode: checksumMode)
            sysexData.append(contentsOf: dumpData)
        }
        
        try sysexData.write(to: url)
    }
}
