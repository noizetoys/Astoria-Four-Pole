//
//  AdvancedMorphView.swift
//  Astoria Filter Editor
//
//  Advanced morphing UI with parameter visualization
//

import SwiftUI

struct AdvancedMorphView: View {
    @State var morph: ProgramMorph
    
    @State private var showParameterDetails = false
    @State private var selectedCurve: MorphCurve = .easeInOut
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
            
            Divider()
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Morph control
                    morphControlSection
                    
                    // Curve selection
                    curveSelectionSection
                    
                    // Parameter visualization
                    if showParameterDetails {
                        parameterVisualizationSection
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Program Morph")
                    .font(.title2.bold())
                Text("Smoothly transition between patches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                showParameterDetails.toggle()
            } label: {
                Label(
                    showParameterDetails ? "Hide Details" : "Show Details",
                    systemImage: showParameterDetails ? "chevron.up" : "chevron.down"
                )
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Morph Control Section
    
    private var morphControlSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Program labels with swap
                HStack {
                    programLabel(morph.sourceProgram, isSource: true)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            morph.swapPrograms()
                        }
                    } label: {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.title2)
                            .symbolEffect(.bounce, value: morph.sourceProgram.id)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    programLabel(morph.destinationProgram, isSource: false)
                }
                
                Divider()
                
                // Visual morph slider with markers
                VStack(spacing: 12) {
                    // Position display
                    HStack {
                        Text("Position")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(String(format: "%.0f%%", morph.morphPosition * 100))
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(
                                morph.morphPosition < 0.5 ? .blue : .purple
                            )
                    }
                    
                    // Custom slider with gradient
                    MorphSlider(position: Binding(
                        get: { morph.morphPosition },
                        set: { morph.setMorphPosition($0, sendCC: !morph.isAutoMorphing) }
                    ))
                    .frame(height: 40)
                    .disabled(morph.isAutoMorphing)
                }
                
                Divider()
                
                // Control buttons
                HStack(spacing: 16) {
                    MorphButton(
                        title: "Source",
                        icon: "arrow.backward.to.line",
                        action: { morph.resetToSource() },
                        isDisabled: morph.isAutoMorphing || morph.morphPosition == 0
                    )
                    
                    MorphButton(
                        title: "Morph",
                        icon: morph.isAutoMorphing ? "stop.fill" : "play.fill",
                        action: {
                            if morph.isAutoMorphing {
                                morph.stopMorph()
                            } else {
                                morph.startMorph()
                            }
                        },
                        isPrimary: true,
                        isActive: morph.isAutoMorphing
                    )
                    
                    MorphButton(
                        title: "Destination",
                        icon: "arrow.forward.to.line",
                        action: { morph.jumpToDestination() },
                        isDisabled: morph.isAutoMorphing || morph.morphPosition == 1
                    )
                }
                
                // Settings
                Divider()
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Slider(value: $morph.morphDuration, in: 0.5...10.0, step: 0.5)
                            Text(String(format: "%.1fs", morph.morphDuration))
                                .font(.caption.monospacedDigit())
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Update Rate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Slider(value: $morph.updateRate, in: 10...60, step: 5)
                            Text(String(format: "%.0f Hz", morph.updateRate))
                                .font(.caption.monospacedDigit())
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(4)
        }
    }
    
    // MARK: - Curve Selection Section
    
    private var curveSelectionSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("Morph Curve")
                        .font(.subheadline.bold())
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ForEach(MorphCurve.allCases, id: \.self) { curve in
                        Button {
                            selectedCurve = curve
                        } label: {
                            VStack(spacing: 4) {
                                curve.icon
                                    .font(.title3)
                                Text(curve.name)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedCurve == curve ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedCurve == curve ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(4)
        }
    }
    
    // MARK: - Parameter Visualization
    
    private var parameterVisualizationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parameter Changes")
                    .font(.subheadline.bold())
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(morph.sourceProgram.allParameters, id: \.id) { sourceParam in
                            if let destParam = morph.destinationProgram.allParameters.first(where: { $0.type == sourceParam.type }) {
                                ParameterMorphRow(
                                    parameter: sourceParam,
                                    sourceValue: sourceParam.value,
                                    destValue: destParam.value,
                                    morphPosition: morph.morphPosition
                                )
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            .padding(4)
        }
    }
    
    // MARK: - Helper Views
    
    private func programLabel(_ program: MiniWorksProgram, isSource: Bool) -> some View {
        VStack(alignment: isSource ? .leading : .trailing, spacing: 4) {
            Text(isSource ? "SOURCE" : "DESTINATION")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            
            Text(program.programName)
                .font(.headline)
            
            Text("Program \(program.programNumber)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: isSource ? .leading : .trailing)
    }
}

// MARK: - Supporting Views

struct MorphSlider: View {
    @Binding var position: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondary.opacity(0.1))
                
                // Gradient fill
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * position)
                
                // Thumb
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .frame(width: 32, height: 32)
                    .offset(x: (geometry.size.width - 32) * position)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newPosition = min(max(0, value.location.x / geometry.size.width), 1)
                                position = newPosition
                            }
                    )
            }
        }
    }
}

struct MorphButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var isPrimary: Bool = false
    var isActive: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(buttonColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
    
    private var buttonColor: Color {
        if isActive {
            return .red.opacity(0.2)
        } else if isPrimary {
            return .accentColor.opacity(0.2)
        } else {
            return .secondary.opacity(0.1)
        }
    }
}

struct ParameterMorphRow: View {
    let parameter: ProgramParameter
    let sourceValue: UInt8
    let destValue: UInt8
    let morphPosition: Double
    
    private var currentValue: UInt8 {
        let delta = Double(destValue) - Double(sourceValue)
        let interpolated = Double(sourceValue) + (delta * morphPosition)
        return UInt8(max(0, min(127, interpolated.rounded())))
    }
    
    private var hasChanged: Bool {
        sourceValue != destValue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Parameter name
            Text(parameter.name)
                .font(.caption)
                .frame(width: 120, alignment: .leading)
                .opacity(hasChanged ? 1 : 0.5)
            
            // Value bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                    
                    // Source marker
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2)
                        .offset(x: CGFloat(sourceValue) / 127 * geometry.size.width)
                    
                    // Dest marker
                    Rectangle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 2)
                        .offset(x: CGFloat(destValue) / 127 * geometry.size.width)
                    
                    // Current position
                    if hasChanged {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .offset(x: CGFloat(currentValue) / 127 * geometry.size.width - 4)
                    }
                }
            }
            .frame(height: 20)
            
            // Values
            HStack(spacing: 4) {
                Text("\(sourceValue)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.blue)
                    .frame(width: 30, alignment: .trailing)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("\(destValue)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.purple)
                    .frame(width: 30, alignment: .leading)
            }
            .opacity(hasChanged ? 1 : 0.3)
        }
        .padding(.vertical, 4)
        .background(
            hasChanged ? Color.accentColor.opacity(0.05) : Color.clear
        )
        .cornerRadius(4)
    }
}

// MARK: - Morph Curve Options

enum MorphCurve: String, CaseIterable {
    case linear = "Linear"
    case easeIn = "Ease In"
    case easeOut = "Ease Out"
    case easeInOut = "Ease In-Out"
    
    var name: String { rawValue }
    
    var icon: Image {
        switch self {
        case .linear:
            return Image(systemName: "line.diagonal")
        case .easeIn:
            return Image(systemName: "arrow.up.right")
        case .easeOut:
            return Image(systemName: "arrow.down.right")
        case .easeInOut:
            return Image(systemName: "arrow.up.and.down")
        }
    }
}

// MARK: - Preview

#Preview("Basic") {
    MorphControlView(
        morph: ProgramMorph(
            source: MiniWorksProgram(),
            destination: MiniWorksProgram()
        )
    )
    .frame(width: 500, height: 600)
}

#Preview("Advanced") {
    AdvancedMorphView(
        morph: ProgramMorph(
            source: MiniWorksProgram(),
            destination: MiniWorksProgram()
        )
    )
    .frame(width: 700, height: 800)
}
