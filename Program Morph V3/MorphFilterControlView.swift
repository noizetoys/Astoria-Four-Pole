//
//  MorphFilterControlView.swift
//  Astoria Filter Editor
//
//  UI for controlling which parameters are morphed
//

import SwiftUI

struct MorphFilterControlView: View {
    @Bindable var morph: ProgramMorphFiltered
    
    @State private var showAdvancedSettings = false
    @State private var showParameterList = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Quick presets
                    presetsSection
                    
                    // Group selection
                    groupSelectionSection
                    
                    // Discrete parameter handling
                    discreteParameterSection
                    
                    // Advanced settings
                    if showAdvancedSettings {
                        advancedSettingsSection
                    }
                    
                    // Parameter list
                    if showParameterList {
                        parameterListSection
                    }
                    
                    // Statistics
                    statisticsSection
                }
                .padding()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Morph Filter Control")
                    .font(.title2.bold())
                Text("Select which parameters to morph")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    showParameterList.toggle()
                } label: {
                    Label("Parameters", systemImage: "list.bullet")
                }
                .buttonStyle(.bordered)
                
                Button {
                    showAdvancedSettings.toggle()
                } label: {
                    Label("Advanced", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Presets Section
    
    private var presetsSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                Text("Quick Presets")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    PresetButton(
                        title: "All Parameters",
                        icon: "circle.grid.3x3.fill",
                        isActive: morph.filterConfig.enabledGroups.count == ParameterGroup.allCases.count
                    ) {
                        morph.filterConfig = .allParameters
                    }
                    
                    PresetButton(
                        title: "Envelopes Only",
                        icon: "waveform.path.ecg",
                        isActive: morph.filterConfig.envelopesOnly
                    ) {
                        morph.filterConfig = .envelopesOnly
                    }
                    
                    PresetButton(
                        title: "Filters Only",
                        icon: "equalizer",
                        isActive: morph.filterConfig.filtersOnly
                    ) {
                        morph.filterConfig = .filtersOnly
                    }
                    
                    PresetButton(
                        title: "VCF Only",
                        icon: "slider.horizontal.3",
                        isActive: morph.filterConfig.enabledGroups == [.vcfEnvelope, .filters, .vcfModulation]
                    ) {
                        morph.filterConfig = .vcfOnly
                    }
                    
                    PresetButton(
                        title: "VCA Only",
                        icon: "speaker.wave.2",
                        isActive: morph.filterConfig.enabledGroups == [.vcaEnvelope, .output, .vcaModulation]
                    ) {
                        morph.filterConfig = .vcaOnly
                    }
                    
                    PresetButton(
                        title: "Modulation Only",
                        icon: "waveform",
                        isActive: morph.filterConfig.enabledGroups == [.vcfModulation, .vcaModulation, .lfo]
                    ) {
                        morph.filterConfig = .modulationOnly
                    }
                }
            }
            .padding(4)
        }
    }
    
    // MARK: - Group Selection
    
    private var groupSelectionSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                HStack {
                    Text("Parameter Groups")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(morph.filterConfig.enabledGroups.count)/\(ParameterGroup.allCases.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(ParameterGroup.allCases) { group in
                        GroupToggleButton(
                            group: group,
                            isEnabled: morph.filterConfig.enabledGroups.contains(group)
                        ) {
                            morph.toggleGroup(group)
                        }
                    }
                }
            }
            .padding(4)
        }
    }
    
    // MARK: - Discrete Parameter Section
    
    private var discreteParameterSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                Text("Discrete Parameters")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("How should discrete parameters (enums) be handled?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Strategy", selection: $morph.filterConfig.modulationSourceStrategy) {
                        ForEach(DiscreteParameterStrategy.allCases) { strategy in
                            Text(strategy.rawValue).tag(strategy)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if morph.filterConfig.modulationSourceStrategy == .snapAtThreshold {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Snap Threshold")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.0f%%", morph.filterConfig.discreteSnapThreshold * 100))
                                    .font(.subheadline.monospacedDigit())
                            }
                            
                            Slider(
                                value: $morph.filterConfig.discreteSnapThreshold,
                                in: 0...1,
                                step: 0.05
                            )
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    Text("Include Discrete Parameters:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Toggle("LFO Shape", isOn: $morph.filterConfig.includeLFOShape)
                    Toggle("Trigger Source", isOn: $morph.filterConfig.includeTriggerSource)
                    Toggle("Trigger Mode", isOn: $morph.filterConfig.includeTriggerMode)
                }
            }
            .padding(4)
        }
    }
    
    // MARK: - Advanced Settings
    
    private var advancedSettingsSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                Text("Advanced Settings")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Disabled Parameters")
                            .font(.subheadline)
                        Spacer()
                        Text("\(morph.filterConfig.disabledParameters.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    if !morph.filterConfig.disabledParameters.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(morph.filterConfig.disabledParameters), id: \.self) { param in
                                    Chip(text: param.rawValue) {
                                        morph.filterConfig.disabledParameters.remove(param)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Force Enabled Parameters")
                            .font(.subheadline)
                        Spacer()
                        Text("\(morph.filterConfig.forceEnabledParameters.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    if !morph.filterConfig.forceEnabledParameters.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(morph.filterConfig.forceEnabledParameters), id: \.self) { param in
                                    Chip(text: param.rawValue) {
                                        morph.filterConfig.forceEnabledParameters.remove(param)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button("Reset All Overrides") {
                        morph.filterConfig.disabledParameters.removeAll()
                        morph.filterConfig.forceEnabledParameters.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(4)
        }
    }
    
    // MARK: - Parameter List
    
    private var parameterListSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                Text("Parameter Status")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(morph.morphingParameterNames, id: \.self) { name in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                
                                Text(name)
                                    .font(.caption)
                                
                                Spacer()
                                
                                if morph.changingParameterNames.contains(name) {
                                    Text("Changing")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            .padding(4)
        }
    }
    
    // MARK: - Statistics
    
    private var statisticsSection: some View {
        GroupBox {
            VStack(spacing: 8) {
                Text("Morph Statistics")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Total Parameters:")
                            .foregroundStyle(.secondary)
                        Text("\(morph.stats.totalParameters)")
                            .bold()
                    }
                    
                    GridRow {
                        Text("Continuous:")
                            .foregroundStyle(.secondary)
                        Text("\(morph.stats.continuousParameters)")
                    }
                    
                    GridRow {
                        Text("Discrete:")
                            .foregroundStyle(.secondary)
                        Text("\(morph.stats.discreteParameters)")
                    }
                    
                    GridRow {
                        Text("Unchanged:")
                            .foregroundStyle(.secondary)
                        Text("\(morph.stats.unchangedParameters)")
                            .foregroundStyle(.orange)
                    }
                    
                    if morph.stats.messagesSent > 0 {
                        Divider()
                        
                        GridRow {
                            Text("Messages Sent:")
                                .foregroundStyle(.secondary)
                            Text("\(morph.stats.messagesSent)")
                                .foregroundStyle(.green)
                        }
                        
                        GridRow {
                            Text("Messages Saved:")
                                .foregroundStyle(.secondary)
                            Text("\(morph.stats.messagesSaved)")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(4)
        }
    }
}

// MARK: - Supporting Views

struct PresetButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isActive ? .white : .primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(isActive ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct GroupToggleButton: View {
    let group: ParameterGroup
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: group.icon)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.rawValue)
                        .font(.subheadline.bold())
                    
                    Text(group.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isEnabled ? .green : .secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? Color.green.opacity(0.1) : Color.secondary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct Chip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Full Morph View with Filter Control

struct CompleteMorphView: View {
    @State var morph: ProgramMorphFiltered
    
    var body: some View {
        VStack(spacing: 0) {
            // Main morph controls
            MorphControlSection(morph: morph)
                .padding()
            
            Divider()
            
            // Filter configuration
            MorphFilterControlView(morph: morph)
        }
    }
}

struct MorphControlSection: View {
    @Bindable var morph: ProgramMorphFiltered
    
    var body: some View {
        VStack(spacing: 16) {
            // Program labels
            HStack {
                VStack(alignment: .leading) {
                    Text("SOURCE")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(morph.sourceProgram.programName)
                        .font(.headline)
                }
                
                Spacer()
                
                Button {
                    morph.swapPrograms()
                } label: {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.title2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("DESTINATION")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(morph.destinationProgram.programName)
                        .font(.headline)
                }
            }
            
            // Morph slider
            VStack(spacing: 8) {
                HStack {
                    Text("Position")
                    Spacer()
                    Text(String(format: "%.0f%%", morph.morphPosition * 100))
                        .monospacedDigit()
                }
                .font(.subheadline)
                
                Slider(value: Binding(
                    get: { morph.morphPosition },
                    set: { morph.setMorphPosition($0) }
                ))
                .disabled(morph.isAutoMorphing)
            }
            
            // Control buttons
            HStack(spacing: 12) {
                Button("Reset") {
                    morph.resetToSource()
                }
                .buttonStyle(.bordered)
                .disabled(morph.isAutoMorphing)
                
                Spacer()
                
                Button(morph.isAutoMorphing ? "Stop" : "Morph") {
                    if morph.isAutoMorphing {
                        morph.stopMorph()
                    } else {
                        morph.startMorph()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(morph.isAutoMorphing ? .red : .accentColor)
                
                Spacer()
                
                Button("Jump") {
                    morph.jumpToDestination()
                }
                .buttonStyle(.bordered)
                .disabled(morph.isAutoMorphing)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CompleteMorphView(
        morph: ProgramMorphFiltered(
            source: MiniWorksProgram(),
            destination: MiniWorksProgram()
        )
    )
    .frame(width: 800, height: 900)
}
