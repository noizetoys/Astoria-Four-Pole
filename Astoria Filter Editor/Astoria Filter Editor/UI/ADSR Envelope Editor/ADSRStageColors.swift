//
//  ADSRStageColors.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//

//import Foundation
import SwiftUI


// MARK: - Stage Colors

/// Colors used for each stage of the ADSR envelope.
/// These are used for:
///  - Drawing the individual envelope segments (Attack, Decay, Sustain, Release)
///  - Coloring the handles
///  - Tinting the corresponding sliders
///
/// If you want to restyle the UI, these are good "knobs" to tweak.
struct ADSRStageColors {
    static let attack  = Color.red
    static let decay   = Color.orange
    static let sustain = Color.green
    static let release = Color.blue
}
