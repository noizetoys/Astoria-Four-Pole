//
//  MorphControlView.swift
//  Astoria Filter Editor
//
//  Created for morphing UI between MiniWorks programs
//

import SwiftUI

struct MorphControlView: View {
    @State var morph: ProgramMorph
    
    @State private var customDuration: Double = 2.0
    @State private var customUpdateRate: Double = 30.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Program labels
            programLabelsView
            
            // Main morph slider
            morphSliderView
            
            // Control buttons
            controlButtonsView
            
            // Settings
            settingsView
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Subviews
    
    private var programLabelsView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Source")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(morph.sourceProgram.programName)
                    .font(.headline)
            }
            
            Spacer()
            
            Button {
                morph.swapPrograms()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Destination")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(morph.destinationProgram.programName)
                    .font(.headline)
            }
        }
        .padding(.horizontal)
    }
    
    private var morphSliderView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Morph Position")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.0f%%", morph.morphPosition * 100))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)
                
                // Progress fill
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * morph.morphPosition, height: 8)
                }
                .frame(height: 8)
            }
            .frame(height: 8)
            
            // Interactive slider
            Slider(
                value: Binding(
                    get: { morph.morphPosition },
                    set: { morph.setMorphPosition($0, sendCC: !morph.isAutoMorphing) }
                ),
                in: 0...1
            )
            .disabled(morph.isAutoMorphing)
        }
        .padding(.horizontal)
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: 12) {
            // Reset to source
            Button {
                morph.resetToSource()
            } label: {
                Label("Source", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            .disabled(morph.isAutoMorphing)
            
            Spacer()
            
            // Morph button
            if morph.isAutoMorphing {
                Button {
                    morph.stopMorph()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button {
                    morph.startMorph()
                } label: {
                    Label("Morph", systemImage: "waveform.path")
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
            
            // Jump to destination
            Button {
                morph.jumpToDestination()
            } label: {
                Label("Destination", systemImage: "arrow.uturn.forward")
            }
            .buttonStyle(.bordered)
            .disabled(morph.isAutoMorphing)
        }
        .padding(.horizontal)
    }
    
    private var settingsView: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Duration setting
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Duration")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1fs", customDuration))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $customDuration, in: 0.5...10.0, step: 0.5)
                        .onChange(of: customDuration) { _, newValue in
                            morph.morphDuration = newValue
                        }
                }
                
                // Update rate setting
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Update Rate")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.0f Hz", customUpdateRate))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $customUpdateRate, in: 10...60, step: 5)
                        .onChange(of: customUpdateRate) { _, newValue in
                            morph.updateRate = newValue
                        }
                }
                
                // Send CC toggle
                Toggle("Send CC Messages", isOn: $morph.sendCCMessages)
                    .font(.subheadline)
            }
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    MorphControlView(
        morph: ProgramMorph(
            source: MiniWorksProgram(),
            destination: MiniWorksProgram()
        )
    )
    .frame(width: 500, height: 600)
}
