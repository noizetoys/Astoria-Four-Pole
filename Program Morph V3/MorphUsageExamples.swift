//
//  MorphUsageExamples.swift
//  Astoria Filter Editor
//
//  Examples and documentation for the Program Morph system
//

import SwiftUI

/*
 PROGRAM MORPH SYSTEM
 ====================
 
 A comprehensive system for smoothly morphing between two MiniWorks programs by
 interpolating parameter values and sending CC messages over time.
 
 KEY FEATURES:
 -------------
 1. Automatic morphing with configurable duration and update rate
 2. Manual morph position control with real-time CC sending
 3. Smooth interpolation curves (ease-in-out by default)
 4. Parameter visualization showing changes between programs
 5. Swap programs, reset to source, or jump to destination
 6. Configurable CC message sending rate (10-60 Hz)
 
 ARCHITECTURE:
 ------------
 
 ProgramMorph (Model)
 ├─ Manages two programs (source and destination)
 ├─ Handles interpolation logic
 ├─ Controls Timer-based automatic morphing
 └─ Sends CC notifications via NotificationCenter
 
 MorphControlView (Basic UI)
 └─ Simple interface for quick morphing
 
 AdvancedMorphView (Full UI)
 ├─ Visual parameter comparison
 ├─ Morph curve selection
 └─ Detailed parameter change visualization
 
 USAGE EXAMPLES:
 ==============
*/

// MARK: - Example 1: Basic Usage

struct BasicMorphExample: View {
    @State private var morph: ProgramMorph
    
    init() {
        let source = MiniWorksProgram()
        source.programName = "Smooth Pad"
        source.cutoff.setValue(40)
        source.resonance.setValue(20)
        
        let dest = MiniWorksProgram()
        dest.programName = "Bright Lead"
        dest.cutoff.setValue(120)
        dest.resonance.setValue(80)
        
        _morph = State(initialValue: ProgramMorph(source: source, destination: dest))
    }
    
    var body: some View {
        VStack {
            MorphControlView(morph: morph)
        }
    }
}

// MARK: - Example 2: Programmatic Control

class MorphController: ObservableObject {
    let morph: ProgramMorph
    
    init(source: MiniWorksProgram, destination: MiniWorksProgram) {
        self.morph = ProgramMorph(source: source, destination: destination)
    }
    
    // Start a 3-second morph to destination
    func startSlowMorph() {
        morph.morphDuration = 3.0
        morph.startMorph(to: 1.0)
    }
    
    // Quick snap to 50% position
    func snapToMiddle() {
        morph.setMorphPosition(0.5)
    }
    
    // Reverse morph back to source
    func reverseMorph() {
        morph.morphDuration = 2.0
        morph.startMorph(to: 0.0)
    }
    
    // Set specific position without sending CC
    func setPositionSilently(_ position: Double) {
        let originalSetting = morph.sendCCMessages
        morph.sendCCMessages = false
        morph.setMorphPosition(position, sendCC: false)
        morph.sendCCMessages = originalSetting
    }
}

// MARK: - Example 3: Integration with MIDI Manager

/*
 To integrate with your MIDI system, listen for the parameter update notifications:
 
 class MIDIManager: ObservableObject {
     private var cancellables = Set<AnyCancellable>()
     
     init() {
         // Listen for morph parameter updates
         NotificationCenter.default.publisher(for: .programParameterUpdated)
             .sink { [weak self] notification in
                 guard let type = notification.userInfo?[SysExConstant.parameterType] as? MiniWorksParameter,
                       let value = notification.userInfo?[SysExConstant.parameterValue] as? UInt8 else {
                     return
                 }
                 
                 self?.sendCC(type.ccValue, value: value)
             }
             .store(in: &cancellables)
     }
     
     func sendCC(_ cc: UInt8, value: UInt8) {
         // Send your MIDI CC message here
         print("Sending CC \(cc): \(value)")
     }
 }
*/

// MARK: - Example 4: Advanced Features

struct AdvancedMorphExample: View {
    @State private var morph: ProgramMorph
    @State private var isMorphing = false
    
    init() {
        // Create two distinctly different programs
        let source = MiniWorksProgram()
        source.programName = "Ambient Drone"
        source.vcfEnvelopeAttack.setValue(100)
        source.vcfEnvelopeDecay.setValue(80)
        source.cutoff.setValue(30)
        source.resonance.setValue(60)
        
        let dest = MiniWorksProgram()
        dest.programName = "Punchy Bass"
        dest.vcfEnvelopeAttack.setValue(0)
        dest.vcfEnvelopeDecay.setValue(40)
        dest.cutoff.setValue(100)
        dest.resonance.setValue(90)
        
        _morph = State(initialValue: ProgramMorph(source: source, destination: dest))
    }
    
    var body: some View {
        VStack {
            AdvancedMorphView(morph: morph)
            
            Divider()
            
            // Custom controls
            HStack {
                Button("Ping Pong") {
                    pingPongMorph()
                }
                
                Button("Randomize") {
                    randomMorph()
                }
            }
            .padding()
        }
    }
    
    // Morph to destination then back to source
    func pingPongMorph() {
        morph.startMorph(to: 1.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + morph.morphDuration + 0.5) {
            self.morph.startMorph(to: 0.0)
        }
    }
    
    // Set random morph position
    func randomMorph() {
        let randomPosition = Double.random(in: 0...1)
        morph.setMorphPosition(randomPosition)
    }
}

// MARK: - Example 5: Morph Preset System

struct MorphPreset: Identifiable {
    let id = UUID()
    let name: String
    let sourceProgram: MiniWorksProgram
    let destinationProgram: MiniWorksProgram
    let duration: Double
    let description: String
}

class MorphPresetManager: ObservableObject {
    @Published var presets: [MorphPreset] = []
    
    init() {
        loadDefaultPresets()
    }
    
    func loadDefaultPresets() {
        // Create some interesting morph presets
        
        // 1. Filter sweep
        let filterSource = MiniWorksProgram()
        filterSource.cutoff.setValue(10)
        let filterDest = MiniWorksProgram()
        filterDest.cutoff.setValue(127)
        
        presets.append(MorphPreset(
            name: "Filter Sweep",
            sourceProgram: filterSource,
            destinationProgram: filterDest,
            duration: 4.0,
            description: "Smooth filter opening over 4 seconds"
        ))
        
        // 2. Resonance dance
        let resSource = MiniWorksProgram()
        resSource.resonance.setValue(0)
        let resDest = MiniWorksProgram()
        resDest.resonance.setValue(100)
        
        presets.append(MorphPreset(
            name: "Resonance Dance",
            sourceProgram: resSource,
            destinationProgram: resDest,
            duration: 2.0,
            description: "Quick resonance increase"
        ))
        
        // 3. Envelope transformation
        let envSource = MiniWorksProgram()
        envSource.vcfEnvelopeAttack.setValue(127)
        envSource.vcfEnvelopeDecay.setValue(0)
        let envDest = MiniWorksProgram()
        envDest.vcfEnvelopeAttack.setValue(0)
        envDest.vcfEnvelopeDecay.setValue(127)
        
        presets.append(MorphPreset(
            name: "Attack to Decay",
            sourceProgram: envSource,
            destinationProgram: envDest,
            duration: 3.0,
            description: "Transform from slow attack to fast decay"
        ))
    }
    
    func createMorph(from preset: MorphPreset) -> ProgramMorph {
        let morph = ProgramMorph(
            source: preset.sourceProgram,
            destination: preset.destinationProgram
        )
        morph.morphDuration = preset.duration
        return morph
    }
}

struct MorphPresetView: View {
    @StateObject private var presetManager = MorphPresetManager()
    @State private var selectedPreset: MorphPreset?
    @State private var currentMorph: ProgramMorph?
    
    var body: some View {
        VStack {
            List(presetManager.presets) { preset in
                Button {
                    selectedPreset = preset
                    currentMorph = presetManager.createMorph(from: preset)
                } label: {
                    VStack(alignment: .leading) {
                        Text(preset.name)
                            .font(.headline)
                        Text(preset.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let morph = currentMorph {
                Divider()
                MorphControlView(morph: morph)
                    .frame(height: 300)
            }
        }
    }
}

// MARK: - Example 6: Real-time Performance Control

struct PerformanceMorphView: View {
    @State private var morph: ProgramMorph
    @State private var automationPath: [Double] = []
    @State private var isRecording = false
    
    init() {
        let source = MiniWorksProgram()
        let dest = MiniWorksProgram()
        dest.cutoff.setValue(127)
        
        _morph = State(initialValue: ProgramMorph(source: source, destination: dest))
    }
    
    var body: some View {
        VStack {
            // X/Y pad for morph control
            GeometryReader { geometry in
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Draw automation path
                    if !automationPath.isEmpty {
                        Path { path in
                            for (index, position) in automationPath.enumerated() {
                                let x = geometry.size.width * position
                                let y = geometry.size.height * 0.5
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    }
                    
                    // Current position indicator
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .position(
                            x: geometry.size.width * morph.morphPosition,
                            y: geometry.size.height * 0.5
                        )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let position = min(max(0, value.location.x / geometry.size.width), 1)
                            morph.setMorphPosition(position)
                            
                            if isRecording {
                                automationPath.append(position)
                            }
                        }
                )
            }
            .frame(height: 200)
            .cornerRadius(12)
            
            // Controls
            HStack {
                Button {
                    isRecording.toggle()
                    if !isRecording {
                        // Stopped recording
                    } else {
                        automationPath.removeAll()
                    }
                } label: {
                    Label(
                        isRecording ? "Stop Recording" : "Record",
                        systemImage: isRecording ? "stop.circle.fill" : "record.circle"
                    )
                }
                .buttonStyle(.bordered)
                
                Button("Clear") {
                    automationPath.removeAll()
                }
                .buttonStyle(.bordered)
                
                Button("Playback") {
                    playbackAutomation()
                }
                .buttonStyle(.bordered)
                .disabled(automationPath.isEmpty)
            }
            .padding()
        }
        .padding()
    }
    
    func playbackAutomation() {
        guard !automationPath.isEmpty else { return }
        
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard index < automationPath.count else {
                timer.invalidate()
                return
            }
            
            morph.setMorphPosition(automationPath[index])
            index += 1
        }
    }
}

// MARK: - Preview

#Preview("Basic") {
    BasicMorphExample()
        .frame(width: 500, height: 600)
}

#Preview("Advanced") {
    AdvancedMorphExample()
        .frame(width: 700, height: 800)
}

#Preview("Presets") {
    MorphPresetView()
        .frame(width: 600, height: 700)
}

#Preview("Performance") {
    PerformanceMorphView()
        .frame(width: 500, height: 400)
}
