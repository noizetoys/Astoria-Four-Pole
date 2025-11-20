//
//  ADSRAttackTime.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

import Foundation


// MARK: - Attack Time Mapping (logarithmic)
//
// This block encapsulates all the logic for translating between MIDI-style
// attack values (0...127) and actual time in milliseconds, plus some formatting.
//
// Design goals:
// - Provide a perceptually sensible mapping (log-scale, not linear).
// - Hit exact anchor points from the spec:
///    0   -> 2 ms
///    64  -> 1000 ms (1 second)
///    127 -> 60000 ms (60 seconds)
//
// We implement this as two log-linear segments in "seconds" space:
//
//   1) For 0...64:  0.002 s  -> 1 s
//   2) For 65...127: 1 s     -> 60 s
//
// That lets us interpolate smoothly in log domain while matching the anchors.
//
enum ADSRAttackTime {
    /// Convert an attack value in MIDI space (0...127) to milliseconds.
    ///  - Uses a log interpolation between the three anchor points.
    ///  - Returned value is in ms for easier display and downstream use.
    static func ms(from midi: UInt8) -> Double {
        // Clamp to legal MIDI 0...127 range
        let m = max(0, min(127, midi))
        
        if m <= 64 {
            // Segment 1: 0...64 maps to 0.002s ... 1s
            //
            // t = (m / 64) in [0,1]
            // logTime = lerp(log(0.002), log(1.0), t)
            // timeSec = exp(logTime)
            // return timeSec * 1000
            return exp(lerp(log(0.002), log(1.0), Double(m) / 64.0)) * 1000.0
        } else {
            // Segment 2: 65...127 maps to 1s ... 60s
            //
            // Offset so 65 -> 0 and 127 -> 1
            // t = (m - 64) / 63
            return exp(lerp(log(1.0), log(60.0), Double(m - 64) / 63.0)) * 1000.0
        }
    }
    
    /// Approx inverse mapping (ms -> MIDI).
    ///
    /// Used for placing the log-grid lines in the attack region:
    ///  - We start from interesting time markers (e.g. 10ms, 100ms, 1s, 10s, 60s),
    ///  - Convert each marker to the corresponding MIDI value using the inverse curve,
    ///  - Then treat that MIDI value as a 0...127 position for the x-axis.
    static func midi(fromMilliseconds ms: Double) -> UInt8 {
        // Convert to seconds and clamp into the [0.002, 60] range
        // to stay within our defined mapping.
        let s = max(0.002, min(60_000.0, ms)) / 1000.0
        
        if s <= 1.0 {
            // Inverse of segment 1: [0.002, 1.0] seconds
            //
            // t = (log(s) - log(0.002)) / (log(1.0) - log(0.002))
            // midi = t * 64
            let t = (log(s) - log(0.002)) / (log(1.0) - log(0.002))
            return UInt8(round(t * 64.0))
        } else {
            // Inverse of segment 2: [1.0, 60.0] seconds
            //
            // t = (log(s) - log(1.0)) / (log(60.0) - log(1.0))
            // midi = 64 + t * 63
            let t = (log(s) - log(1.0)) / (log(60.0) - log(1.0))
            return 64 + UInt8(round(t * 63.0))
        }
    }
    
    /// Linear interpolation helper used by ms(from:).
    /// Given endpoints a and b, and a parameter t in [0,1], compute a + (b - a) * t.
    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * max(0, min(1, t))
    }
    
    /// Human-friendly string for an attack time in ms:
    ///   - For < 1000ms, show integer ms (e.g. "123 ms")
    ///   - For >= 1000ms, show seconds to two decimals (e.g. "1.23s")
    ///
    /// This keeps the UI readable for both very short and very long times.
    static func formatted(_ ms: Double) -> String {
        if ms < 1000 {
            return "\(Int(round(ms))) ms"
        } else {
            let seconds = ms / 1000.0
            return String(format: "%.2fs", seconds)
        }
    }
}
