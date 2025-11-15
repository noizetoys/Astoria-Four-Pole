//
//  MIDI Manager Debugger.swift
//  Program Change Send Test
//
//  Created by James B. Majors on 11/11/25.
//

import Foundation
import CoreMIDI


fileprivate func verbosePrint(_ fileName: String = #file,
                              _ function: String = #function,
                              _ line: Int = #line,
                              _ column: Int = #column,
                              emoji: String = "🎹",
                              message: String) {
    #if DEBUG
    let fileName = (fileName as NSString).lastPathComponent
    let separator: String = String(repeating: emoji, count: 20)
    
    print("\n\(separator)")
    print("\(fileName)\n\(function) [\(line) : \(column)]:\n\n\(message)")
    print("\(separator)\n")
    
#endif
}

//var name: Unmanaged<CFString>?
//MIDIObjectGetStringProperty(source.endpoint, kMIDIPropertyDisplayName, &name)
//let sourceName = name?.takeRetainedValue() as String? ?? "N/A"


    public func debugClientCreation(client: MIDIClientRef, status: OSStatus) {
        #if DEBUG || DEBUG_MIDI_CLIENT_CREATION
        var properties: Unmanaged<CFPropertyList>?
        var propertiesString: String = "No Properties"
        
        if MIDIObjectGetProperties(client, &properties, true) == noErr {
            if let props = properties?.takeRetainedValue() {
                propertiesString = "\(props)"
            }
        }
        
        verbosePrint(message: """
client: \(client) 
status: \(status.text)

properties: \(propertiesString)
""")
#endif
    }



public func debugPortCreation(endpoint: MIDIEndpointRef, status: OSStatus) {
    #if DEBUG || DEBUG_MIDI_ENDPOINT_CREATION
    var properties: Unmanaged<CFPropertyList>?
    var propertiesString: String = "No Properties"
    if MIDIObjectGetProperties(endpoint, &properties, true) == noErr {
        if let props = properties?.takeRetainedValue() {
            propertiesString = "\(props)"
        }
    }

    verbosePrint(message: """
endPoint: \(endpoint)
status: \(status.text)

Properties: \(propertiesString)
""")
    #endif
}


func debugConfigureEndpoints(_ sources: [MIDIDevice], isSource: Bool = true) {
#if DEBUG || DEBUG_SOURCES
    var propStrings: [String] = []
    
    for (index, source) in sources.enumerated() {
        var properties: Unmanaged<CFPropertyList>?
        var propertiesString: String = "[\(index)] No Properties"
        
        if MIDIObjectGetProperties(source.endpoint, &properties, true) == noErr {
            if let props = properties?.takeRetainedValue() {
                propertiesString = "\(index): \(props)\n"
            }
            propStrings.append(propertiesString)
        }
    }
    
    var outputString = ""
    for propString in propStrings {
        outputString += "\(propString)\n"
    }
    
    let typeString = isSource ? "Sources" : "Destinations"
    
    verbosePrint(message: """
            \(typeString) Count: \(sources.count)
            
            properties:
            \(outputString)
            """)
#endif
}


func debugConnectEndpoints(source: MIDIDevice, destination: MIDIDevice, status: OSStatus) {
    verbosePrint(message: """
        source: \(source.name)  ← →  destination: \(destination.name) 
        status: \(status.text)
        """)
}



