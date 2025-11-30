//
//  FileManagerPaths.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//
import Foundation


// MARK: - File Manager Paths

/**
 Manages application directory structure and provides path generation.
 
 ## Customization
 Replace `bundleIdentifier` with your app's identifier.
 Modify directory names as needed for your application structure.
 */
struct FileManagerPaths {
    static let bundleIdentifier = "com.yourcompany.MiniworksEditor"
    
    /// Base directory for all application files
    static var applicationSupport: URL {
        get throws {
            let fileManager = FileManager.default
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return appSupport.appendingPathComponent(bundleIdentifier)
        }
    }
    
    /// Device Profiles directory
    static var profilesDirectory: URL {
        get throws {
            try applicationSupport.appendingPathComponent("Profiles")
        }
    }
    
    /// Individual Programs directory
    static var programsDirectory: URL {
        get throws {
            try applicationSupport.appendingPathComponent("Programs")
        }
    }
    
    /// SysEx export directory
    static var sysExDirectory: URL {
        get throws {
            try applicationSupport.appendingPathComponent("SysEx")
        }
    }
    
    /// Logs directory
    static var logsDirectory: URL {
        get throws {
            try applicationSupport.appendingPathComponent("Logs")
        }
    }
    
    /// Factory presets directory
    static var factoryPresetsDirectory: URL {
        get throws {
            try programsDirectory.appendingPathComponent("Factory")
        }
    }
}
