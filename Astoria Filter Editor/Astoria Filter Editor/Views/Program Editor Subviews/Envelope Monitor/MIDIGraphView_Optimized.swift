    //
    //  MIDIGraphView.swift
    //  Astoria Filter Editor
    //
    //  Self-contained CVDisplayLink implementation (like LFO)
    //  Created by James B. Majors on 11/29/25.
    //

import SwiftUI
import Combine


//
//  MIDIGraphView_WithControls.swift
//  Enhanced version with display on/off and note marker visibility controls
//
//  WHAT THIS ADDS:
//  ═══════════════════════════════════════════════════════════════════════════
//  1. Display on/off toggle - Start/stop CVDisplayLink
//  2. Show/hide note markers - Toggle note event visualization
//  3. Show/hide velocity markers - Toggle velocity dots separately
//  4. Show/hide position markers - Toggle position dots separately
//
//  IMPLEMENTATION STRATEGY:
//  ═══════════════════════════════════════════════════════════════════════════
//  - CVDisplayLink start/stop for display control
//  - Layer visibility flags for note/velocity/position
//  - SwiftUI bindings for reactive updates
//  - Maintains all performance optimizations
//
//  USAGE:
//  ═══════════════════════════════════════════════════════════════════════════
//  @State private var isDisplayActive = true
//  @State private var showNoteMarkers = true
//  @State private var showVelocity = true
//  @State private var showPosition = true
//
//  MIDIGraphView(
//      ccNumber: .breathControl,
//      channel: 0,
//      isDisplayActive: $isDisplayActive,
//      showNoteMarkers: $showNoteMarkers,
//      showVelocity: $showVelocity,
//      showPosition: $showPosition
//  )
//
//  ═══════════════════════════════════════════════════════════════════════════



    // MARK: - CALayer-based Graph Layer


// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Enhanced CALayer with Visibility Controls
// ═══════════════════════════════════════════════════════════════════════════

/**
   * Enhanced MIDIGraphLayer with visibility controls
   *
   * NEW FEATURES:
   * ───────────────────────────────────────────────────────────────────────────
   * - showVelocityMarkers: Toggle red velocity dots
   * - showPositionMarkers: Toggle orange position dots
   * - Separate control of each marker type
   *
   * WHY SEPARATE CONTROLS?
   * ───────────────────────────────────────────────────────────────────────────
    * Users might want to see:
    * - Only velocity (how hard they played)
    * - Only position (where on CC line)
    * - Both (full visualization)
    * - Neither (just CC line)
    *
    * HOW IT WORKS:
    * ───────────────────────────────────────────────────────────────────────────
    * Each marker type is in a separate container layer.
    * Setting layer.isHidden = true makes GPU skip compositing.
    * No CPU cost when hidden (GPU just doesn't composite that layer).
    */
/**
 * MIDIGraphLayer - High-performance CALayer implementation for MIDI visualization
 */
class MIDIGraphLayer: CALayer {
    
    private let backgroundLayer = CALayer()
    private let gridLayer = CAShapeLayer()
    private let ccLineLayer = CAShapeLayer()
    private let ccPointsLayer = CAShapeLayer()
    
    private let velocityMarkersLayer = CALayer()
    private let positionMarkersLayer = CALayer()
    
    private var noteMarkerPool: [CAShapeLayer] = []
    
    private let xOffset: CGFloat = 40
    private let yOffset: CGFloat = 10
    private let graphPadding: CGFloat = 50
    private let verticalPadding: CGFloat = 20
    
        // ───────────────────────────────────────────────────────────────────────
        // MARK: - Visibility Properties
        // ───────────────────────────────────────────────────────────────────────
    
        /**
            * Visibility flags - control what's displayed
            *
            * HOW LAYER VISIBILITY WORKS:
            * ───────────────────────────────────────────────────────────────────────
            * layer.isHidden = true:
            *   - GPU skips compositing this layer
            *   - No rendering cost
            *   - Layer still exists, just not drawn
            *   - Instant toggle (no overhead)
            *
            * layer.isHidden = false:
            *   - GPU composites layer normally
            *   - Uses cached rasterized version (fast)
            *   - Instant toggle
            *
            * PERFORMANCE:
            * ───────────────────────────────────────────────────────────────────────
            * Hiding a layer: ~0 CPU (GPU just skips it)
            * Showing a layer: ~0 CPU (GPU uses cached version)
            * Toggle cost: Negligible
            */
    var showVelocityMarkers: Bool = true {
        didSet {
            velocityMarkersLayer.isHidden = !showVelocityMarkers
        }
    }
    
    
    var showPositionMarkers: Bool = true {
        didSet {
            positionMarkersLayer.isHidden = !showPositionMarkers
        }
    }
    
    
    override init() {
        super.init()
        setupLayers()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    
    private func setupLayers() {
        backgroundColor = NSColor.black.withAlphaComponent(0.9).cgColor
        
        addSublayer(backgroundLayer)
        addSublayer(gridLayer)
        addSublayer(ccLineLayer)
        addSublayer(ccPointsLayer)
        
        addSublayer(velocityMarkersLayer)
        addSublayer(positionMarkersLayer)

        ccLineLayer.strokeColor = NSColor.cyan.cgColor
        ccLineLayer.fillColor = nil
        ccLineLayer.lineWidth = 2
        ccLineLayer.lineCap = .round
        ccLineLayer.lineJoin = .round
        ccLineLayer.shouldRasterize = true
        ccLineLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        ccPointsLayer.fillColor = NSColor.cyan.cgColor
        ccPointsLayer.shouldRasterize = true
        ccPointsLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        velocityMarkersLayer.shouldRasterize = true
        velocityMarkersLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        positionMarkersLayer.shouldRasterize = true
        positionMarkersLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        actions = ["position": NSNull(), "bounds": NSNull(), "path": NSNull()]
        CATransaction.commit()
    }
    
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        backgroundLayer.frame = bounds
        gridLayer.frame = bounds
        ccLineLayer.frame = bounds
        ccPointsLayer.frame = bounds
        
        velocityMarkersLayer.frame = bounds
        positionMarkersLayer.frame = bounds

        drawGrid()
    }
    
    
    private func drawGrid() {
        let path = CGMutablePath()
        let graphWidth = bounds.width - graphPadding
        let graphHeight = bounds.height - verticalPadding
        
        for i in 0..<5 {
            let y = yOffset + (graphHeight * CGFloat(i) / 4.0)
            path.move(to: CGPoint(x: xOffset, y: y))
            path.addLine(to: CGPoint(x: xOffset + graphWidth, y: y))
        }
        
        gridLayer.path = path
        gridLayer.strokeColor = NSColor.gray.withAlphaComponent(0.3).cgColor
        gridLayer.lineWidth = 1
    }
    
    
    func updateData(_ dataPoints: [DataPoint]) {
        guard dataPoints.count > 1 else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let graphWidth = bounds.width - graphPadding
        let graphHeight = bounds.height - verticalPadding
        let xStep = graphWidth / CGFloat(dataPoints.count - 1)
        
        updateCCLine(dataPoints: dataPoints, xStep: xStep, graphHeight: graphHeight)
        updateCCPoints(dataPoints: dataPoints, xStep: xStep, graphHeight: graphHeight)
        
        updateVelocityMarkers(dataPoints: dataPoints, xStep: xStep, graphHeight: graphHeight)
        updatePositionMarkers(dataPoints: dataPoints, xStep: xStep, graphHeight: graphHeight)

        CATransaction.commit()
    }
    
    
    private func updateCCLine(dataPoints: [DataPoint], xStep: CGFloat, graphHeight: CGFloat) {
        let path = CGMutablePath()
        
        for (index, point) in dataPoints.enumerated() {
            let x = xOffset + CGFloat(index) * xStep
            let normalizedValue = point.value / 127.0
            let y = yOffset + (1.0 - normalizedValue) * graphHeight
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        ccLineLayer.path = path
    }
    
    
    private func updateCCPoints(dataPoints: [DataPoint], xStep: CGFloat, graphHeight: CGFloat) {
        let path = CGMutablePath()
        
        for (index, point) in dataPoints.enumerated() {
            let x = xOffset + CGFloat(index) * xStep
            let normalizedValue = point.value / 127.0
            let y = yOffset + (1.0 - normalizedValue) * graphHeight
            
            path.addEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
        }
        
        ccPointsLayer.path = path
    }
    
    
        // ───────────────────────────────────────────────────────────────────────
        // MARK: - Velocity Markers (Red - Note Velocity)
        // ───────────────────────────────────────────────────────────────────────
    
        /**
            * Updates velocity markers (red dots showing how hard note was played)
            *
            * OPTIMIZATION:
            * ───────────────────────────────────────────────────────────────────────
            * Even if layer is hidden, we still update the content.
            * This is faster than checking visibility before updating because:
            * 1. Update is fast (just setting layer properties)
            * 2. GPU will skip compositing anyway if hidden
            * 3. No branching logic needed
            * 4. Content ready when user toggles visibility
            */
    
    
    
    private func updateVelocityMarkers(dataPoints: [DataPoint], xStep: CGFloat, graphHeight: CGFloat) {
        velocityMarkersLayer.sublayers?.forEach { layer in
            if let shapeLayer = layer as? CAShapeLayer {
                shapeLayer.isHidden = true
                noteMarkerPool.append(shapeLayer)
            }
        }
        velocityMarkersLayer.sublayers?.removeAll()
        
        for (index, point) in dataPoints.enumerated() {
            guard let noteValue = point.noteValue else { continue }
            
            let x = xOffset + CGFloat(index) * xStep
            
            let normalizedVelocity = noteValue / 127.0
            let velocityY = yOffset + (1.0 - normalizedVelocity) * graphHeight
            
            let velocityGlowLayer = getNoteMarkerLayer()
            
            velocityGlowLayer.path = CGPath(
                ellipseIn: CGRect(x: x - 6, y: velocityY - 6, width: 12, height: 12),
                transform: nil)
            velocityGlowLayer.fillColor = NSColor.red.withAlphaComponent(0.3).cgColor
            velocityGlowLayer.isHidden = false
            velocityMarkersLayer.addSublayer(velocityGlowLayer)
            
            let positionLayer = getNoteMarkerLayer()
            positionLayer.path = CGPath(
                ellipseIn: CGRect(x: x - 4, y: velocityY - 4, width: 8, height: 8),
                transform: nil)
            positionLayer.fillColor = NSColor.orange.cgColor
            positionLayer.isHidden = false
            velocityMarkersLayer.addSublayer(positionLayer)
        }
    }
    
    
    private func updatePositionMarkers(dataPoints: [DataPoint], xStep: CGFloat, graphHeight: CGFloat) {
        positionMarkersLayer.sublayers?.forEach { layer in
            if let shapeLayer = layer as? CAShapeLayer {
                shapeLayer.isHidden = true
                noteMarkerPool.append(shapeLayer)
            }
        }
        
        positionMarkersLayer.sublayers?.removeAll()
        
        for (index, point) in dataPoints.enumerated() {
            guard point.noteValue != nil else { continue }
            
            let x = xOffset + CGFloat(index) * xStep
            let ccValue = point.value
            let normalizedCC = ccValue / 127.0
            let ccY = yOffset + (1.0 - normalizedCC) * graphHeight
            
            let glowLayer = getNoteMarkerLayer()
            glowLayer.path = CGPath(
                ellipseIn: CGRect(x: x - 5, y: ccY - 5, width: 10, height: 10),
                transform: nil)
            glowLayer.fillColor = NSColor.orange.withAlphaComponent(0.3).cgColor
            glowLayer.isHidden = false
            positionMarkersLayer.addSublayer(glowLayer)
            
            let markerlayer = getNoteMarkerLayer()
            markerlayer.path = CGPath(
                ellipseIn: CGRect(x: x - 3, y: ccY - 3, width: 6, height: 6),
                transform: nil)
            markerlayer.fillColor = NSColor.orange.cgColor
            markerlayer.isHidden = false
            positionMarkersLayer.addSublayer(markerlayer)
        }
    }
    
    
    private func getNoteMarkerLayer() -> CAShapeLayer {
        if let layer = noteMarkerPool.popLast() {
            return layer
        }
        else {
            let layer = CAShapeLayer()
            layer.actions = ["path": NSNull(), "position": NSNull()]
            return layer
        }
    }
}

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
//        if currentSource != nil {
            Task { @MainActor in
                await startListening()
            }
//        }
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

        ccListenerTask?.cancel()
        noteListenerTask?.cancel()
        
            // Get first available source
        guard
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
                if Task.isCancelled { break }
                
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

    // MARK: - NSViewRepresentable

/**
 * GraphLayerView - Bridge to SwiftUI
 *
 * Simplified (like LFO):
 * - Passes simple configuration values
 * - No @ObservedObject
 * - View handles everything
 */
struct GraphLayerView: NSViewRepresentable {
    var ccNumber: UInt8
    var channel: UInt8
    
        /// NEW: Control bindings
    @Binding var isDisplayActive: Bool
    @Binding var showVelocity: Bool
    @Binding var showPosition: Bool

    
    
//    init(ccNumber: UInt8, channel: UInt8) {
//        debugPrint(icon: "🔥3️⃣", message: "GraphLayerView Created", type: .trace)
//        self.ccNumber = ccNumber
//        self.channel = channel
//    }
    
    func makeNSView(context: Context) -> GraphContainerView {
        debugPrint(icon: "🔨", message: "Creating GraphContainerView", type: .trace)
        let view = GraphContainerView()
        view.configure(ccNumber: ccNumber,
                       channel: channel,
                       isActive: isDisplayActive,
                       showVelocity: showVelocity,
                       showPosition: showPosition)
        return view
    }
    
    
    func updateNSView(_ nsView: GraphContainerView, context: Context) {
            // Only update if configuration changed
        nsView.configure(ccNumber: ccNumber,
                         channel: channel,
                         isActive: isDisplayActive,
                         showVelocity: showVelocity,
                         showPosition: showPosition)
    }
    
    
    static func dismantleNSView(_ nsView: GraphContainerView, coordinator: ()) {
        debugPrint(icon: "💀", message: "Dismantling GraphContainerView", type: .trace)
    }
}

    // MARK: - SwiftUI Wrapper

/**
 * MIDIGraphView - SwiftUI interface (simplified)
 *
 * No longer needs GraphViewModel!
 * Just passes configuration to self-contained view.
 */
struct MIDIGraphView: View {
    var ccNumber: UInt8
    var channel: UInt8
    
    @Binding var isOn: Bool
    @Binding var showVelocity: Bool
    @Binding var showNotes: Bool

    
//    init(ccNumber: UInt8,
//         channel: UInt8,
//         isOn: Binding<Bool>,
//         showVelocity: Bool,
//         showNotes: Bool) {
//        self.ccNumber = ccNumber
//        self.channel = channel
//        self.isOn = isOn
//        self.showVelocity = showVelocity
//        self.showNotes = showNotes
//    }
    
//    init(ccNumber: UInt8, channel: UInt8) {
//        debugPrint(icon: "🔥2️⃣", message: "MIDIGraphView Created", type: .trace)
//        self.ccNumber = ccNumber
//        self.channel = channel
//    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.9)
                
                    // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                    // Y-axis labels
                HStack {
                    VStack {
                        Text("127")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text("96")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("64")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text("32")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("0")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .frame(width: 30)
                    
                    Spacer()
                }
                .padding(.leading, 5)
                
                    // Self-contained graph view
                GraphLayerView(ccNumber: ccNumber,
                               channel: channel,
                               isDisplayActive: $isOn,
                               showVelocity: $showVelocity,
                               showPosition: $showNotes)
                    .padding(.trailing, 10)
            }
        }
    }
}
