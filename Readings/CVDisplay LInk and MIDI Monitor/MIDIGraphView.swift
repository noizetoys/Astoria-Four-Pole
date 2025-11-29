//
//  MIDIGraphView.swift
//  Astoria Filter Editor
//
//  Self-contained CVDisplayLink implementation (like LFO)
//  Created by James B. Majors on 11/29/25.
//

import SwiftUI
import Combine

// MARK: - CALayer-based Graph Layer

/**
 * MIDIGraphLayer - High-performance CALayer implementation for MIDI visualization
 */
class MIDIGraphLayer: CALayer {
    
    private let backgroundLayer = CALayer()
    private let gridLayer = CAShapeLayer()
    private let ccLineLayer = CAShapeLayer()
    private let ccPointsLayer = CAShapeLayer()
    private let noteMarkersLayer = CALayer()
    private var noteMarkerPool: [CAShapeLayer] = []
    
    private let xOffset: CGFloat = 40
    private let yOffset: CGFloat = 10
    private let graphPadding: CGFloat = 50
    private let verticalPadding: CGFloat = 20
    
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
        addSublayer(noteMarkersLayer)
        
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
        
        noteMarkersLayer.shouldRasterize = true
        noteMarkersLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
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
        noteMarkersLayer.frame = bounds
        
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
        updateNoteMarkers(dataPoints: dataPoints, xStep: xStep, graphHeight: graphHeight)
        
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
    
    private func updateNoteMarkers(dataPoints: [DataPoint], xStep: CGFloat, graphHeight: CGFloat) {
        noteMarkersLayer.sublayers?.forEach { layer in
            if let shapeLayer = layer as? CAShapeLayer {
                shapeLayer.isHidden = true
                noteMarkerPool.append(shapeLayer)
            }
        }
        noteMarkersLayer.sublayers?.removeAll()
        
        for (index, point) in dataPoints.enumerated() {
            guard let noteValue = point.noteValue else { continue }
            
            let x = xOffset + CGFloat(index) * xStep
            
            let normalizedVelocity = noteValue / 127.0
            let velocityY = yOffset + (1.0 - normalizedVelocity) * graphHeight
            
            let velocityGlowLayer = getNoteMarkerLayer()
            let velocityLayer = getNoteMarkerLayer()
            
            velocityGlowLayer.path = CGPath(ellipseIn: CGRect(x: x - 6, y: velocityY - 6, width: 12, height: 12), transform: nil)
            velocityGlowLayer.fillColor = NSColor.red.withAlphaComponent(0.3).cgColor
            velocityGlowLayer.isHidden = false
            noteMarkersLayer.addSublayer(velocityGlowLayer)
            
            velocityLayer.path = CGPath(ellipseIn: CGRect(x: x - 4, y: velocityY - 4, width: 8, height: 8), transform: nil)
            velocityLayer.fillColor = NSColor.red.cgColor
            velocityLayer.isHidden = false
            noteMarkersLayer.addSublayer(velocityLayer)
            
            let ccValue = point.value
            let normalizedCC = ccValue / 127.0
            let ccY = yOffset + (1.0 - normalizedCC) * graphHeight
            
            let positionGlowLayer = getNoteMarkerLayer()
            let positionLayer = getNoteMarkerLayer()
            
            positionGlowLayer.path = CGPath(ellipseIn: CGRect(x: x - 5, y: ccY - 5, width: 10, height: 10), transform: nil)
            positionGlowLayer.fillColor = NSColor.orange.withAlphaComponent(0.3).cgColor
            positionGlowLayer.isHidden = false
            noteMarkersLayer.addSublayer(positionGlowLayer)
            
            positionLayer.path = CGPath(ellipseIn: CGRect(x: x - 3, y: ccY - 3, width: 6, height: 6), transform: nil)
            positionLayer.fillColor = NSColor.orange.cgColor
            positionLayer.isHidden = false
            noteMarkersLayer.addSublayer(positionLayer)
        }
    }
    
    private func getNoteMarkerLayer() -> CAShapeLayer {
        if let layer = noteMarkerPool.popLast() {
            return layer
        } else {
            let layer = CAShapeLayer()
            layer.actions = ["path": NSNull(), "position": NSNull()]
            return layer
        }
    }
}

// MARK: - Self-Contained Graph Container (like LFO)

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
    private var currentCCNumber: ContinuousController = .breathControl
    private var currentChannel: UInt8 = 0
    
    // Notification observers
    private var cancellables = Set<AnyCancellable>()
    
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
    
    // MARK: - CVDisplayLink Setup (like LFO)
    
    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        displayLink = link
        
        guard let displayLink = displayLink else {
            debugPrint(icon: "❌", message: "Failed to create CVDisplayLink")
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
        
        CVDisplayLinkStart(displayLink)
        debugPrint(icon: "✅", message: "CVDisplayLink started")
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .midiSourceConnected)
            .sink { [weak self] _ in
                debugPrint(icon: "🔌", message: "MIDI source connected")
                Task { @MainActor [weak self] in
                    await self?.startListening()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - MIDI Configuration
    
    func configure(ccNumber: ContinuousController, channel: UInt8) {
        debugPrint(icon: "⚙️", message: "Configuring: CC=\(ccNumber.rawValue), Channel=\(channel)")
        currentCCNumber = ccNumber
        currentChannel = channel
        
        // If already connected, restart with new config
        if currentSource != nil {
            Task { @MainActor in
                await startListening()
            }
        }
    }
    
    // MARK: - MIDI Listening (like LFO's parameter updates)
    
    private func startListening() async {
        // Stop existing listeners
        ccListenerTask?.cancel()
        noteListenerTask?.cancel()
        
        // Get first available source
        guard let source = await midiService.availableSources().first else {
            debugPrint(icon: "⚠️", message: "No MIDI source available")
            return
        }
        
        currentSource = source
        debugPrint(icon: "🎹", message: "Starting MIDI listeners for source: \(source.displayName)")
        
        // CC Listener (writes currentCCValue)
        ccListenerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
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
        debugPrint(icon: "🧹", message: "GraphContainerView deinit")
        
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
    var ccNumber: ContinuousController
    var channel: UInt8
    
    func makeNSView(context: Context) -> GraphContainerView {
        debugPrint(icon: "🔨", message: "Creating GraphContainerView")
        let view = GraphContainerView()
        view.configure(ccNumber: ccNumber, channel: channel)
        return view
    }
    
    func updateNSView(_ nsView: GraphContainerView, context: Context) {
        // Only update if configuration changed
        nsView.configure(ccNumber: ccNumber, channel: channel)
    }
    
    static func dismantleNSView(_ nsView: GraphContainerView, coordinator: ()) {
        debugPrint(icon: "💀", message: "Dismantling GraphContainerView")
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
    var ccNumber: ContinuousController
    var channel: UInt8
    
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
                GraphLayerView(ccNumber: ccNumber, channel: channel)
                    .padding(.trailing, 10)
            }
        }
    }
}
