//
//  MIDI Message.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import CoreMIDI


struct MIDIMessage {
    let timeStamp: MIDITimeStamp
    let data: [UInt8]
    let source: MIDIEndpointRef
    
    private var hasSysexStartBit: Bool {
        data.first == MIDIConstants.sysExStartBit
    }
    
    private var hasSysExEndBit: Bool {
        data.last == MIDIConstants.sysExEndBit
    }
    
    var isSysExMessage: Bool { hasSysexStartBit }
    
    var isCompleteSysExMessage: Bool { hasSysexStartBit && hasSysExEndBit }
    
    var isSysExStartMessage: Bool { hasSysexStartBit && !hasSysExEndBit }
    var isSysExContinuationMessage: Bool { !hasSysexStartBit && !hasSysExEndBit }
    var isSysExEndMessage: Bool { !hasSysexStartBit && hasSysExEndBit }
}
