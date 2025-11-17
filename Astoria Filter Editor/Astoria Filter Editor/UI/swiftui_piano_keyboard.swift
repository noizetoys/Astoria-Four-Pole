import SwiftUI

// MARK: - MIDI Helpers
let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

func midiNoteName(_ note: Int) -> String {
    let name = noteNames[note % 12]
    let octave = (note / 12) - 1
    return "\(name)\(octave)"
}

// MARK: - Piano Key Model
struct PianoKey: Identifiable {
    let id = UUID()
    let midi: Int
    var isBlack: Bool { [1,3,6,8,10].contains(midi % 12) }
}

// MARK: - Mod Wheel
struct ModWheel: View {
    @Binding var value: Double
    @Binding var assignToPitchBend: Bool

    var body: some View {
        VStack {
            Text(assignToPitchBend ? "Pitch" : "Mod")
                .font(.caption)

            Slider(value: $value, in: 0...1)
                .rotationEffect(.degrees(-90))
                .frame(height: 150)

            Toggle("PB", isOn: $assignToPitchBend)
                .font(.caption)
        }
        .padding(4)
    }
}

// MARK: - Piano Keyboard View
struct PianoKeyboardView: View {
    @State private var octave: Int = 3
    @State private var selectedNote: Int? = nil
    @State private var velocity: Double = 0.8
    @State private var aftertouch: Double = 0.0
    @State private var modWheel: Double = 0.0
    @State private var assignModToPitch = false

    var keys: [PianoKey] {
        let base = (octave + 1) * 12
        return (0..<12).map { PianoKey(midi: base + $0) }
    }

    var body: some View {
        VStack(spacing: 16) {

            // Octave Stepper
            Stepper("Octave: \(octave)", value: $octave, in: -1...9)
                .padding(.horizontal)

            // Selected note display
            if let note = selectedNote {
                Text("Selected: \(midiNoteName(note)) (\(note))  Vel: \(Int(velocity*127))  AT: \(Int(aftertouch*127))")
                    .font(.headline)
            }

            HStack(alignment: .bottom, spacing: 8) {

                // Mod Wheel
                ModWheel(value: $modWheel, assignToPitchBend: $assignModToPitch)

                // Piano Keys
                ZStack {
                    // White keys
                    HStack(spacing: 2) {
                        ForEach(keys.filter { !$0.isBlack }) { key in
                            pianoKeyView(key)
                                .foregroundColor(.black)
                                .background(selectedNote == key.midi ? Color.yellow : Color.white)
                                .cornerRadius(4)
                        }
                    }

                    // Black keys overlayed
                    HStack {
                        ForEach(keys) { key in
                            if key.isBlack {
                                Spacer(minLength: key.midi % 12 == 1 || key.midi % 12 == 6 ? 16 : 0)
                                pianoKeyView(key)
                                    .frame(width: 24, height: 110)
                                    .background(selectedNote == key.midi ? Color.blue : Color.black)
                                    .cornerRadius(3)
                                Spacer(minLength: key.midi % 12 == 3 || key.midi % 12 == 10 ? 16 : 0)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 160)
            }
            .padding(.bottom)
        }
        .padding()
    }

    // MARK: - Piano Key Rendering
    func pianoKeyView(_ key: PianoKey) -> some View {
        Rectangle()
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if selectedNote != key.midi {
                        selectedNote = key.midi
                    }
                    aftertouch = min(max(0, value.translation.height / -150), 1)
                }
                .onEnded { _ in
                    aftertouch = 0
                }
            )
    }
}

// MARK: - Preview
struct PianoKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        PianoKeyboardView()
    }
}
