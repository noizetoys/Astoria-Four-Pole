//
//  MIDIGraphLayer.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/29/25.
//

import SwiftUI

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
            positionLayer.fillColor = NSColor.red.cgColor
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

