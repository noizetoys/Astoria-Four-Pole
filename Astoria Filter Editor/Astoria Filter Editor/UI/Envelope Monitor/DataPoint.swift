//
//  DataPoint.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//
import Foundation


    // MARK: - Data Point Model

/**
 * DataPoint - Represents a single point on the scrolling graph
 *
 * Properties:
 * - id: Unique identifier for SwiftUI list rendering
 * - value: The CC value at this point in time (0-127)
 * - hasNote: Whether a note event occurred at this point
 * - noteValue: The velocity of the note event (if hasNote is true)
 * - timestamp: When this data point was created
 *
 * The graph displays:
 * - CC values as a connected cyan line
 * - Note velocities as red dots (when hasNote = true)
 * - Note positions as orange dots on the CC line (when hasNote = true)
 */
struct DataPoint: Identifiable {
    let id = UUID()
    let value: CGFloat          // CC value (0-127)
    let hasNote: Bool            // Does this point have a note event?
    let noteValue: CGFloat?      // Note velocity if hasNote is true
    let timestamp: Date          // When this point was created
    
    init(value: CGFloat, hasNote: Bool = false, noteValue: CGFloat? = nil) {
        self.value = value
        self.hasNote = hasNote
        self.noteValue = noteValue
        self.timestamp = Date()
    }
}
