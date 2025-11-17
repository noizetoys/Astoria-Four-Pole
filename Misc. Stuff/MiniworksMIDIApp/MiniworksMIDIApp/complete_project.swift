/*
================================================================================
MiniWorksMIDI - Complete Project Files
================================================================================

This file contains all project files separated by markers.
To extract:
1. Copy this entire file
2. Use the script below, OR
3. Manually split at the "FILE:" markers

macOS/Linux extraction script:
---
#!/bin/bash
mkdir -p MiniWorksMIDI
awk '/^\/\/ FILE: /{file="MiniWorksMIDI/"$3; next} file{print > file}' MiniWorksMIDI-Complete-Project.txt
---

================================================================================
*/

// FILE: MiniWorksMIDIApp.swift
//
//  MiniWorksMIDIApp.swift
//  MiniWorksMIDI
//
//  A universal SwiftUI app for macOS and iOS that provides a complete
//  CoreMIDI SysEx interface for the Waldorf MiniWorks 4-Pole synthesizer.
//
//  This is the app entry point. It creates the MIDI manager as a shared
//  environment object so all views can access MIDI state.
//

import SwiftUI

@main
struct MiniWorksMIDIApp: App {
    @StateObject private var midiManager = MIDIManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(midiManager)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
}

// FILE: ContentView.swift
//
//  ContentView.swift
//  MiniWorksMIDI
//
//  Main container view that provides a tabbed interface for MIDI configuration,
//  program editing, and CC mapping. On macOS, uses a sidebar-style navigation;
//  on iOS, uses a tab bar.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var midiManager: MIDIManager
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List {
                NavigationLink(destination: MIDIView()) {
                    Label("MIDI Setup", systemImage: "cable.connector")
                }
                NavigationLink(destination: ProgramEditorView()) {
                    Label("Program Editor", systemImage: "slider.horizontal.3")
                }
                NavigationLink(destination: CCMappingView()) {
                    Label("CC Mapping", systemImage: "dial.medium")
                }
            }
            .navigationTitle("MiniWorksMIDI")
        } detail: {
            MIDIView()
        }
        .frame(minWidth: 900, minHeight: 700)
        #else
        TabView {
            MIDIView()
                .tabItem {
                    Label("MIDI", systemImage: "cable.connector")
                }
            
            ProgramEditorView()
                .tabItem {
                    Label("Editor", systemImage: "slider.horizontal.3")
                }
            
            CCMappingView()
                .tabItem {
                    Label("CC Map", systemImage: "dial.medium")
                }
        }
        #endif
    }
}

// FILE: Utils.swift
//
//  Utils.swift
//  MiniWorksMIDI
//
//  Utility functions for SysEx checksum calculation and validation.
//
//  ═══════════════════════════════════════════════════════════════════════
//  WHAT ARE CHECKSUMS AND WHY DO WE NEED THEM?
//  ═══════════════════════════════════════════════════════════════════════
//
//  When sending data over MIDI, errors can occur:
//  - Electrical interference can flip bits
//  - Cable issues can corrupt data
//  - Timing problems can cause dropped bytes
//
//  A CHECKSUM is a simple error detection mechanism. Think of it like a
//  "seal" on an envelope that proves the contents haven't been tampered with.
//
//  HOW IT WORKS:
//  1. Sender calculates a checksum from all the data bytes
//  2. Sender appends the checksum to the message
//  3. Receiver calculates the SAME checksum from received data
//  4. Receiver compares: if checksums match, data is probably correct
//
//  Example:
//  Data: [10, 20, 30, 40]
//  Sum: 10 + 20 + 30 + 40 = 100
//  Checksum (mask7): 100 & 0x7F = 100
//  Message sent: [10, 20, 30, 40, 100]
//
//  If the receiver gets [10, 20, 99, 40, 100], when they recalculate
//  the checksum they'll get 169, which doesn't match 100, so they know
//  something went wrong!
//
//  ═══════════════════════════════════════════════════════════════════════
//  WHY TWO DIFFERENT CHECKSUM MODES?
//  ═══════════════════════════════════════════════════════════════════════
//
//  Different manufacturers (and even different firmware versions of the
//  same device) use different checksum algorithms. The MiniWorks may use
//  either "mask7" or "complement7" depending on your hardware version.
//
//  Both ensure the checksum is a valid MIDI data byte (0-127), which is
//  required because MIDI data bytes must have the most significant bit = 0.
//  (Status bytes have MSB = 1, data bytes have MSB = 0)
//
//  ═══════════════════════════════════════════════════════════════════════
//  THE TWO CHECKSUM ALGORITHMS
//  ═══════════════════════════════════════════════════════════════════════
//
//  MASK7 ("7-bit mask"):
//  -------------------
//  - Add all bytes together
//  - Keep only the lower 7 bits (AND with 0x7F = 0111 1111)
//  - Result: 0-127
//
//  Example:
//  Data: [64, 100, 127]
//  Sum: 64 + 100 + 127 = 291 (binary: 1 0010 0011)
//  Mask: 291 & 0x7F = 0010 0011 = 35
//  Checksum: 35
//
//  Why: Simple and fast. The AND operation strips the high bit.
//
//  COMPLEMENT7 ("7-bit two's complement"):
//  --------------------------------------
//  - Add all bytes together
//  - Negate the sum (two's complement: flip all bits and add 1)
//  - Keep only the lower 7 bits (AND with 0x7F)
//  - Result: 0-127
//
//  Example:
//  Data: [64, 100, 127]
//  Sum: 291
//  Negate: -291 (two's complement)
//  Mask: (-291) & 0x7F = 93
//  Checksum: 93
//
//  Why: Provides better error detection. If you add all the data bytes
//  plus the checksum together and mask to 7 bits, you always get 0.
//  This is called a "zero-sum checksum" and catches more errors.
//
//  Verification for complement7:
//  (64 + 100 + 127 + 93) & 0x7F = 384 & 0x7F = 0 ✓
//

import Foundation

enum ChecksumMode: String, CaseIterable {
    case mask7 = "Mask 7-bit"
    case complement7 = "Complement 7-bit"
}

/// Calculate checksum for SysEx payload using the specified mode
///
/// IMPORTANT: The data parameter should include ONLY the payload bytes,
/// not the F0, manufacturer ID, device ID, or F7 bytes!
///
/// For a MiniWorks Program Dump:
/// F0 3E 04 00 <program#> <param1> <param2> ... <paramN> <checksum> F7
///
/// You would pass: [<program#>, <param1>, <param2>, ..., <paramN>]
/// (Everything after device ID, before checksum)
///
/// - Parameters:
///   - data: The data bytes to checksum (excluding F0, manufacturer ID, and F7)
///   - mode: The checksum algorithm to use
/// - Returns: A single byte checksum value (0-127)
func calculateChecksum(_ data: [UInt8], mode: ChecksumMode) -> UInt8 {
    // Step 1: Add all bytes together
    // We use &+ (wrapping addition) to allow overflow without crashing
    // If the sum exceeds the maximum Int value, it wraps around
    let sum = data.reduce(0) { $0 &+ Int($1) }
    
    switch mode {
    case .mask7:
        // Simple 7-bit mask: keeps lower 7 bits of sum
        // Binary AND with 0x7F (0111 1111) zeros out the high bit
        return UInt8(sum & 0x7F)
        
    case .complement7:
        // Two's complement, masked to 7 bits
        // This creates a "zero-sum" checksum where data + checksum = 0 (mod 128)
        // Negating in binary: flip all bits, add 1
        return UInt8((-sum) & 0x7F)
    }
}

/// Verify that a SysEx message has a valid checksum
///
/// This function:
/// 1. Extracts the payload (data between header and checksum)
/// 2. Calculates what the checksum SHOULD be
/// 3. Compares it to what was actually received
///
/// MESSAGE FORMAT:
/// F0 3E 04 <command> <data...> <checksum> F7
/// └─┘ └───┘ └───────────────┘ └────────┘ └┘
///  │    │          │              │        └─ End marker
///  │    │          │              └────────── Checksum byte
///  │    │          └───────────────────────── Payload (what we checksum)
///  │    └────────────────────────────────── Header
///  └─────────────────────────────────────── Start marker
///
/// - Parameters:
///   - data: Complete SysEx data including F0...F7
///   - mode: The checksum mode to verify against
/// - Returns: true if checksum is valid, false if corrupted or invalid format
func verifyChecksum(_ data: [UInt8], mode: ChecksumMode) -> Bool {
    // Basic validation: message must be long enough and have proper markers
    guard data.count > 6,        // Minimum: F0 3E 04 XX YY ZZ F7 = 7 bytes
          data.first == 0xF0,    // Must start with SysEx start marker
          data.last == 0xF7 else // Must end with SysEx end marker
    {
        return false
    }
    
    // Extract payload: everything after header, before checksum
    // F0 3E 04 [PAYLOAD...] [CHECKSUM] F7
    //  0  1  2      3          count-2   count-1
    let payloadStart = 3                    // Skip F0, 3E, 04
    let checksumIndex = data.count - 2      // Checksum is second-to-last byte
    let payload = Array(data[payloadStart..<checksumIndex])
    
    // Get the checksum that was included in the message
    let receivedChecksum = data[checksumIndex]
    
    // Calculate what the checksum SHOULD be
    let calculatedChecksum = calculateChecksum(payload, mode: mode)
    
    // Compare: if they match, data is valid!
    return receivedChecksum == calculatedChecksum
}

/// Format bytes as hex string for logging
///
/// Converts [F0, 3E, 04, 00] to "F0 3E 04 00"
/// This makes MIDI data human-readable in the log.
///
/// - Parameter bytes: Array of bytes to format
/// - Returns: Space-separated hex string
func hexString(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
}

/// Extract program number from a Program Dump SysEx message
///
/// MiniWorks Program Dump format:
/// F0 3E 04 00 <program#> <data...> <checksum> F7
///              └────┘
///             byte 4 is the program number (0-127)
///
/// - Parameter data: Complete SysEx message
/// - Returns: Program number (0-127) or nil if invalid format
func extractProgramNumber(_ data: [UInt8]) -> Int? {
    // Verify this is a Program Dump message
    guard data.count > 5,
          data[0] == 0xF0,    // SysEx start
          data[1] == 0x3E,    // Waldorf manufacturer ID
          data[2] == 0x04,    // MiniWorks device ID
          data[3] == 0x00     // Program Dump command (not request)
    else {
        return nil
    }
    
    return Int(data[4])
}

// MARK: - Educational Helpers

/// Demonstrate checksum calculation with detailed explanation
///
/// This is a teaching function that shows the step-by-step process
/// of calculating both checksum types. Useful for understanding the math!
func demonstrateChecksum(data: [UInt8]) {
    print("\n═══ CHECKSUM DEMONSTRATION ═══")
    print("Data bytes: \(data.map { String($0) }.joined(separator: ", "))")
    
    // Calculate sum
    let sum = data.reduce(0) { $0 + Int($1) }
    print("\n1. Sum all bytes: \(data.map { String($0) }.joined(separator: " + ")) = \(sum)")
    print("   Binary: \(String(sum, radix: 2))")
    
    // Mask7
    let mask7Result = sum & 0x7F
    print("\n2. MASK7: \(sum) & 0x7F")
    print("   Binary: \(String(sum, radix: 2))")
    print("         & 01111111")
    print("         = \(String(mask7Result, radix: 2).padLeft(8))")
    print("   Decimal: \(mask7Result)")
    
    // Complement7
    let complement7Result = (-sum) & 0x7F
    print("\n3. COMPLEMENT7: (-\(sum)) & 0x7F")
    print("   Two's complement of \(sum) = \(-sum)")
    print("   Binary: \(String(UInt(bitPattern: -sum), radix: 2))")
    print("         & 01111111")
    print("         = \(String(complement7Result, radix: 2).padLeft(8))")
    print("   Decimal: \(complement7Result)")
    
    // Verification for complement7
    let verify = (sum + complement7Result) & 0x7F
    print("\n4. VERIFY (complement7): (\(sum) + \(complement7Result)) & 0x7F = \(verify)")
    print("   \(verify == 0 ? "✓ Correct! Zero-sum checksum" : "✗ Error in calculation")")
    
    print("═══════════════════════════════\n")
}

extension String {
    func padLeft(_ length: Int, with char: Character = "0") -> String {
        let padCount = length - count
        return padCount > 0 ? String(repeating: char, count: padCount) + self : self
    }
}

// FILE: ModSource.swift
//
//  ModSource.swift
//  MiniWorksMIDI
//
//  Defines modulation sources available on the Waldorf MiniWorks.
//  These are used for various modulation routing parameters throughout
//  the synthesizer architecture.
//

import Foundation

enum ModSource: Int, CaseIterable, Identifiable, Codable {
    case off = 0
    case lfo1 = 1
    case lfo2 = 2
    case envelope = 3
    case velocity = 4
    case modWheel = 5
    case aftertouch = 6
    case keytrack = 7
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .lfo1: return "LFO 1"
        case .lfo2: return "LFO 2"
        case .envelope: return "Envelope"
        case .velocity: return "Velocity"
        case .modWheel: return "Mod Wheel"
        case .aftertouch: return "Aftertouch"
        case .keytrack: return "Keytrack"
        }
    }
}

// FILE: Debouncer.swift
//
//  Debouncer.swift
//  MiniWorksMIDI
//
//  A simple debouncer that delays execution until a period of inactivity.
//  Used to batch parameter changes when live update is enabled, preventing
//  MIDI flooding when the user drags a knob continuously.
//
//  Design: Each parameter change cancels the previous timer and starts a new
//  one. Only after 150ms of no changes does the action execute.
//

import Foundation

@MainActor
class Debouncer: ObservableObject {
    private var task: Task<Void, Never>?
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.15) {
        self.delay = delay
    }
    
    /// Submit an action to be debounced
    /// - Parameter action: Closure to execute after delay period with no new calls
    func submit(_ action: @escaping () -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                action()
            }
        }
    }
    
    /// Cancel any pending action
    func cancel() {
        task?.cancel()
    }
}

// FILE: PresetStore.swift
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

// FILE: ProgramModel.swift
// [This file is too long - continuing in next section...]

/*
NOTE: Due to length constraints, the remaining files (ProgramModel.swift, 
KnobView.swift, ADSRView.swift, MIDIManager.swift, ProgramEditorView.swift,
MIDIView.swift, CCMappingView.swift, and README.md) would continue here.

To get the complete project, please copy each file separately from the 
artifacts panel, or I can provide them in smaller groups.
*/
