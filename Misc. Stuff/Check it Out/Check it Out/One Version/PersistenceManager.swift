//
//  PersistenceManager.swift
//  Check it Out
//
//  Created by James B. Majors on 11/20/25.
//

import Observation
import SwiftData

// MARK: - Persistence Manager

@Observable
class PersistenceManager {
    var modelContainer: ModelContainer?
    var modelContext: ModelContext?
    
    init() {
        setupContainer()
    }
    
    private func setupContainer() {
        let schema = Schema([
            PersistedTag.self,
            PersistedPatch.self,
            PersistedConfiguration.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer!)
        } catch {
            print("Failed to create model container: \(error)")
        }
    }
    
    // MARK: - Save Operations
    
    func saveTags(_ tags: [Tag]) throws {
        guard let context = modelContext else { return }
        
        // Delete existing tags
        try context.delete(model: PersistedTag.self)
        
        // Save new tags
        for tag in tags {
            let persistedTag = PersistedTag(from: tag)
            context.insert(persistedTag)
        }
        
        try context.save()
    }
    
    func savePatches(_ patches: [Patch]) throws {
        guard let context = modelContext else { return }
        
        // Delete existing patches
        try context.delete(model: PersistedPatch.self)
        
        // Save new patches
        for patch in patches {
            let persistedPatch = PersistedPatch(from: patch)
            context.insert(persistedPatch)
        }
        
        try context.save()
    }
    
    func saveConfigurations(_ configurations: [Configuration]) throws {
        guard let context = modelContext else { return }
        
        // Delete existing configurations
        try context.delete(model: PersistedConfiguration.self)
        
        // Save new configurations
        for config in configurations {
            let persistedConfig = PersistedConfiguration(from: config)
            context.insert(persistedConfig)
        }
        
        try context.save()
    }
    
    // MARK: - Load Operations
    
    func loadTags() throws -> [Tag] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<PersistedTag>()
        let persistedTags = try context.fetch(descriptor)
        return persistedTags.map { $0.toTag() }
    }
    
    func loadPatches(availableTags: [Tag]) throws -> [Patch] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<PersistedPatch>()
        let persistedPatches = try context.fetch(descriptor)
        return persistedPatches.map { $0.toPatch(availableTags: availableTags) }
    }
    
    func loadConfigurations(availablePatches: [Patch]) throws -> [Configuration] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<PersistedConfiguration>()
        let persistedConfigs = try context.fetch(descriptor)
        return persistedConfigs.map { $0.toConfiguration(availablePatches: availablePatches) }
    }
}
