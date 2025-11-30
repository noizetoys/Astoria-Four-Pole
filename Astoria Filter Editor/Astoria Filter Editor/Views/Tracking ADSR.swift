import SwiftUI

    // MARK: - ADSR Data Model
struct ADSR {
    var attack: Int
    var decay: Int
    var sustain: Int
    var release: Int
    
    var sustainLevel01: CGFloat {
        CGFloat(sustain) / 63.0
    }
    
    init(attack: Int = 32, decay: Int = 32, sustain: Int = 32, release: Int = 32) {
        self.attack = attack.clamped(to: 0...63)
        self.decay = decay.clamped(to: 0...63)
        self.sustain = sustain.clamped(to: 0...63)
        self.release = release.clamped(to: 0...63)
    }
    
    mutating func clamp() {
        attack = attack.clamped(to: 0...63)
        decay = decay.clamped(to: 0...63)
        sustain = sustain.clamped(to: 0...63)
        release = release.clamped(to: 0...63)
    }
}

extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        return max(range.lowerBound, min(range.upperBound, self))
    }
}

    // MARK: - Rotary Knob
struct RotaryKnob: View {
    let label: String
    @Binding var value: Int
    let color: Color
    
    @State private var isDragging = false
    @State private var lastDragValue: CGFloat = 0
    
    private var angle: Double {
        let normalized = Double(value) / 63.0
        return (normalized * 270.0) - 135.0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 76, height: 76)
                
                ActiveArc(angle: angle)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 76, height: 76)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                PointerIndicator(angle: angle, color: color)
            }
            .frame(width: 100, height: 100)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            lastDragValue = gesture.location.y
                        }
                        let deltaY = lastDragValue - gesture.location.y
                        let newValue = value + Int(deltaY * 0.5)
                        value = newValue.clamped(to: 0...63)
                        lastDragValue = gesture.location.y
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            Text("\(value)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

struct ActiveArc: Shape {
    let angle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        path.addArc(center: center, radius: radius,
                    startAngle: Angle(degrees: -135),
                    endAngle: Angle(degrees: angle), clockwise: false)
        return path
    }
}

struct PointerIndicator: View {
    let angle: Double
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .offset(y: -38)
            .rotationEffect(Angle(degrees: angle))
    }
}

    // MARK: - Animated Dot
struct AnimatedDot: View {
    let progress: CGFloat
    let adsr: ADSR
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    
    private var position: CGPoint {
        let totalDynamic = max(1, adsr.attack + adsr.decay + adsr.release)
        let sustainWidth = width * 0.25
        let dynamicWidth = width - sustainWidth
        
        let attackWidth = (CGFloat(adsr.attack) / CGFloat(totalDynamic)) * dynamicWidth
        let decayWidth = (CGFloat(adsr.decay) / CGFloat(totalDynamic)) * dynamicWidth
        let releaseWidth = (CGFloat(adsr.release) / CGFloat(totalDynamic)) * dynamicWidth
        
        let bottom = padding + height
        let top = padding
        let sustainY = bottom - (height * adsr.sustainLevel01)
        let totalWidth = attackWidth + decayWidth + sustainWidth + releaseWidth
        let currentX = padding + (progress * totalWidth)
        
        var x = padding
        var y = bottom
        
        if currentX <= padding + attackWidth {
            x = currentX
            let prog = (currentX - padding) / max(1, attackWidth)
            y = bottom - (prog * height)
        } else if currentX <= padding + attackWidth + decayWidth {
            x = currentX
            let prog = (currentX - padding - attackWidth) / max(1, decayWidth)
            y = top + (prog * (sustainY - top))
        } else if currentX <= padding + attackWidth + decayWidth + sustainWidth {
            x = currentX
            y = sustainY
        } else {
            x = currentX
            let prog = (currentX - padding - attackWidth - decayWidth - sustainWidth) / max(1, releaseWidth)
            y = sustainY + (prog * (bottom - sustainY))
        }
        
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        Circle()
            .fill(RadialGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]),
                                 center: .center, startRadius: 1, endRadius: 8))
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: Color.blue.opacity(0.5), radius: 4)
            .position(position)
    }
}

    // MARK: - Graph Shapes
struct GridBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for level in stride(from: 0.0, through: 1.0, by: 0.25) {
            let y = rect.maxY - (rect.height * level)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

struct ADSRPath: Shape {
    let adsr: ADSR
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let totalDynamic = max(1, adsr.attack + adsr.decay + adsr.release)
        let sustainWidth = width * 0.25
        let dynamicWidth = width - sustainWidth
        
        let attackWidth = (CGFloat(adsr.attack) / CGFloat(totalDynamic)) * dynamicWidth
        let decayWidth = (CGFloat(adsr.decay) / CGFloat(totalDynamic)) * dynamicWidth
        let releaseWidth = (CGFloat(adsr.release) / CGFloat(totalDynamic)) * dynamicWidth
        
        let bottom = padding + height
        let top = padding
        let sustainY = bottom - (height * adsr.sustainLevel01)
        
        var x = padding
        path.move(to: CGPoint(x: x, y: bottom))
        x += attackWidth
        path.addLine(to: CGPoint(x: x, y: top))
        x += decayWidth
        path.addLine(to: CGPoint(x: x, y: sustainY))
        x += sustainWidth
        path.addLine(to: CGPoint(x: x, y: sustainY))
        x += releaseWidth
        path.addLine(to: CGPoint(x: x, y: bottom))
        
        return path
    }
}

struct ADSRPointsAndLabels: View {
    let adsr: ADSR
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    
    var body: some View {
        let totalDynamic = max(1, adsr.attack + adsr.decay + adsr.release)
        let sustainWidth = width * 0.25
        let dynamicWidth = width - sustainWidth
        let attackWidth = (CGFloat(adsr.attack) / CGFloat(totalDynamic)) * dynamicWidth
        let decayWidth = (CGFloat(adsr.decay) / CGFloat(totalDynamic)) * dynamicWidth
        let releaseWidth = (CGFloat(adsr.release) / CGFloat(totalDynamic)) * dynamicWidth
        let bottom = padding + height
        let top = padding
        let sustainY = bottom - (height * adsr.sustainLevel01)
        
        ZStack {
            let attackX = padding + attackWidth
            Circle().fill(Color.blue).frame(width: 8, height: 8).position(x: attackX, y: top)
            Text("A").font(.caption).fontWeight(.semibold).position(x: attackX, y: top - 15)
            
            let decayX = attackX + decayWidth
            Circle().fill(Color.blue).frame(width: 8, height: 8).position(x: decayX, y: sustainY)
            Text("D").font(.caption).fontWeight(.semibold).position(x: decayX, y: sustainY - 15)
            
            let sustainX = decayX + sustainWidth
            Circle().fill(Color.blue).frame(width: 8, height: 8).position(x: sustainX, y: sustainY)
            Text("S").font(.caption).fontWeight(.semibold).position(x: sustainX, y: sustainY - 15)
            
            let releaseX = sustainX + releaseWidth
            Text("R").font(.caption).fontWeight(.semibold).position(x: releaseX, y: bottom - 15)
        }
    }
}

struct ColorBar: View {
    let adsr: ADSR
    let width: CGFloat
    let padding: CGFloat
    let yOffset: CGFloat
    
    var body: some View {
        let totalDynamic = max(1, adsr.attack + adsr.decay + adsr.release)
        let sustainWidth = width * 0.25
        let dynamicWidth = width - sustainWidth
        let attackWidth = (CGFloat(adsr.attack) / CGFloat(totalDynamic)) * dynamicWidth
        let decayWidth = (CGFloat(adsr.decay) / CGFloat(totalDynamic)) * dynamicWidth
        let releaseWidth = (CGFloat(adsr.release) / CGFloat(totalDynamic)) * dynamicWidth
        
        HStack(spacing: 0) {
            ZStack {
                Rectangle().fill(Color.red.opacity(0.7))
                Text("\(adsr.attack)").font(.caption).fontWeight(.semibold).foregroundColor(.white)
            }
            .frame(width: attackWidth)
            
            ZStack {
                Rectangle().fill(Color.orange.opacity(0.7))
                Text("\(adsr.decay)").font(.caption).fontWeight(.semibold).foregroundColor(.white)
            }
            .frame(width: decayWidth)
            
            ZStack {
                Rectangle().fill(Color.green.opacity(0.7))
                Text("\(adsr.sustain)").font(.caption).fontWeight(.semibold).foregroundColor(.white)
            }
            .frame(width: sustainWidth)
            
            ZStack {
                Rectangle().fill(Color.purple.opacity(0.7))
                Text("\(adsr.release)").font(.caption).fontWeight(.semibold).foregroundColor(.white)
            }
            .frame(width: releaseWidth)
        }
        .frame(height: 20)
        .offset(x: padding, y: yOffset)
    }
}

    // MARK: - Graph View
struct ADSREnvelopeGraph: View {
    let adsr: ADSR
    let animationProgress: CGFloat
    let isAnimating: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 40
            let width = geometry.size.width
            let height = geometry.size.height - 40
            let graphWidth = width - 2 * padding
            let graphHeight = height - 2 * padding
            
            ZStack {
                GridBackground().stroke(Color.gray.opacity(0.1), lineWidth: 1).padding(padding)
                ADSRPath(adsr: adsr, width: graphWidth, height: graphHeight, padding: padding)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                ADSRPointsAndLabels(adsr: adsr, width: graphWidth, height: graphHeight, padding: padding)
                
                if isAnimating {
                    AnimatedDot(progress: animationProgress, adsr: adsr, width: graphWidth,
                                height: graphHeight, padding: padding)
                }
                
                ColorBar(adsr: adsr, width: graphWidth, padding: padding, yOffset: height)
            }
        }
        .frame(height: 340)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

    // MARK: - Animation Phase
enum ADSRPhase {
    case idle
    case attack
    case decay
    case sustain
    case release
}

    // MARK: - Main Editor
struct ADSREnvelopeEditor: View {
    @State private var adsr = ADSR()
    @State private var isAnimating = false
    @State private var animationProgress: CGFloat = 0.0
    @State private var currentPhase: ADSRPhase = .idle
    
    private var totalDuration: Double {
        let scale = 2.0 / 63.0
        return Double(adsr.attack) * scale + Double(adsr.decay) * scale + 0.5 + Double(adsr.release) * scale
    }
    
        // Calculate durations for each phase
    private var attackDuration: Double {
        Double(adsr.attack) * (2.0 / 63.0)
    }
    
    private var decayDuration: Double {
        Double(adsr.decay) * (2.0 / 63.0)
    }
    
    private var releaseDuration: Double {
        Double(adsr.release) * (2.0 / 63.0)
    }
    
        // Calculate progress thresholds for each phase
    private var attackEndProgress: CGFloat {
        let total = totalDuration
        return CGFloat(attackDuration / total)
    }
    
    private var decayEndProgress: CGFloat {
        let total = totalDuration
        return CGFloat((attackDuration + decayDuration) / total)
    }
    
    private var sustainEndProgress: CGFloat {
        let total = totalDuration
        return CGFloat((attackDuration + decayDuration + 0.5) / total)
    }
    
        // MIDI Note On - Start attack phase
    private func startEnvelope() {
        animationProgress = 0.0
        isAnimating = true
        currentPhase = .attack
        
            // Animate through attack
        withAnimation(.linear(duration: attackDuration)) {
            animationProgress = attackEndProgress
        }
        
            // Schedule decay phase
        DispatchQueue.main.asyncAfter(deadline: .now() + attackDuration) {
            if currentPhase == .attack {
                startDecay()
            }
        }
    }
    
    private func startDecay() {
        currentPhase = .decay
        withAnimation(.linear(duration: decayDuration)) {
            animationProgress = decayEndProgress
        }
        
            // Schedule sustain phase
        DispatchQueue.main.asyncAfter(deadline: .now() + decayDuration) {
            if currentPhase == .decay {
                startSustain()
            }
        }
    }
    
    private func startSustain() {
        currentPhase = .sustain
            // Sustain holds - no automatic progression
            // In real use, this would wait for MIDI Note Off
    }
    
        // MIDI Note Off - Jump to release phase
    private func startRelease() {
        guard isAnimating else { return }
        
        currentPhase = .release
        
            // Calculate where we are now and where release should start
        let releaseStartProgress = sustainEndProgress
        
        withAnimation(.linear(duration: releaseDuration)) {
            animationProgress = 1.0
        }
        
            // Auto-cleanup after release completes
        DispatchQueue.main.asyncAfter(deadline: .now() + releaseDuration) {
            if currentPhase == .release {
                stopEnvelope()
            }
        }
    }
    
    private func stopEnvelope() {
        isAnimating = false
        currentPhase = .idle
        animationProgress = 0.0
    }
    
        // Original full animation for testing
    private func startAnimation() {
        animationProgress = 0.0
        isAnimating = true
        currentPhase = .attack
        withAnimation(.linear(duration: totalDuration)) {
            animationProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            stopEnvelope()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("ADSR Envelope Editor").font(.largeTitle).fontWeight(.bold)
                ADSREnvelopeGraph(adsr: adsr, animationProgress: animationProgress, isAnimating: isAnimating)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    RotaryKnob(label: "Attack", value: $adsr.attack, color: .red)
                    RotaryKnob(label: "Decay", value: $adsr.decay, color: .orange)
                    RotaryKnob(label: "Sustain", value: $adsr.sustain, color: .green)
                    RotaryKnob(label: "Release", value: $adsr.release, color: .purple)
                }
                .padding(.horizontal)
                
                HStack {
                    HStack(spacing: 16) {
                        Text("A: \(adsr.attack)").font(.caption)
                        Text("D: \(adsr.decay)").font(.caption)
                        Text("S: \(adsr.sustain)").font(.caption)
                        Text("R: \(adsr.release)").font(.caption)
                    }
                    
                        // Phase indicator
                    Text("Phase: \(phaseLabel)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(phaseColor)
                    
                    Spacer()
                    
                        // MIDI-style controls
                    Button(action: { startEnvelope() }) {
                        Label("Note On", systemImage: "play.circle.fill")
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color.green).cornerRadius(8)
                    }
                    .disabled(isAnimating && currentPhase != .idle)
                    
                    Button(action: { startRelease() }) {
                        Label("Note Off", systemImage: "stop.circle.fill")
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color.orange).cornerRadius(8)
                    }
                    .disabled(!isAnimating || currentPhase == .release || currentPhase == .idle)
                    
                    Button(action: { startAnimation() }) {
                        Label(isAnimating ? "Stop" : "Play", systemImage: isAnimating ? "stop.fill" : "play.fill")
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isAnimating ? Color.red : Color.blue).cornerRadius(8)
                    }
                    
                    Button(action: { adsr = ADSR(); stopEnvelope() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color.gray).cornerRadius(8)
                    }
                }
                .padding().background(Color.gray.opacity(0.1)).cornerRadius(12).padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                                   startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
    }
    
    private var phaseLabel: String {
        switch currentPhase {
            case .idle: return "Idle"
            case .attack: return "Attack"
            case .decay: return "Decay"
            case .sustain: return "Sustain"
            case .release: return "Release"
        }
    }
    
    private var phaseColor: Color {
        switch currentPhase {
            case .idle: return .gray
            case .attack: return .red
            case .decay: return .orange
            case .sustain: return .green
            case .release: return .purple
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ADSREnvelopeEditor()
        }
    }
}

#Preview {
    ContentView()
}
