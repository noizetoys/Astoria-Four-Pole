import SwiftUI
import Foundation

// MARK: - MIDI Time Mapping

/// Maps a MIDI-style 7-bit value (0–127) to a time in seconds using a logarithmic curve.
///
/// WHY:
/// Human perception of time (and many modulation parameters) is closer to logarithmic
/// than linear. This function spaces values so that low times have fine control
/// (2 ms vs 10 ms), and high times can span up to 60 seconds without feeling cramped.
///
/// HOW:
/// We interpolate exponentially between minTime and maxTime, then apply a power
/// exponent to bend the curve so that a chosen midpoint (64) lands at approximately 1 second.
///
/// Defaults:
/// - midiValue =   0 → ≈ 0.002 s (2 ms)
/// - midiValue =  64 → ≈ 1.0 s
/// - midiValue = 127 → ≈ 60.0 s
func timeFromMIDIValue(_ midiValue: Int,
                       minTime: Double = 0.002,
                       midTime: Double = 1.0,
                       maxTime: Double = 60.0) -> Double {

    // Clamp MIDI into the valid 7-bit range.
    let clamped = Double(min(max(midiValue, 0), 127))

    // Normalize into [0,1].
    let normalized = clamped / 127.0

    // Empirically derived exponent so that value 64 maps close to 1 second.
    // See tutorial: we solve for 'a' in the equation
    //   minTime * (maxTime/minTime)^( (64/127)^a ) = midTime
    let exponent: Double = 0.74

    let ratio = maxTime / minTime
    let scaled = pow(ratio, pow(normalized, exponent))

    return minTime * scaled
}

/// Inverse mapping: time → approximate MIDI value (0–127).
///
/// WHY:
/// Useful if the user types a time manually and we want to reflect that back
/// into MIDI/automation domain.
///
/// HOW:
/// Invert the exponential mapping using logarithms.
func midiValueFromTime(_ time: Double,
                       minTime: Double = 0.002,
                       maxTime: Double = 60.0,
                       exponent: Double = 0.74) -> Int {
    // Clamp time into the valid range.
    let clampedTime = min(max(time, minTime), maxTime)

    let ratio = maxTime / minTime
    let normalized = log(clampedTime / minTime) / log(ratio)

    // Undo the power 'exponent' from the forward mapping.
    let midi = pow(normalized, 1.0 / exponent) * 127.0
    return Int(midi.rounded())
}

// MARK: - Visualizer View

struct MIDITimeMappingVisualizer: View {
    @State private var midiValue: Double = 64

    /// Current mapped time in seconds.
    private var timeSeconds: Double {
        timeFromMIDIValue(Int(midiValue))
    }

    /// A formatted string showing ms or seconds depending on magnitude.
    private var formattedTime: String {
        if timeSeconds < 0.1 {
            // show milliseconds
            let ms = timeSeconds * 1000
            return String(format: "%.1f ms", ms)
        } else if timeSeconds < 10 {
            return String(format: "%.3f s", timeSeconds)
        } else {
            return String(format: "%.2f s", timeSeconds)
        }
    }

    /// A normalized log scale 0...1, for drawing a bar that grows with time.
    /// We remap [minTime, maxTime] → [0,1] logarithmically.
    private var logNormalized: Double {
        let minTime = 0.002
        let maxTime = 60.0
        let ratio = maxTime / minTime
        let n = log(timeSeconds / minTime) / log(ratio)
        return min(max(n, 0), 1)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("MIDI Time Mapping Visualizer")
                .font(.title2.bold())

            // Slider for raw MIDI value 0...127
            VStack(spacing: 8) {
                HStack {
                    Text("MIDI Value")
                    Spacer()
                    Text(String(format: "%.0f", midiValue))
                        .monospacedDigit()
                }
                Slider(value: $midiValue, in: 0...127, step: 1)
            }

            // Display mapped time
            VStack(spacing: 8) {
                Text("Mapped Time")
                    .font(.headline)
                Text(formattedTime)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            // Animated log bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Log Scale (2 ms → 60 s)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                GeometryReader { proxy in
                    let width = proxy.size.width
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: width * logNormalized)
                            .animation(.easeOut(duration: 0.2), value: logNormalized)
                    }
                }
                .frame(height: 16)
            }

            // Sample “breakpoints”
            VStack(alignment: .leading, spacing: 4) {
                Text("Reference Points")
                    .font(.subheadline.bold())
                let v0 = 0
                let vMid = 64
                let vMax = 127
                Text("0   → \(String(format: "%.3f", timeFromMIDIValue(v0))) s")
                Text("64  → \(String(format: "%.3f", timeFromMIDIValue(vMid))) s")
                Text("127 → \(String(format: "%.3f", timeFromMIDIValue(vMax))) s")
            }
            .font(.footnote.monospacedDigit())
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

struct MIDITimeMappingVisualizer_Previews: PreviewProvider {
    static var previews: some View {
        MIDITimeMappingVisualizer()
            .preferredColorScheme(.dark)
    }
}
