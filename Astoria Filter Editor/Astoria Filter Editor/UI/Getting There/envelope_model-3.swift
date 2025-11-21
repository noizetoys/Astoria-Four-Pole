import Foundation
import Combine

/// ObservableObject model for ADSR envelope parameters
/// Manages envelope values and triggers SysEx transmission on changes
class EnvelopeModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Attack time in milliseconds (calculated from MIDI value 0-127)
    /// 0 = 2ms, 64 = 1000ms, 127 = 60000ms
    @Published var attackTimeMs: Double = 1000 {
        didSet { scheduleParameterSend() }
    }
    
    /// Attack as normalized 0.0-1.0 value for internal use
    var attack: Double {
        get { attackMidiValue / 127.0 }
        set { attackTimeMs = Self.midiValueToMs(Self.msToMidiValue(newValue * 60000)) }
    }
    
    /// Attack as MIDI value (0-127)
    var attackMidiValue: Double {
        get { Self.msToMidiValue(attackTimeMs) }
        set { attackTimeMs = Self.midiValueToMs(newValue) }
    }
    
    /// Decay time (0.0 = instant, 1.0 = maximum)
    @Published var decay: Double = 0.5 {
        didSet { scheduleParameterSend() }
    }
    
    /// Sustain level (0.0 = silent, 1.0 = maximum)
    @Published var sustain: Double = 0.7 {
        didSet { scheduleParameterSend() }
    }
    
    /// Release time (0.0 = instant, 1.0 = maximum)
    @Published var release: Double = 0.5 {
        didSet { scheduleParameterSend() }
    }
    
    // MARK: - Additional Parameters (for future use)
    
    /// LFO Rate in Hz (calculated from MIDI value 0-127)
    /// 0 = 0.008 Hz, 64 = 1.0 Hz (approx), 127 = 261.6 Hz
    @Published var lfoRateHz: Double = 1.0 {
        didSet { scheduleParameterSend() }
    }
    
    /// LFO Rate as MIDI value (0-127)
    var lfoRateMidiValue: Double {
        get { Self.hzToMidiValue(lfoRateHz) }
        set { lfoRateHz = Self.midiValueToHz(newValue) }
    }
    
    /// Gate time in milliseconds (linear mapping from MIDI value 0-127)
    /// 0 = 0ms, 64 = 254ms, 127 = 508ms
    @Published var gateTimeMs: Double = 254.0 {
        didSet { scheduleParameterSend() }
    }
    
    /// Gate time as MIDI value (0-127)
    var gateTimeMidiValue: Double {
        get { Self.msToGateMidiValue(gateTimeMs) }
        set { gateTimeMs = Self.gateMidiValueToMs(newValue) }
    }
    
    // MARK: - Properties
    
    /// Reference to MIDI manager for sending SysEx
//    private let midiManager: MIDIManager
    
    /// Device ID for SysEx messages (0x00-0x7F)
    var deviceID: UInt8 = 0x00
    
    /// Envelope type: .vcf (filter) or .vca (amplifier)
    var envelopeType: EnvelopeType = .vcf
    
    /// Debounce timer to avoid flooding MIDI with rapid changes
    private var debounceTimer: Timer?
    
    /// Debounce delay in seconds
    private let debounceDelay: TimeInterval = 0.15
    
    // MARK: - Envelope Type
    
    enum EnvelopeType {
        case vcf  // Voltage Controlled Filter
        case vca  // Voltage Controlled Amplifier
        
        /// Base parameter number for this envelope type
        var baseParameterNumber: UInt8 {
            switch self {
            case .vcf: return 0x10  // VCF envelope starts at parameter 16
            case .vca: return 0x14  // VCA envelope starts at parameter 20
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize envelope model with MIDI manager
    /// - Parameter midiManager: MIDI manager instance for sending messages
//    init(midiManager: MIDIManager) {
//        self.midiManager = midiManager
//    }
    
    // MARK: - Attack Time Mapping
    
    /// Convert MIDI value (0-127) to milliseconds using exponential curve
    /// 0 = 2ms, 64 = 1000ms, 127 = 60000ms
    static func midiValueToMs(_ midiValue: Double) -> Double {
        let clampedValue = max(0, min(127, midiValue))
        
        if clampedValue == 0 {
            return 2.0
        }
        
        // Exponential mapping: ms = 2 * (30000 ^ (value/127))
        let normalizedValue = clampedValue / 127.0
        let exponent = normalizedValue * log(30000.0)
        return 2.0 * exp(exponent)
    }
    
    /// Convert milliseconds to MIDI value (0-127) using inverse exponential
    /// 2ms = 0, 1000ms = 64, 60000ms = 127
    static func msToMidiValue(_ ms: Double) -> Double {
        let clampedMs = max(2.0, min(60000.0, ms))
        
        if clampedMs <= 2.0 {
            return 0.0
        }
        
        // Inverse exponential: value = 127 * (log(ms/2) / log(30000))
        let normalized = log(clampedMs / 2.0) / log(30000.0)
        return normalized * 127.0
    }
    
    /// Format attack time for display
    static func formatAttackTime(_ ms: Double) -> String {
        if ms < 1000 {
            return String(format: "%.0f ms", ms)
        } else if ms < 10000 {
            return String(format: "%.2f s", ms / 1000.0)
        } else {
            return String(format: "%.1f s", ms / 1000.0)
        }
    }
    
    // MARK: - LFO Rate Mapping
    
    /// Convert MIDI value (0-127) to Hz using exponential curve
    /// 0 = 0.008 Hz, 64 = ~1.0 Hz, 127 = 261.6 Hz
    static func midiValueToHz(_ midiValue: Double) -> Double {
        let clampedValue = max(0, min(127, midiValue))
        
        if clampedValue == 0 {
            return 0.008
        }
        
        // Exponential mapping: Hz = 0.008 * (32700 ^ (value/127))
        // 32700 = 261.6 / 0.008
        let normalizedValue = clampedValue / 127.0
        let ratio = 261.6 / 0.008  // 32700
        let exponent = normalizedValue * log(ratio)
        return 0.008 * exp(exponent)
    }
    
    /// Convert Hz to MIDI value (0-127) using inverse exponential
    /// 0.008 Hz = 0, ~1.0 Hz = 64, 261.6 Hz = 127
    static func hzToMidiValue(_ hz: Double) -> Double {
        let clampedHz = max(0.008, min(261.6, hz))
        
        if clampedHz <= 0.008 {
            return 0.0
        }
        
        // Inverse exponential: value = 127 * (log(hz/0.008) / log(32700))
        let ratio = 261.6 / 0.008  // 32700
        let normalized = log(clampedHz / 0.008) / log(ratio)
        return normalized * 127.0
    }
    
    /// Format LFO rate for display
    static func formatLfoRate(_ hz: Double) -> String {
        if hz < 0.1 {
            return String(format: "%.3f Hz", hz)
        } else if hz < 1.0 {
            return String(format: "%.2f Hz", hz)
        } else if hz < 10.0 {
            return String(format: "%.1f Hz", hz)
        } else {
            return String(format: "%.0f Hz", hz)
        }
    }
    
    // MARK: - Gate Time Mapping
    
    /// Convert MIDI value (0-127) to milliseconds using linear mapping
    /// 0 = 0ms, 64 = 254ms, 127 = 508ms
    static func gateMidiValueToMs(_ midiValue: Double) -> Double {
        let clampedValue = max(0, min(127, midiValue))
        
        // Linear mapping: ms = value * 4
        return clampedValue * 4.0
    }
    
    /// Convert milliseconds to MIDI value (0-127) using linear mapping
    /// 0ms = 0, 254ms = 64, 508ms = 127
    static func msToGateMidiValue(_ ms: Double) -> Double {
        let clampedMs = max(0.0, min(508.0, ms))
        
        // Linear mapping: value = ms / 4
        return clampedMs / 4.0
    }
    
    /// Format gate time for display
    static func formatGateTime(_ ms: Double) -> String {
        return String(format: "%.0f ms", ms)
    }
    
    // MARK: - Parameter Sending
    
    /// Schedule a parameter send after debounce delay
    /// Cancels any pending sends and creates a new timer
    private func scheduleParameterSend() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { [weak self] _ in
            self?.sendAllParameters()
        }
    }
    
    /// Send all four ADSR parameters as individual SysEx messages
    private func sendAllParameters() {
//        let baseParam = envelopeType.baseParameterNumber
        
        // Convert to MIDI range
        // Attack uses the exponential mapping (already in MIDI value via attackMidiValue)
//        let attackValue = UInt8(attackMidiValue)
//        let decayValue = UInt8(decay * 127.0)
//        let sustainValue = UInt8(sustain * 127.0)
//        let releaseValue = UInt8(release * 127.0)
        
        // Send each parameter
//        midiManager.sendParameterChange(
//            deviceID: deviceID,
//            parameter: baseParam + 0,
//            value: attackValue
//        )
//        
//        midiManager.sendParameterChange(
//            deviceID: deviceID,
//            parameter: baseParam + 1,
//            value: decayValue
//        )
//        
//        midiManager.sendParameterChange(
//            deviceID: deviceID,
//            parameter: baseParam + 2,
//            value: sustainValue
//        )
//        
//        midiManager.sendParameterChange(
//            deviceID: deviceID,
//            parameter: baseParam + 3,
//            value: releaseValue
//        )
    }
    
    // MARK: - SysEx Reception
    
    /// Update envelope from received SysEx dump
    /// - Parameter data: Complete SysEx message data
    func updateFromSysEx(_ data: [UInt8]) {
        guard data.count >= 35 else { return }
        guard data[0] == 0xF0 && data[1] == 0x3E && data[2] == 0x04 else { return }
        
        // Verify checksum
//        guard midiManager.verifyChecksum(data) else {
//            print("Checksum verification failed")
//            return
//        }
        
        let baseParam = envelopeType.baseParameterNumber
        
        // Extract parameters from dump (bytes 5-34 contain parameters)
        // Parameter numbering starts at byte 5
        let parameterOffset = 5
        
        if Int(baseParam) + 3 < data.count - parameterOffset - 1 {
            // Temporarily disable sending while updating
            debounceTimer?.invalidate()
            
            // Attack uses exponential mapping from MIDI value
            let attackMidi = Double(data[parameterOffset + Int(baseParam) + 0])
            attackTimeMs = Self.midiValueToMs(attackMidi)
            
            decay = Double(data[parameterOffset + Int(baseParam) + 1]) / 127.0
            sustain = Double(data[parameterOffset + Int(baseParam) + 2]) / 127.0
            release = Double(data[parameterOffset + Int(baseParam) + 3]) / 127.0
        }
    }
    
    // MARK: - Preset Management
    
    /// Reset envelope to default values
    func resetToDefault() {
        debounceTimer?.invalidate()
        attackTimeMs = 100  // 100ms
        decay = 0.3
        sustain = 0.7
        release = 0.4
        scheduleParameterSend()
    }
    
    /// Set envelope to instant attack preset
    func setInstant() {
        debounceTimer?.invalidate()
        attackTimeMs = 2  // 2ms (minimum)
        decay = 0.0
        sustain = 1.0
        release = 0.0
        scheduleParameterSend()
    }
    
    /// Set envelope to slow pad preset
    func setSlowPad() {
        debounceTimer?.invalidate()
        attackTimeMs = 5000  // 5 seconds
        decay = 0.4
        sustain = 0.8
        release = 0.7
        scheduleParameterSend()
    }
}
