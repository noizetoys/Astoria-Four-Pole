//
//  MIDI Device Info.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import CoreMIDI



struct MIDIDeviceInfo: Identifiable {
    let id = UUID()
    
    let endpoint: MIDIEndpointRef
    let name: String
    let manufacturer: String
    let uniqueID: Int32
    let isSource: Bool
}
