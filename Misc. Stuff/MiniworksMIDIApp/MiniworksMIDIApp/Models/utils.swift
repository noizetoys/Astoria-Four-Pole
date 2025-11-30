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
