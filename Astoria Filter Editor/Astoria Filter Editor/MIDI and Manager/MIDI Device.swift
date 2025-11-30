//
//  MIDIDevice.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/14/25.
//

import Foundation
import CoreMIDI


nonisolated
public struct MIDIDevice: Identifiable, Hashable, Sendable {
    public let id: MIDIUniqueID
    public let endpoint: MIDIEndpointRef
    public let name: String
    public let manufacturer: String
    public let model: String

    
    public enum DeviceType: Sendable {
        case source
        case destination
    }
    
    public let type: DeviceType
    
    
    init?(endpoint: MIDIEndpointRef, type: DeviceType) throws {
        var name: Unmanaged<CFString>?
        var manufacturer: Unmanaged<CFString>?
        var model: Unmanaged<CFString>?
        var uniqueID: Int32 = 0
        
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyManufacturer, &manufacturer)
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyModel, &model)
        MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
        
        
        guard let name = name?.takeRetainedValue() as String?
        else { return nil }

        self.id = MIDIUniqueID(uniqueID)
        self.endpoint = endpoint
        self.name = name
        self.manufacturer = manufacturer?.takeRetainedValue() as String? ?? "Unknown"
        self.model = model?.takeRetainedValue() as String? ?? "Unknown"
        self.type = type
    }
}
