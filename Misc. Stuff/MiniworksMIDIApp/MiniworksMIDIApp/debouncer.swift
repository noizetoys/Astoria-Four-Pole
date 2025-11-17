//
//  Debouncer.swift
//  MiniWorksMIDI
//
//  A simple debouncer that delays execution until a period of inactivity.
//  Used to batch parameter changes when live update is enabled, preventing
//  MIDI flooding when the user drags a knob continuously.
//
//  Design: Each parameter change cancels the previous timer and starts a new
//  one. Only after 150ms of no changes does the action execute.
//

import Foundation
import Combine


@MainActor
class Debouncer: ObservableObject {
    private var task: Task<Void, Never>?
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.15) {
        self.delay = delay
    }
    
    /// Submit an action to be debounced
    /// - Parameter action: Closure to execute after delay period with no new calls
    func submit(_ action: @escaping () -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                action()
            }
        }
    }
    
    /// Cancel any pending action
    func cancel() {
        task?.cancel()
    }
}
