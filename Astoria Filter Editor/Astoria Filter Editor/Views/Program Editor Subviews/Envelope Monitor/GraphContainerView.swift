//
//  GraphContainerView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/29/25.
//

import SwiftUI
import Combine


    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Enhanced Graph Container with Display Control
    // ═══════════════════════════════════════════════════════════════════════════

/**
 * Enhanced GraphContainerView with display on/off control
 *
 * NEW FEATURES:
 * ───────────────────────────────────────────────────────────────────────────
 * - Start/stop CVDisplayLink on demand
 * - Control note marker visibility
 * - Maintains all MIDI listening even when display off
 * - Zero CPU when display off (CVDisplayLink stopped)
 *
 * WHY KEEP MIDI LISTENING WHEN DISPLAY OFF?
 * ───────────────────────────────────────────────────────────────────────────
 * When user turns off display:
 * - CVDisplayLink stops (saves CPU)
 * - MIDI still arrives and updates currentCCValue
 * - When display turned back on, graph shows current state
 * - No missed MIDI data
 *
 * This is like a TV:
 * - Display off = screen off, but tuner still works
 * - Display on = screen shows current channel
 */

/**
 * GraphContainerView - Self-contained MIDI graph with CVDisplayLink
 *
 * Architecture (mirrors LFO):
 * - Owns all state (dataPoints, ccValue, noteValue)
 * - Listens to MIDI directly via AsyncStream
 * - Uses CVDisplayLink for smooth 60 FPS rendering
 * - No external dependencies
 */
@MainActor
class GraphContainerView: NSView {
    
        // MARK: - Properties
    
    private let graphLayer = MIDIGraphLayer()
    private var displayLink: CVDisplayLink?
    
        // MIDI state (updated by AsyncStream)
    private var currentCCValue: UInt8 = 0
    private var currentNoteVelocity: UInt8 = 0
    private var lastNoteVelocity: UInt8 = 0
    
        // Data points for graph
    private var dataPoints: [DataPoint] = []
    private let maxDataPoints = 200
    
        // MIDI listening tasks
    private var ccListenerTask: Task<Void, Never>?
    private var noteListenerTask: Task<Void, Never>?
    
    // Local stop flags to end listener loops without cancelling other tasks
    private var ccStopRequested = false
    private var noteStopRequested = false
    
        // MIDI service
    private let midiService: MIDIService = .shared
    
        // Configuration
    private var currentSource: MIDIDevice?
    private var currentCCNumber: UInt8 = ContinuousController.breathControl
    private var currentChannel: UInt8 = 1
    
        // Notification observers
    private var cancellables = Set<AnyCancellable>()
    
    
// ───────────────────────────────────────────────────────────────────────
// MARK: - Display Control
// ───────────────────────────────────────────────────────────────────────

    /**
     * Display active flag - controls CVDisplayLink
     *
     * HOW IT WORKS:
     * ───────────────────────────────────────────────────────────────────────
     * true:  CVDisplayLink running → updateFromDisplayLink() at 60 Hz
     * false: CVDisplayLink stopped → no updates, zero CPU
     *
     * IMPORTANT: MIDI still updates currentCCValue even when stopped!
     * This means:
     * - User turns off display
     * - Plays MIDI for 30 seconds
     * - Turns display back on
     * - Graph shows current state (not frozen at turn-off point)
     *
     * IMPLEMENTATION:
     * ───────────────────────────────────────────────────────────────────────
     * didSet { } called whenever value changes
     * Starts or stops CVDisplayLink accordingly
     */
    
    
    private var isDisplayActive: Bool = true {
        didSet {
            if isDisplayActive {
                startDisplay()
            }
            else {
                stopDisplay()
            }
        }
    }
    
        // MARK: - Initialization
    
    override var isFlipped: Bool {
        return true
    }
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    
    private func setup() {
        setupLayer()
        setupDisplayLink()
        setupNotifications()
    }
    
    
        // MARK: - Layer Setup
    
    private func setupLayer() {
        wantsLayer = true
        layer = graphLayer
    }
    
        // ───────────────────────────────────────────────────────────────────────
        // MARK: - CVDisplayLink Setup
        // ───────────────────────────────────────────────────────────────────────
    
    /**
     * Creates CVDisplayLink but doesn't start it yet
     *
     * WHY CREATE BUT NOT START?
     * ───────────────────────────────────────────────────────────────────────
     * We want the display link ready to go, but controlled by isDisplayActive.
     * This way:
     * - Fast start (already created)
     * - Fast stop (just stop, not destroy)
     * - Fast restart (just start, not recreate)
     *
     * LIFECYCLE:
     * ───────────────────────────────────────────────────────────────────────
     * init() → Create CVDisplayLink
     * configure(isDisplayActive: true) → Start CVDisplayLink
     * configure(isDisplayActive: false) → Stop CVDisplayLink
     * deinit → Stop and release CVDisplayLink
     */

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        displayLink = link
        
        guard let displayLink = displayLink else {
            debugPrint(icon: "❌", message: "Failed to create CVDisplayLink", type: .trace)
            return
        }
        
        CVDisplayLinkSetOutputCallback(
            displayLink,
            { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, context) -> CVReturn in
                    // On CVDisplayLink thread
                let view = Unmanaged<GraphContainerView>.fromOpaque(context!).takeUnretainedValue()
                
                    // Marshal to main thread
                DispatchQueue.main.async {
                    view.updateFromDisplayLink()
                }
                
                return kCVReturnSuccess
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        if isDisplayActive {
            CVDisplayLinkStart(displayLink)
            debugPrint(icon: "✅", message: "CVDisplayLink started", type: .trace)
        } else {
            debugPrint(icon: "⏸️", message: "CVDisplayLink created but not started", type: .trace)
        }
    }
    
    
        // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .midiSourceConnected)
            .sink { [weak self] _ in
                debugPrint(icon: "🔌", message: "MIDI source connected", type: .trace)
                Task { @MainActor [weak self] in
                    await self?.startListening()
                }
            }
            .store(in: &cancellables)
    }
    
    
        // ───────────────────────────────────────────────────────────────────────
        // MARK: - Display Control Methods
        // ───────────────────────────────────────────────────────────────────────
    
    /**
     * Starts the display (CVDisplayLink)
     *
     * WHAT HAPPENS:
     * ───────────────────────────────────────────────────────────────────────
     * 1. CVDisplayLink starts firing at 60 Hz
     * 2. updateFromDisplayLink() called every 16.7ms
     * 3. Graph updates with current MIDI state
     * 4. CPU usage: ~12% (for 200 point graph)
     *
     * CALLED WHEN:
     * - isDisplayActive set to true
     * - User toggles display on
     */

    private func startDisplay() {
        guard let displayLink else { return }
        
        if CVDisplayLinkIsRunning(displayLink) {
            debugPrint(icon: "⚠️", message: "CVDisplayLink already running", type: .trace)
            return
        }
        
        CVDisplayLinkStart(displayLink)
        debugPrint(icon: "▶️", message: "Display started", type: .trace)
    }
    
    
    /**
     * Stops the display (CVDisplayLink)
     *
     * WHAT HAPPENS:
     * ───────────────────────────────────────────────────────────────────────
     * 1. CVDisplayLink stops firing
     * 2. updateFromDisplayLink() no longer called
     * 3. Graph frozen at last state
     * 4. CPU usage: ~0% (just MIDI listening)
     *
     * IMPORTANT: MIDI still updates currentCCValue!
     * When display restarted, shows current state.
     *
     * CALLED WHEN:
     * - isDisplayActive set to false
     * - User toggles display off
     */
    private func stopDisplay() {
        guard let displayLink else { return }
        
        if !CVDisplayLinkIsRunning(displayLink) {
            debugPrint(icon: "⚠️", message: "CVDisplayLink already stopped", type: .trace)
            return
        }
        
        CVDisplayLinkStop(displayLink)
        debugPrint(icon: "⏸️", message: "Display stopped", type: .trace)

    }
    
        // MARK: - MIDI Configuration
    
    func configure(ccNumber: UInt8,
                   channel: UInt8,
                   isActive: Bool,
                   showVelocity: Bool,
                   showPosition: Bool) {
        debugPrint(icon: "⚙️4️⃣", message: "Configuring: CC=\(ccNumber), Channel=\(channel)", type: .trace)
        currentCCNumber = ccNumber
        currentChannel = channel
        
        isDisplayActive = isActive
        graphLayer.showVelocityMarkers = showVelocity
        graphLayer.showPositionMarkers = showPosition
        
            // If already connected, restart with new config
        Task { @MainActor in
            await startListening()
        }
    }
    
    
        // ───────────────────────────────────────────────────────────────────────
        // MARK: - MIDI Listening
        // ───────────────────────────────────────────────────────────────────────
    
    /**
     * MIDI listening continues regardless of display state
     *
     * WHY?
     * ───────────────────────────────────────────────────────────────────────
     * - Maintains current state
     * - Zero latency when display turned back on
     * - User doesn't miss any MIDI data
     * - Cost is negligible (just writing UInt8 values)
     */

    private func startListening() async {
            // Stop existing listeners
        debugPrint(icon: "🔥5️⃣", message: "GraphContainerView Starting to Listen????", type: .trace)

        // Do not use these, doing so will remove ALL TASKS
//        ccListenerTask?.cancel()
//        noteListenerTask?.cancel()
        
            // Get first available source
        guard
            ccListenerTask == nil,
            noteListenerTask == nil,
            let source = await midiService.availableSources().first
        else {
            debugPrint(icon: "⚠️", message: "No MIDI source available", type: .trace)
            return
        }
        
        currentSource = source
        debugPrint(icon: "🎹", message: "Starting MIDI listeners for source: \(source.name)", type: .trace)
        
            // CC Listener (writes currentCCValue)
        ccListenerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            debugPrint(icon: "🎹", message: " ccListener Triggered from: \(source.name)", type: .trace)

            for await ccData in await self.midiService.ccStream(from: source) {
                if Task.isCancelled { break }
                
                    // Filter for our CC and channel
                guard ccData.cc == self.currentCCNumber else { continue }
                    // Note: Add channel filtering if needed
                
                    // Simple write (CVDisplayLink will sample)
                self.currentCCValue = ccData.value
            }
        }
        
            // Note Listener (writes currentNoteVelocity)
        noteListenerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            debugPrint(icon: "🎹", message: " noteListenerTask Triggered from: \(source.name)", type: .trace)

            for await noteData in await self.midiService.noteStream(from: source) {
                if self.noteStopRequested { break }
                
                    // Note: Add note number and channel filtering if needed
                
                    // Simple write (CVDisplayLink will sample)
                self.currentNoteVelocity = noteData.velocity
            }
        }
    }
    
        // MARK: - CVDisplayLink Update (60 Hz)
    
    private func updateFromDisplayLink() {
            // Sample current MIDI values (written by AsyncStream)
        let ccVal = CGFloat(currentCCValue)
        let currentNote = currentNoteVelocity
        
            // Detect note events (same logic as original ViewModel)
        var noteVal: CGFloat? = nil
        
        if currentNote != lastNoteVelocity && currentNote > 0 {
                // New note event
            noteVal = CGFloat(currentNote)
            lastNoteVelocity = currentNote
        } else if currentNote == 0 && lastNoteVelocity > 0 {
                // Note off
            lastNoteVelocity = 0
        }
        
            // Create data point
        let newPoint = DataPoint(
            value: ccVal,
            hasNote: noteVal != nil,
            noteValue: noteVal
        )
        
        dataPoints.append(newPoint)
        
            // Maintain scrolling (remove old points)
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst(dataPoints.count - maxDataPoints)
        }
        
            // Update display
        graphLayer.updateData(dataPoints)
    }
    
        // MARK: - Layout
    
    override func layout() {
        super.layout()
        graphLayer.frame = bounds
    }
    
        // MARK: - Cleanup
    
    deinit {
        debugPrint(icon: "🧹", message: "GraphContainerView deinit", type: .trace)
        
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        
        ccListenerTask?.cancel()
        noteListenerTask?.cancel()
    }
}
