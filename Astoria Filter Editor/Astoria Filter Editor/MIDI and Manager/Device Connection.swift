//
//  Device Connection.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/14/25.
//

import Foundation
import CoreMIDI


typealias NoteEvent = (isNoteOn: Bool, channel: UInt8, note: UInt8, velocity: UInt8)
typealias ContinuousControllerEvent = (channel: UInt8, cc: UInt8, value: UInt8)


struct DeviceConnection {
    let source: MIDIDevice
    let destination: MIDIDevice
    
    var sysexContinuation: AsyncStream<[UInt8]>.Continuation?
    var ccContinuation: AsyncStream<ContinuousControllerEvent>.Continuation?
    var noteContinuation: AsyncStream<NoteEvent>.Continuation?
}
