//
//  ProgramEditorView.swift
//  MiniWorksMIDI
//
//  Main program editor interface with parameter knobs, ADSR visualizations,
//  and preset management. Supports live parameter updates with debouncing
//  to prevent MIDI flooding during continuous knob adjustments.
//
//  Layout:
//  - Top: Preset controls and live update toggle
//  - Main: Parameter sections (Oscillators, Filter, Amplifier, Modulation)
//  - Bottom: VCF and VCA envelope editors
//

import SwiftUI
import Combine


struct ProgramEditorView: View {
    @EnvironmentObject var midiManager: MIDIManager
    @StateObject private var program = ProgramModel()
    @StateObject private var presetStore = PresetStore()
    @StateObject private var debouncer = Debouncer()
    
    @State private var liveUpdate = false
    @State private var selectedPreset: PresetStore.PresetInfo?
    @State private var showingSaveSheet = false
    @State private var showingExportSheet = false
    @State private var newPresetName = ""
    @State private var statusMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header: Preset management
                presetControls
                
                // Parameter sections
                VStack(spacing: 20) {
                    oscillatorSection
                    filterSection
                    amplifierSection
                    modulationSection
                }
                .padding()
                
                // ADSR Envelopes
                HStack(spacing: 20) {
                    ADSRView(
                        title: "VCF Envelope",
                        attack: $program.vcfAttack,
                        decay: $program.vcfDecay,
                        sustain: $program.vcfSustain,
                        release: $program.vcfRelease,
                        onChange: { _ in sendIfLive() }
                    )
                    
                    ADSRView(
                        title: "VCA Envelope",
                        attack: $program.vcaAttack,
                        decay: $program.vcaDecay,
                        sustain: $program.vcaSustain,
                        release: $program.vcaRelease,
                        onChange: { _ in sendIfLive() }
                    )
                }
                .padding()
                
                // Status message
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding()
                }
            }
        }
        .navigationTitle("Program Editor")
        .sheet(isPresented: $showingSaveSheet) {
            savePresetSheet
        }
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
        }
    }
    
    // MARK: - Preset Controls
    
    private var presetControls: some View {
        VStack(spacing: 12) {
            HStack {
                // Preset picker
                Menu {
                    ForEach(presetStore.presets) { preset in
                        Button(preset.name) {
                            loadPreset(preset)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedPreset?.name ?? "Select Preset")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Save preset
                Button(action: { showingSaveSheet = true }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                
                // Export .syx
                Button(action: { showingExportSheet = true }) {
                    Label("Export", systemImage: "doc.badge.arrow.up")
                }
                
                Spacer()
                
                // Live update toggle
                Toggle("Live Update", isOn: $liveUpdate)
                    .toggleStyle(.switch)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Request buttons
            HStack {
                Button("Request Program Dump") {
                    midiManager.requestProgramDump(programNumber: 0)
                }
                
                Button("Request All Dump") {
                    midiManager.requestAllDump()
                }
                
                Button("Send to Hardware") {
                    sendProgram()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // MARK: - Parameter Sections
    
    private var oscillatorSection: some View {
        GroupBox("Oscillators") {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    KnobView(label: "OSC1 Pitch", value: $program.osc1Pitch, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "OSC1 Fine", value: $program.osc1Fine, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "OSC2 Pitch", value: $program.osc2Pitch, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "OSC2 Fine", value: $program.osc2Fine, range: 0...127, onChange: { _ in sendIfLive() })
                }
                
                HStack(spacing: 20) {
                    KnobView(label: "OSC2 Detune", value: $program.osc2Detune, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "Mix", value: $program.oscMix, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "PWM", value: $program.pwm, range: 0...127, onChange: { _ in sendIfLive() })
                    
                    VStack {
                        Text("PWM Src")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("PWM Source", selection: $program.pwmSource) {
                            ForEach(ModSource.allCases) { source in
                                Text(source.displayName).tag(source)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: program.pwmSource) { _ in sendIfLive() }
                    }
                }
            }
            .padding()
        }
    }
    
    private var filterSection: some View {
        GroupBox("Filter (VCF)") {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    KnobView(label: "Cutoff", value: $program.cutoff, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "Resonance", value: $program.resonance, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "Env Amount", value: $program.vcfEnvAmount, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "Keytrack", value: $program.vcfKeytrack, range: 0...127, onChange: { _ in sendIfLive() })
                }
                
                HStack(spacing: 20) {
                    KnobView(label: "Mod Amount", value: $program.vcfModAmount, range: 0...127, onChange: { _ in sendIfLive() })
                    
                    VStack {
                        Text("Mod Source")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("VCF Mod Source", selection: $program.vcfModSource) {
                            ForEach(ModSource.allCases) { source in
                                Text(source.displayName).tag(source)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: program.vcfModSource) { _ in sendIfLive() }
                    }
                }
            }
            .padding()
        }
    }
    
    private var amplifierSection: some View {
        GroupBox("Amplifier (VCA)") {
            HStack(spacing: 20) {
                KnobView(label: "Volume", value: $program.volume, range: 0...127, onChange: { _ in sendIfLive() })
                KnobView(label: "Mod Amount", value: $program.vcaModAmount, range: 0...127, onChange: { _ in sendIfLive() })
                
                VStack {
                    Text("Mod Source")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("VCA Mod Source", selection: $program.vcaModSource) {
                        ForEach(ModSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: program.vcaModSource) { _ in sendIfLive() }
                }
            }
            .padding()
        }
    }
    
    private var modulationSection: some View {
        GroupBox("Modulation") {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    KnobView(label: "LFO1 Rate", value: $program.lfo1Rate, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "LFO1 Amount", value: $program.lfo1Amount, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "LFO2 Rate", value: $program.lfo2Rate, range: 0...127, onChange: { _ in sendIfLive() })
                    KnobView(label: "LFO2 Amount", value: $program.lfo2Amount, range: 0...127, onChange: { _ in sendIfLive() })
                }
                
                HStack(spacing: 20) {
                    KnobView(label: "Pitch Mod", value: $program.pitchModAmount, range: 0...127, onChange: { _ in sendIfLive() })
                    
                    VStack {
                        Text("Pitch Mod Src")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Pitch Mod Source", selection: $program.pitchModSource) {
                            ForEach(ModSource.allCases) { source in
                                Text(source.displayName).tag(source)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: program.pitchModSource) { _ in sendIfLive() }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Sheets
    
    private var savePresetSheet: some View {
        VStack(spacing: 20) {
            Text("Save Preset")
                .font(.headline)
            
            TextField("Preset Name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            HStack {
                Button("Cancel") {
                    showingSaveSheet = false
                    newPresetName = ""
                }
                
                Button("Save") {
                    do {
                        try presetStore.savePreset(program, name: newPresetName)
                        statusMessage = "Preset saved: \(newPresetName)"
                        showingSaveSheet = false
                        newPresetName = ""
                    } catch {
                        statusMessage = "Save failed: \(error.localizedDescription)"
                    }
                }
                .disabled(newPresetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    private var exportSheet: some View {
        VStack(spacing: 20) {
            Text("Export All Dump")
                .font(.headline)
            
            Text("Export all programs as a .syx file")
                .font(.caption)
            
            Button("Export") {
                #if os(macOS)
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.init(filenameExtension: "syx")!]
                panel.nameFieldStringValue = "MiniWorks_AllDump.syx"
                
                if panel.runModal() == .OK, let url = panel.url {
                    do {
                        try presetStore.exportAllDumpSysEx(program, to: url, checksumMode: midiManager.checksumMode)
                        statusMessage = "Exported to \(url.lastPathComponent)"
                        showingExportSheet = false
                    } catch {
                        statusMessage = "Export failed: \(error.localizedDescription)"
                    }
                }
                #else
                statusMessage = "Export not available on iOS"
                showingExportSheet = false
                #endif
            }
            
            Button("Cancel") {
                showingExportSheet = false
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    // MARK: - Actions
    
    private func sendIfLive() {
        guard liveUpdate else { return }
        debouncer.submit {
            sendProgram()
        }
    }
    
    private func sendProgram() {
        let sysex = program.toProgramDumpSysEx(programNumber: 0, checksumMode: midiManager.checksumMode)
        midiManager.sendSysEx(sysex)
        statusMessage = "Program sent to hardware"
    }
    
    private func loadPreset(_ preset: PresetStore.PresetInfo) {
        do {
            let loaded = try presetStore.loadPreset(preset)
            
            // Copy all parameters from loaded preset to current program
            program.osc1Pitch = loaded.osc1Pitch
            program.osc1Fine = loaded.osc1Fine
            program.osc2Pitch = loaded.osc2Pitch
            program.osc2Fine = loaded.osc2Fine
            program.osc2Detune = loaded.osc2Detune
            program.oscMix = loaded.oscMix
            program.pwm = loaded.pwm
            program.pwmSource = loaded.pwmSource
            
            program.cutoff = loaded.cutoff
            program.resonance = loaded.resonance
            program.vcfEnvAmount = loaded.vcfEnvAmount
            program.vcfKeytrack = loaded.vcfKeytrack
            program.vcfModAmount = loaded.vcfModAmount
            program.vcfModSource = loaded.vcfModSource
            
            program.vcfAttack = loaded.vcfAttack
            program.vcfDecay = loaded.vcfDecay
            program.vcfSustain = loaded.vcfSustain
            program.vcfRelease = loaded.vcfRelease
            
            program.volume = loaded.volume
            program.vcaModAmount = loaded.vcaModAmount
            program.vcaModSource = loaded.vcaModSource
            
            program.vcaAttack = loaded.vcaAttack
            program.vcaDecay = loaded.vcaDecay
            program.vcaSustain = loaded.vcaSustain
            program.vcaRelease = loaded.vcaRelease
            
            program.lfo1Rate = loaded.lfo1Rate
            program.lfo1Amount = loaded.lfo1Amount
            program.lfo2Rate = loaded.lfo2Rate
            program.lfo2Amount = loaded.lfo2Amount
            
            program.pitchModSource = loaded.pitchModSource
            program.pitchModAmount = loaded.pitchModAmount
            
            selectedPreset = preset
            statusMessage = "Loaded preset: \(preset.name)"
        } catch {
            statusMessage = "Load failed: \(error.localizedDescription)"
        }
    }
}
