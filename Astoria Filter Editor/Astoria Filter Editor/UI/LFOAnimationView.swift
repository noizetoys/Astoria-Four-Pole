    //
    //  LFOAnimationView.swift
    //  High-performance LFO visualization using CALayer
    //
    //  Created for use in SwiftUI via UIViewRepresentable/NSViewRepresentable
    //

import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformView = UIView
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformView = NSView
typealias PlatformColor = NSColor
#endif

    // MARK: - SwiftUI Wrapper

    /// SwiftUI wrapper for the high-performance CALayer-based LFO view
struct LFOAnimationView: View {
    var lfoSpeed: ProgramParameter
    var lfoShape: ProgramParameter
    @State private var isRunning: Bool = true
    @State private var snapToNote: Bool = false
    
    let minFrequency: Double = 0.008
    let maxFrequency: Double = 261.6
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
                // The high-performance CALayer view
            LFOLayerViewRepresentable(
                lfoSpeed: lfoSpeed,
                lfoShape: lfoShape,
                isRunning: isRunning
            )
            .frame(height: 250)
            .cornerRadius(12)
            .contextMenu {
                ForEach(LFOType.allCases, id: \.self) { waveform in
                    Button(action: {
                        setWaveform(waveform)
                    }) {
                        HStack {
                            Text(waveform.rawValue)
                            if selectedWaveform == waveform {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
//            waveformSelectorView
            frequencyControlView
            infoDisplayView
            
            Spacer()
        }
        .padding()
    }
    
        // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Text("Low Frequency Oscillator")
                .font(.title)
                .bold()
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(isRunning ? "ON" : "OFF")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isRunning ? .green : .gray)
                
                Toggle("", isOn: $isRunning)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
        }
        .padding(.horizontal)
    }
    
    private var waveformSelectorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Waveform")
                .font(.headline)
            
            Picker("Waveform", selection: waveformBinding()) {
                ForEach(LFOType.allCases, id: \.self) { waveform in
                    Text(waveform.rawValue).tag(waveform)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
    
    private var frequencyControlView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Frequency")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.3f Hz", frequency))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            Toggle(isOn: Binding(
                get: { snapToNote },
                set: { newValue in
                    snapToNote = newValue
                    if newValue {
                            // Immediately snap to nearest note when toggled on
                        let snappedFreq = snapFrequencyToNote(frequency)
                        frequency = snappedFreq
                    }
                }
            )) {
                HStack(spacing: 4) {
                    Text("Snap to Note")
                        .font(.subheadline)
                    Image(systemName: "music.note")
                        .font(.caption)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            HStack {
                Text("0.008")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Slider(value: frequencySliderBinding(), in: log10(minFrequency)...log10(maxFrequency))
                
                Text("261.6")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
    
    private var infoDisplayView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Period: \(String(format: "%.3f s", 1.0 / max(frequency, 0.001)))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            
            let musicalNote = frequencyToMusicalNote(frequency)
            HStack {
                Text("Musical Note:")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(musicalNote.description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cyan)
                if abs(musicalNote.cents) < 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Text("(MIDI: \(musicalNote.midiNote))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
    
        // MARK: - Computed Properties & Helpers
    
    private var frequency: Double {
        get {
            let normalized = Double(lfoSpeed.value) / 127.0
            let logMin = log10(minFrequency)
            let logMax = log10(maxFrequency)
            let logFreq = logMin + normalized * (logMax - logMin)
            return pow(10, logFreq)
        }
        nonmutating set {
            let logMin = log10(minFrequency)
            let logMax = log10(maxFrequency)
            let logFreq = log10(newValue)
            let normalized = (logFreq - logMin) / (logMax - logMin)
            let midiValue = UInt8(max(0, min(127, normalized * 127)))
            lfoSpeed.setValue(midiValue)
        }
    }
    
    private var selectedWaveform: LFOType {
        if case .lfo(let lfoType) = lfoShape.containedParameter {
            return lfoType
        }
        return .sine
    }
    
    private func setWaveform(_ waveform: LFOType) {
        lfoShape.containedParameter = .lfo(waveform)
    }
    
    private func waveformBinding() -> Binding<LFOType> {
        Binding(
            get: { selectedWaveform },
            set: { setWaveform($0) }
        )
    }
    
    private func frequencySliderBinding() -> Binding<Double> {
        Binding(
            get: { log10(frequency) },
            set: { newValue in
                var newFrequency = pow(10, newValue)
                
                if snapToNote {
                        // Snap to nearest note frequency
                    newFrequency = snapFrequencyToNote(newFrequency)
                }
                
                frequency = newFrequency
            }
        )
    }
    
    private func snapFrequencyToNote(_ freq: Double) -> Double {
            // Calculate the nearest MIDI note
        let midiNoteFloat = 12.0 * log2(freq / 440.0) + 69.0
        let midiNote = Int(round(midiNoteFloat))
        
            // Convert back to exact frequency for that note
        let exactFreq = 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
        
        return exactFreq
    }
    
    private func frequencyToMusicalNote(_ frequency: Double) -> (description: String, cents: Double, midiNote: Int) {
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let midiNoteFloat = 12.0 * log2(frequency / 440.0) + 69.0
        let midiNote = Int(round(midiNoteFloat))
        let cents = (midiNoteFloat - Double(midiNote)) * 100.0
        let noteIndex = ((midiNote % 12) + 12) % 12
        let octave = Int(floor(Double(midiNote) / 12.0)) - 1
        let noteName = noteNames[noteIndex]
        let centsSign = cents >= 0 ? "+" : ""
        let centsString = String(format: "%@%.0f¢", centsSign, cents)
        return ("\(noteName)\(octave) \(centsString)", cents, midiNote)
    }
}

    // MARK: - Platform-Specific Representable

#if os(iOS)
struct LFOLayerViewRepresentable: UIViewRepresentable {
    var lfoSpeed: ProgramParameter
    var lfoShape: ProgramParameter
    var isRunning: Bool
    
    func makeUIView(context: Context) -> LFOLayerView {
        return LFOLayerView()
    }
    
    func updateUIView(_ uiView: LFOLayerView, context: Context) {
        uiView.update(speed: lfoSpeed.value, shape: lfoShape.containedParameter, isRunning: isRunning)
    }
}
#elseif os(macOS)
struct LFOLayerViewRepresentable: NSViewRepresentable {
    var lfoSpeed: ProgramParameter
    var lfoShape: ProgramParameter
    var isRunning: Bool
    
    func makeNSView(context: Context) -> LFOLayerView {
        return LFOLayerView()
    }
    
    func updateNSView(_ nsView: LFOLayerView, context: Context) {
        nsView.update(speed: lfoSpeed.value, shape: lfoShape.containedParameter, isRunning: isRunning)
    }
}
#endif

    // MARK: - Core Animation View

class LFOLayerView: PlatformView {
    
        // MARK: - Properties
    
#if os(iOS)
    private var displayLink: CADisplayLink?
#elseif os(macOS)
    private var displayLink: CVDisplayLink?
#endif
    
    private var phase: Double = 0
    private var frequency: Double = 1.0
    private var waveformType: LFOType = .sine
    private var lastUpdateTime: CFTimeInterval = 0
    private var _isRunning: Bool = true
    
        // Color range for tracer based on frequency
    private let minFrequency: Double = 0.008
    private let maxFrequency: Double = 261.6
    
        // MARK: - Layers
    
    private let containerLayer = CALayer()
    private let gridLayer = CAShapeLayer()
    private let waveformLayer = CAShapeLayer()
    private let tracerLayer = CALayer()
    private let tracerDotLayer = CAShapeLayer()
    private let trailLayer = CALayer()
    
        // Trail dots for motion effect
    private var trailDots: [CAShapeLayer] = []
    private let trailCount = 3
    
        // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
#if os(iOS)
        backgroundColor = .black
#elseif os(macOS)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
#endif
        
        setupLayers()
        startAnimation()
    }
    
    private func setupLayers() {
#if os(iOS)
        let mainLayer = layer
#elseif os(macOS)
        guard let mainLayer = layer else { return }
#endif
        
            // Container
        containerLayer.frame = mainLayer.bounds
        mainLayer.addSublayer(containerLayer)
        
            // Grid line
        gridLayer.strokeColor = PlatformColor.gray.withAlphaComponent(0.3).cgColor
        gridLayer.lineWidth = 1
        gridLayer.fillColor = nil
        containerLayer.addSublayer(gridLayer)
        
            // Waveform path
        waveformLayer.strokeColor = PlatformColor.green.withAlphaComponent(0.7).cgColor
        waveformLayer.lineWidth = 2
        waveformLayer.fillColor = nil
        waveformLayer.lineCap = .round
        waveformLayer.lineJoin = .round
        containerLayer.addSublayer(waveformLayer)
        
            // Trail layer container
        containerLayer.addSublayer(trailLayer)
        
            // Create trail dots
        for i in 0..<trailCount {
            let dot = CAShapeLayer()
            let size = 10.0 - Double(i) * 2.0
            dot.path = CGPath(ellipseIn: CGRect(x: -size/2, y: -size/2, width: size, height: size), transform: nil)
            dot.fillColor = PlatformColor.cyan.withAlphaComponent(0.3 - Double(i) * 0.08).cgColor
            trailLayer.addSublayer(dot)
            trailDots.append(dot)
        }
        
            // Tracer container
        containerLayer.addSublayer(tracerLayer)
        
            // Main tracer dot
        tracerDotLayer.path = CGPath(ellipseIn: CGRect(x: -7, y: -7, width: 14, height: 14), transform: nil)
        tracerDotLayer.fillColor = PlatformColor.cyan.cgColor
        tracerDotLayer.shadowColor = PlatformColor.cyan.cgColor
        tracerDotLayer.shadowOpacity = 0.8
        tracerDotLayer.shadowRadius = 8
        tracerDotLayer.shadowOffset = .zero
        tracerLayer.addSublayer(tracerDotLayer)
        
        updateWaveformPath()
    }
    
        // MARK: - Layout
    
#if os(iOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
#elseif os(macOS)
    override func layout() {
        super.layout()
        updateLayout()
    }
#endif
    
    private func updateLayout() {
#if os(iOS)
        let mainLayer = layer
#elseif os(macOS)
        guard let mainLayer = layer else { return }
#endif
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        containerLayer.frame = mainLayer.bounds
        updateGridPath()
        updateWaveformPath()
        
        CATransaction.commit()
    }
    
        // MARK: - Path Updates
    
    private func updateGridPath() {
        let path = CGMutablePath()
        let midY = containerLayer.bounds.height / 2
        path.move(to: CGPoint(x: 0, y: midY))
        path.addLine(to: CGPoint(x: containerLayer.bounds.width, y: midY))
        gridLayer.path = path
    }
    
    private func updateWaveformPath() {
        let width = containerLayer.bounds.width
        let height = containerLayer.bounds.height
        let midY = height / 2
        let amplitude = height * 0.4
        let points = 200
        
        let path = CGMutablePath()
        
        for i in 0..<points {
            let x = (Double(i) / Double(points)) * width
            let localPhase = (Double(i) / Double(points)) * 2 * .pi
            let value = calculateWaveform(phase: localPhase, type: waveformType)
            let y = midY - (value * amplitude)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        waveformLayer.path = path
    }
    
        // MARK: - Animation
    
    private func startAnimation() {
#if os(iOS)
            // iOS: Use CADisplayLink for display-synchronized callbacks
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
        
#elseif os(macOS)
            // macOS: Use CVDisplayLink (CADisplayLink is iOS-only)
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        displayLink = link
        
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext) -> CVReturn in
                let view = Unmanaged<LFOLayerView>.fromOpaque(displayLinkContext!).takeUnretainedValue()
                
                DispatchQueue.main.async {
                    view.updateAnimation()
                }
                
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())
            
            CVDisplayLinkStart(displayLink)
        }
#endif
        
        lastUpdateTime = CACurrentMediaTime()
    }
    
    private func stopAnimation() {
#if os(iOS)
        displayLink?.invalidate()
        displayLink = nil
#elseif os(macOS)
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
#endif
    }
    
#if os(iOS)
    @objc private func updateAnimation() {
        updateAnimationFrame()
    }
#elseif os(macOS)
    private func updateAnimation() {
        updateAnimationFrame()
    }
#endif
    
    private func updateAnimationFrame() {
        guard _isRunning else { return }
        
        let currentTime = CACurrentMediaTime()
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
            // Update phase
        let deltaPhase = 2 * .pi * frequency * deltaTime
        phase += deltaPhase
        
            // Keep phase in range
        if phase >= 2 * .pi {
            phase = phase.truncatingRemainder(dividingBy: 2 * .pi)
        }
        
            // Update tracer position
        updateTracerPosition()
    }
    
    private func updateTracerPosition() {
        let width = containerLayer.bounds.width
        let height = containerLayer.bounds.height
        let midY = height / 2
        let amplitude = height * 0.4
        
        let progress = phase / (2 * .pi)
        let x = progress * width
        let value = calculateWaveform(phase: phase, type: waveformType)
        let y = midY - (value * amplitude)
        
            // Calculate color based on frequency (red for slow, cyan for fast)
        let tracerColor = getTracerColor()
        
            // Disable implicit animations for smooth performance
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
            // Update main tracer color and position
        tracerDotLayer.fillColor = tracerColor.cgColor
        tracerDotLayer.shadowColor = tracerColor.cgColor
        tracerLayer.position = CGPoint(x: x, y: y)
        
            // Update trail dots with the same color
        for (index, dot) in trailDots.enumerated() {
            let trailPhase = phase - Double(index + 1) * 0.15
            if trailPhase >= 0 {
                let trailProgress = trailPhase / (2 * .pi)
                let trailX = trailProgress * width
                let trailValue = calculateWaveform(phase: trailPhase, type: waveformType)
                let trailY = midY - (trailValue * amplitude)
                dot.position = CGPoint(x: trailX, y: trailY)
                
                    // Update trail color with appropriate opacity
                let opacity = 0.3 - Double(index) * 0.08
                let trailColor = tracerColor.withAlphaComponent(opacity)
                dot.fillColor = trailColor.cgColor
                dot.isHidden = false
            } else {
                dot.isHidden = true
            }
        }
        
        CATransaction.commit()
    }
    
    private func getTracerColor() -> PlatformColor {
            // Map frequency to hue (red to cyan)
        let hue = min(log10(frequency / minFrequency) / log10(maxFrequency / minFrequency), 1.0)
        
#if os(iOS)
        return UIColor(hue: hue * 0.6, saturation: 0.9, brightness: 1.0, alpha: 1.0)
#elseif os(macOS)
        return NSColor(hue: hue * 0.6, saturation: 0.9, brightness: 1.0, alpha: 1.0)
#endif
    }
    
        // MARK: - Waveform Calculation
    
    private func calculateWaveform(phase: Double, type: LFOType) -> Double {
        let normalizedPhase = phase.truncatingRemainder(dividingBy: 2 * .pi)
        let progress = normalizedPhase / (2 * .pi)
        
        switch type {
            case .sine:
                return sin(normalizedPhase)
                
            case .triangle:
                if progress < 0.25 {
                    return progress * 4
                } else if progress < 0.75 {
                    return 1 - (progress - 0.25) * 4
                } else {
                    return -1 + (progress - 0.75) * 4
                }
                
            case .sawtooth:
                return (progress * 2) - 1
                
            case .pulse:
                return progress < 0.5 ? 1.0 : -1.0
                
            case .sampleHold:
                    // Simple stepped random for now
                let steps = 8
                let stepIndex = Int(progress * Double(steps))
                    // Use phase as seed for consistent random
                let seed = Double(stepIndex) * 1234.5
                let random = sin(seed)
                return random
        }
    }
    
        // MARK: - Parameter Updates
    
    func update(speed: UInt8, shape: ContainedParameter?, isRunning: Bool) {
            // Convert MIDI speed to frequency
        let normalized = Double(speed) / 127.0
        let logMin = log10(0.008)
        let logMax = log10(261.6)
        let logFreq = logMin + normalized * (logMax - logMin)
        frequency = pow(10, logFreq)
        
            // Update waveform type
        if case .lfo(let lfoType) = shape {
            if waveformType != lfoType {
                waveformType = lfoType
                updateWaveformPath()
            }
        }
        
            // Update running state
        if _isRunning != isRunning {
            _isRunning = isRunning
            if isRunning {
                lastUpdateTime = 0 // Reset timing
            }
        }
    }
    
        // MARK: - Cleanup
    
    deinit {
        stopAnimation()
    }
}



#Preview {
    @Previewable @State var program = MiniWorksProgram()
    
    LFOAnimationView(lfoSpeed: program.lfoSpeed, lfoShape: program.lfoShape)
}
