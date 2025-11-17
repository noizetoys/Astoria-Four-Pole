//
//  ParameterView.swift
//  Virtual Waldorf 4 Pole Filter
//

import SwiftUI

struct ParameterView: View {
    @ObservedObject var deviceState: VirtualDeviceState
    
    var body: some View {
        GroupBox(label: Label("Parameters", systemImage: "slider.horizontal.3")) {
            ScrollView {
                VStack(spacing: 16) {
                    // VCF Envelope
                    ParameterSection(title: "VCF Envelope") {
                        ParameterRow(
                            label: "Attack",
                            parameter: .VCFEnvelopeAttack,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Decay",
                            parameter: .VCFEnvelopeDecay,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Sustain",
                            parameter: .VCFEnvelopeSustain,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Release",
                            parameter: .VCFEnvelopeRelease,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Cutoff Amount",
                            parameter: .VCFEnvelopeCutoffAmount,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                    }
                    
                    // VCA Envelope
                    ParameterSection(title: "VCA Envelope") {
                        ParameterRow(
                            label: "Attack",
                            parameter: .VCAEnvelopeAttack,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Decay",
                            parameter: .VCAEnvelopeDecay,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Sustain",
                            parameter: .VCAEnvelopeSustain,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Release",
                            parameter: .VCAEnvelopeRelease,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Volume Amount",
                            parameter: .VCAEnvelopeVolumeAmount,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                    }
                    
                    // LFO
                    ParameterSection(title: "LFO") {
                        ParameterRow(
                            label: "Speed",
                            parameter: .LFOSpeed,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Speed Mod Amount",
                            parameter: .LFOSpeedModulationAmount,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                        
                        ModSourcePicker(
                            label: "Shape",
                            parameter: .LFOShape,
                            deviceState: deviceState,
                            options: [
                                (1, "Sine"),
                                (2, "Triangle"),
                                (3, "Sawtooth"),
                                (4, "Pulse")
                            ]
                        )
                        
                        ModSourcePicker(
                            label: "Speed Mod Source",
                            parameter: .LFOSpeedModulationSource,
                            deviceState: deviceState
                        )
                    }
                    
                    // Filter
                    ParameterSection(title: "Filter") {
                        ParameterRow(
                            label: "Cutoff",
                            parameter: .cutoff,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Cutoff Mod Amount",
                            parameter: .cutoffModulationAmount,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                        ModSourcePicker(
                            label: "Cutoff Mod Source",
                            parameter: .cutoffModulationSource,
                            deviceState: deviceState
                        )
                        
                        ParameterRow(
                            label: "Resonance",
                            parameter: .resonance,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Resonance Mod Amount",
                            parameter: .resonanceModulationAmount,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                        ModSourcePicker(
                            label: "Resonance Mod Source",
                            parameter: .resonanceModulationSource,
                            deviceState: deviceState
                        )
                    }
                    
                    // Volume & Panning
                    ParameterSection(title: "Volume & Panning") {
                        ParameterRow(
                            label: "Volume",
                            parameter: .volume,
                            deviceState: deviceState
                        )
                        ParameterRow(
                            label: "Volume Mod Amount",
                            parameter: .volumeModulationAmount,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                        ModSourcePicker(
                            label: "Volume Mod Source",
                            parameter: .volumeModulationSource,
                            deviceState: deviceState
                        )
                        
                        ParameterRow(
                            label: "Panning",
                            parameter: .panning,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                        ParameterRow(
                            label: "Panning Mod Amount",
                            parameter: .panningModulationAmount,
                            deviceState: deviceState,
                            isBipolar: true
                        )
                        ModSourcePicker(
                            label: "Panning Mod Source",
                            parameter: .panningModulationSource,
                            deviceState: deviceState
                        )
                    }
                    
                    // Trigger
                    ParameterSection(title: "Trigger") {
                        ParameterRow(
                            label: "Gate Time",
                            parameter: .gateTime,
                            deviceState: deviceState
                        )
                        
                        ModSourcePicker(
                            label: "Trigger Source",
                            parameter: .triggerSource,
                            deviceState: deviceState,
                            options: [
                                (0, "Audio"),
                                (1, "MIDI"),
                                (2, "All")
                            ]
                        )
                        
                        ModSourcePicker(
                            label: "Trigger Mode",
                            parameter: .triggerMode,
                            deviceState: deviceState,
                            options: [
                                (0, "Multi"),
                                (1, "Single")
                            ]
                        )
                    }
                }
                .padding(8)
            }
        }
    }
}

struct ParameterSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .textCase(.uppercase)
            
            VStack(spacing: 6) {
                content
            }
        }
    }
}

struct ParameterRow: View {
    let label: String
    let parameter: MiniWorksParameter
    @ObservedObject var deviceState: VirtualDeviceState
    var isBipolar: Bool = false
    
    private var currentValue: Binding<Double> {
        Binding(
            get: {
                let program = deviceState.programs[deviceState.currentProgram]
                return Double(program[parameter])
            },
            set: { newValue in
                deviceState.updateParameter(parameter, value: UInt8(newValue))
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Slider(value: currentValue, in: 0...127, step: 1)
            
            Text(displayValue)
                .font(.caption)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    private var displayValue: String {
        let value = Int(currentValue.wrappedValue)
        if isBipolar {
            return "\(value - 64)"
        }
        return "\(value)"
    }
}

struct ModSourcePicker: View {
    let label: String
    let parameter: MiniWorksParameter
    @ObservedObject var deviceState: VirtualDeviceState
    var options: [(Int, String)]?
    
    private var currentValue: Binding<Int> {
        Binding(
            get: {
                let program = deviceState.programs[deviceState.currentProgram]
                return Int(program[parameter])
            },
            set: { newValue in
                deviceState.updateParameter(parameter, value: UInt8(newValue))
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Picker("", selection: currentValue) {
                if let opts = options {
                    ForEach(opts, id: \.0) { value, name in
                        Text(name).tag(value)
                    }
                } else {
                    ForEach(Array(ModulationSource.allCases.enumerated()), id: \.offset) { _, source in
                        Text(source.name).tag(Int(source.rawValue))
                    }
                }
            }
            .labelsHidden()
        }
    }
}

#Preview {
    ParameterView(deviceState: VirtualDeviceState())
        .padding()
        .frame(width: 400, height: 600)
}
