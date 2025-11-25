//
//  FileManagerTests.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import Foundation

// MARK: - Testing Utilities

/**
 ## Testing and Validation
 */
class FileManagerTests {
    let fileManager = MiniworksFileManager.shared
    
    /// Verify file structure is created correctly
    func testDirectoryStructure() async {
        do {
            try await fileManager.createDirectoryStructure()
            
            let paths = [
                try FileManagerPaths.profilesDirectory,
                try FileManagerPaths.programsDirectory,
                try FileManagerPaths.sysExDirectory
            ]
            
            for path in paths {
                let exists = FileManager.default.fileExists(atPath: path.path)
                print(exists ? "✅" : "❌", path.lastPathComponent)
            }
        } catch {
            print("❌ Directory test failed: \(error)")
        }
    }
    
    /// Test round-trip: save, load, verify
    func testRoundTrip(_ profile: MiniworksDeviceProfile) async {
        let testName = "RoundTripTest"
        
        do {
            // Save
            try await fileManager.saveProfile(profile, name: testName)
            print("✅ Save completed")
            
            // Load
            let loaded = try await fileManager.loadProfile(named: testName)
            print("✅ Load completed")
            
            // Verify (compare checksums)
            let originalChecksum = profile.encodeToBytes()
            let loadedChecksum = loaded.encodeToBytes()
            
            if originalChecksum == loadedChecksum {
                print("✅ Data integrity verified")
            } else {
                print("❌ Data mismatch!")
            }
            
            // Cleanup
            try await fileManager.deleteProfile(named: testName)
            print("✅ Cleanup completed")
            
        } catch {
            print("❌ Round-trip test failed: \(error)")
        }
    }
}
