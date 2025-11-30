//
//  CCMappingView.swift
//  MiniWorksMIDI
//
//  MIDI CC (Continuous Controller) Mapping Interface
//
//  ═══════════════════════════════════════════════════════════════════════
//  WHAT IS MIDI CC?
//  ═══════════════════════════════════════════════════════════════════════
//  
//  MIDI CC messages are used to control continuous parameters on synthesizers
//  in real-time. Unlike SysEx (which sends complete program dumps), CC messages
//  send individual parameter changes as you twist knobs or move sliders.
//
//  A CC message is just 3 bytes:
//  - Status byte: 0xB0-0xBF (indicates "Control Change" on channels 1-16)
//  - Controller number: 0-127 (which parameter to change)
//  - Value: 0-127 (what value to set it to)
//
//  Example: To set the filter cutoff (CC# 74) to half-open (value 64) on
//  channel 1, you'd send: B0 4A 40 (in hex)
//
//  ═══════════════════════════════════════════════════════════════════════
//  WHY USE CC INSTEAD OF SYSEX?
//  ═══════════════════════════════════════════════════════════════════════
//
//  - CC messages are MUCH smaller (3 bytes vs 40+ for SysEx)
//  - Hardware responds instantly (no checksum calculation needed)
//  - Can be recorded and played back in DAWs
//  - Can be controlled by MIDI controllers, keyboards, and pedals
//  - Standard across all MIDI devices (SysEx format varies by manufacturer)
//
//  This view lets you map each synthesizer parameter to a CC number so you
//  can control the MiniWorks from external MIDI controllers or DAW automation.
//

import SwiftUI

struct CCMappingView: View {
    @EnvironmentObject var midiManager: MIDIManager
    @StateObject private var ccMapper = CCMapper()
    @State private var showingLearnMode = false
    @State private var learningParameter: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with learn mode toggle
            headerView
                .padding()
                .background(Color.blue.opacity(0.1))
            
            Divider()
            
            // Mapping list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(CCMapper.Parameter.allCases) { param in
                        mappingRow(for: param)
                        Divider()
                    }
                }
            }
            
            Divider()
            
            // Status and controls
            footerView
                .padding()
                .background(Color.gray.opacity(0.05))
        }
        .navigationTitle("CC Mapping")
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MIDI CC Mapping")
                        .font(.headline)
                    Text("Map parameters to MIDI CC numbers for real-time control")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("Learn Mode", isOn: $showingLearnMode)
                    .toggleStyle(.switch)
            }
            
            if showingLearnMode {
                Text("👆 Click a parameter, then move a knob on your MIDI controller")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Mapping Rows
    
    private func mappingRow(for parameter: CCMapper.Parameter) -> some View {
        HStack(spacing: 16) {
            // Parameter name
            VStack(alignment: .leading, spacing: 2) {
                Text(parameter.displayName)
                    .font(.body)
                Text(parameter.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 160, alignment: .leading)
            
            Spacer()
            
            // CC number picker
            HStack(spacing: 8) {
                Text("CC#")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let ccNumber = ccMapper.mapping[parameter] {
                    // Show assigned CC number
                    Menu {
                        Button("Clear Mapping") {
                            ccMapper.clearMapping(for: parameter)
                        }
                        
                        Divider()
                        
                        ForEach(0..<128) { cc in
                            Button("CC \(cc)") {
                                ccMapper.setMapping(parameter: parameter, ccNumber: cc)
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(ccNumber)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                } else {
                    // Not mapped
                    Button(action: {
                        if showingLearnMode {
                            learningParameter = parameter.rawValue
                        }
                    }) {
                        HStack {
                            Text("---")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40)
                            if learningParameter == parameter.rawValue {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .disabled(!showingLearnMode)
                }
            }
            
            // Last received value indicator
            if let value = ccMapper.lastValues[parameter] {
                Text("\(value)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(width: 40)
                    .padding(4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            } else {
                Text("--")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(learningParameter == parameter.rawValue ? Color.blue.opacity(0.05) : Color.clear)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Load Default Mapping") {
                    ccMapper.loadDefaultMapping()
                }
                .buttonStyle(.bordered)
                
                Button("Clear All") {
                    ccMapper.clearAllMappings()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save Mapping") {
                    ccMapper.saveMapping()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("\(ccMapper.mapping.count) parameters mapped")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - CC Mapper Model

/// Manages MIDI CC mapping for synthesizer parameters
///
/// HOW CC MAPPING WORKS:
/// ═══════════════════════════════════════════════════════════════════════
///
/// 1. USER MAPS PARAMETERS:
///    User assigns each synth parameter (like "Cutoff") to a CC number
///    Example: Cutoff -> CC# 74
///
/// 2. HARDWARE SENDS CC:
///    When you twist the cutoff knob on your MIDI controller, it sends:
///    B0 4A 40  (Channel 1, CC 74, Value 64)
///
/// 3. WE RECEIVE & ROUTE:
///    MIDIManager receives the CC message and looks up CC 74 in our mapping
///    Finds it's mapped to "Cutoff" parameter
///
/// 4. UPDATE PARAMETER:
///    We update the cutoff value to 64 and send to synthesizer
///
/// This creates a "bridge" between your MIDI controller and the synthesizer!
///
@MainActor
class CCMapper: ObservableObject {
    @Published var mapping: [Parameter: Int] = [:]
    @Published var lastValues: [Parameter: Int] = [:]
    
    /// All mappable parameters on the MiniWorks synthesizer
    enum Parameter: String, CaseIterable, Identifiable {
        // Oscillators
        case osc1Pitch, osc1Fine, osc2Pitch, osc2Fine, osc2Detune, oscMix, pwm
        
        // Filter
        case cutoff, resonance, vcfEnvAmount, vcfKeytrack, vcfModAmount
        
        // VCF Envelope
        case vcfAttack, vcfDecay, vcfSustain, vcfRelease
        
        // Amplifier
        case volume, vcaModAmount
        
        // VCA Envelope
        case vcaAttack, vcaDecay, vcaSustain, vcaRelease
        
        // Modulation
        case lfo1Rate, lfo1Amount, lfo2Rate, lfo2Amount, pitchModAmount
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .osc1Pitch: return "OSC 1 Pitch"
            case .osc1Fine: return "OSC 1 Fine Tune"
            case .osc2Pitch: return "OSC 2 Pitch"
            case .osc2Fine: return "OSC 2 Fine Tune"
            case .osc2Detune: return "OSC 2 Detune"
            case .oscMix: return "Oscillator Mix"
            case .pwm: return "Pulse Width Mod"
            case .cutoff: return "Filter Cutoff"
            case .resonance: return "Filter Resonance"
            case .vcfEnvAmount: return "VCF Envelope Amount"
            case .vcfKeytrack: return "VCF Keyboard Tracking"
            case .vcfModAmount: return "VCF Mod Amount"
            case .vcfAttack: return "VCF Attack"
            case .vcfDecay: return "VCF Decay"
            case .vcfSustain: return "VCF Sustain"
            case .vcfRelease: return "VCF Release"
            case .volume: return "Volume"
            case .vcaModAmount: return "VCA Mod Amount"
            case .vcaAttack: return "VCA Attack"
            case .vcaDecay: return "VCA Decay"
            case .vcaSustain: return "VCA Sustain"
            case .vcaRelease: return "VCA Release"
            case .lfo1Rate: return "LFO 1 Rate"
            case .lfo1Amount: return "LFO 1 Amount"
            case .lfo2Rate: return "LFO 2 Rate"
            case .lfo2Amount: return "LFO 2 Amount"
            case .pitchModAmount: return "Pitch Mod Amount"
            }
        }
        
        var category: String {
            switch self {
            case .osc1Pitch, .osc1Fine, .osc2Pitch, .osc2Fine, .osc2Detune, .oscMix, .pwm:
                return "Oscillator"
            case .cutoff, .resonance, .vcfEnvAmount, .vcfKeytrack, .vcfModAmount:
                return "Filter"
            case .vcfAttack, .vcfDecay, .vcfSustain, .vcfRelease:
                return "VCF Envelope"
            case .volume, .vcaModAmount:
                return "Amplifier"
            case .vcaAttack, .vcaDecay, .vcaSustain, .vcaRelease:
                return "VCA Envelope"
            case .lfo1Rate, .lfo1Amount, .lfo2Rate, .lfo2Amount, .pitchModAmount:
                return "Modulation"
            }
        }
    }
    
    init() {
        loadMapping()
    }
    
    // MARK: - Mapping Management
    
    func setMapping(parameter: Parameter, ccNumber: Int) {
        mapping[parameter] = ccNumber
        saveMapping()
    }
    
    func clearMapping(for parameter: Parameter) {
        mapping.removeValue(forKey: parameter)
        saveMapping()
    }
    
    func clearAllMappings() {
        mapping.removeAll()
        saveMapping()
    }
    
    /// Load default CC mapping based on General MIDI conventions
    func loadDefaultMapping() {
        mapping = [
            // Standard MIDI CC numbers for synthesis parameters
            .cutoff: 74,           // Brightness (commonly used for filter cutoff)
            .resonance: 71,        // Resonance/Harmonic Content
            .volume: 7,            // Volume (standard CC)
            .oscMix: 15,           // General Purpose 1
            .vcfEnvAmount: 73,     // Attack Time
            .vcfAttack: 73,        // Attack Time
            .vcfDecay: 75,         // Decay Time
            .vcfSustain: 70,       // Sound Controller 1
            .vcfRelease: 72,       // Release Time
            .vcaAttack: 73,        // Attack Time (envelope 2)
            .vcaDecay: 75,         // Decay Time
            .vcaSustain: 70,       // Sound Controller
            .vcaRelease: 72,       // Release Time
            .lfo1Rate: 76,         // Vibrato Rate
            .lfo1Amount: 77,       // Vibrato Depth
            .lfo2Rate: 78,         // Vibrato Delay
            .lfo2Amount: 1         // Mod Wheel (standard)
        ]
        saveMapping()
    }
    
    // MARK: - Receiving CC Messages
    
    /// Handle incoming CC message and update corresponding parameter
    ///
    /// This is called by MIDIManager when a CC message arrives.
    /// The message format is:
    ///   Status: 0xB0-0xBF (Control Change, channels 1-16)
    ///   Data1: CC number (0-127)
    ///   Data2: CC value (0-127)
    ///
    func handleCC(ccNumber: Int, value: Int, program: ProgramModel) {
        // Find which parameter this CC is mapped to
        guard let parameter = mapping.first(where: { $0.value == ccNumber })?.key else {
            return  // CC not mapped, ignore
        }
        
        // Store the last received value for display
        lastValues[parameter] = value
        
        // Update the corresponding parameter in the program
        updateParameter(parameter, value: value, in: program)
    }
    
    private func updateParameter(_ parameter: Parameter, value: Int, in program: ProgramModel) {
        // Map the incoming CC value (0-127) to the parameter
        // Some parameters might need scaling or transformation
        switch parameter {
        case .osc1Pitch: program.osc1Pitch = value
        case .osc1Fine: program.osc1Fine = value
        case .osc2Pitch: program.osc2Pitch = value
        case .osc2Fine: program.osc2Fine = value
        case .osc2Detune: program.osc2Detune = value
        case .oscMix: program.oscMix = value
        case .pwm: program.pwm = value
        case .cutoff: program.cutoff = value
        case .resonance: program.resonance = value
        case .vcfEnvAmount: program.vcfEnvAmount = value
        case .vcfKeytrack: program.vcfKeytrack = value
        case .vcfModAmount: program.vcfModAmount = value
        case .vcfAttack: program.vcfAttack = value
        case .vcfDecay: program.vcfDecay = value
        case .vcfSustain: program.vcfSustain = value
        case .vcfRelease: program.vcfRelease = value
        case .volume: program.volume = value
        case .vcaModAmount: program.vcaModAmount = value
        case .vcaAttack: program.vcaAttack = value
        case .vcaDecay: program.vcaDecay = value
        case .vcaSustain: program.vcaSustain = value
        case .vcaRelease: program.vcaRelease = value
        case .lfo1Rate: program.lfo1Rate = value
        case .lfo1Amount: program.lfo1Amount = value
        case .lfo2Rate: program.lfo2Rate = value
        case .lfo2Amount: program.lfo2Amount = value
        case .pitchModAmount: program.pitchModAmount = value
        }
    }
    
    // MARK: - Persistence
    
    private func saveMapping() {
        // Convert to JSON-friendly format
        let dict = mapping.mapValues { $0 }
        let keys = dict.keys.map { $0.rawValue }
        let values = dict.values
        
        UserDefaults.standard.set(Dictionary(uniqueKeysWithValues: zip(keys, values)), forKey: "CCMapping")
    }
    
    private func loadMapping() {
        guard let dict = UserDefaults.standard.dictionary(forKey: "CCMapping") as? [String: Int] else {
            return
        }
        
        mapping = dict.compactMapValues { ccNumber in
            ccNumber
        }.reduce(into: [:]) { result, pair in
            if let param = Parameter(rawValue: pair.key) {
                result[param] = pair.value
            }
        }
    }
}
