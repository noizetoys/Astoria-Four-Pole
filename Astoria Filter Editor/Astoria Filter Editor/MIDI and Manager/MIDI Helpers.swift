//
//  MIDI Helpers.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/10/25.
//

import Foundation
import CoreMIDI


/*
 From: https://furnacecreek.org/blog/2024-04-06-modern-coremidi-event-handling-with-swift
 
 
 Usage:
        MIDIEventListForEach(list) { message, timestamp in
            switch message.type {
                case .channelVoice1:
 
                    switch message.channelVoice1.status {
                        case .noteOn:
 
                            self.handleNoteOn(message.channelVoice1.note.number,
                                              velocity: message.channelVoice1.note.velocity,
                                              timestamp: timestamp)
                            ...
                            
 */


typealias MIDIForEachBlock = (MIDIUniversalMessage, MIDITimeStamp) -> Void


final class MIDIForEachContext {
    var block: MIDIForEachBlock
    
    init(block: @escaping MIDIForEachBlock) {
        self.block = block
    }
}



func MIDIEventListForEach(_ list: UnsafePointer<MIDIEventList>, _ block: MIDIForEachBlock) {
    withoutActuallyEscaping(block) { escapingClosure in
        let context = MIDIForEachContext(block: escapingClosure)
        
        withExtendedLifetime(context) {
            let contextPointer = Unmanaged.passUnretained(context).toOpaque()
            MIDIEventListForEachEvent(list, { contextPointer, timestamp, message in
                guard let contextPointer
                else { return }
                
                let localContext = Unmanaged<MIDIForEachContext>
                    .fromOpaque(contextPointer)
                    .takeUnretainedValue()
                localContext.block(message, timestamp)
            }, contextPointer)
        }
        
    }
    
}

