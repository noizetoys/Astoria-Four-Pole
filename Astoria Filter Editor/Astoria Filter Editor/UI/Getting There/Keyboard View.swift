import SwiftUI

    // MARK: - MIDI Helpers
let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

func midiNoteName(_ note: Int) -> String {
    let name = noteNames[note % 12]
    let octave = (note / 12) - 1
    return "\(name)\(octave)"
}

struct PianoKey: Identifiable {
    let id = UUID()
    let midi: Int
    var isBlack: Bool { [1,3,6,8,10].contains(midi % 12) }
}

    // MARK: - Mod Wheel (spring center)
struct ModWheel: View {
    @Binding var value: Double
    @Binding var assignToPitchBend: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(assignToPitchBend ? "Pitch" : "Mod")
                .font(.caption)
            
            GeometryReader { geo in
                ZStack {
                    Capsule().fill(Color.gray.opacity(0.2))
                    
                    Capsule()
                        .fill(Color.gray)
                        .frame(height: geo.size.height * 0.25)
                        .offset(y: (0.5 - value) * geo.size.height)
                }
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let r = 1 - (g.location.y / geo.size.height)
                        value = min(max(r, 0), 1)
                    }
                    .onEnded { _ in
                        value = 0.5
                    }
                )
            }
            .frame(width: 40, height: 160)
            
            Text(String(format: "%.2f", value)).font(.caption2)
            Toggle("PB", isOn: $assignToPitchBend).font(.caption)
        }
    }
}

    // MARK: - Piano Keyboard
struct PianoKeyboardView: View {
    @State private var octave: Int = 3
    @State private var selectedNote: Int? = nil
    @State private var velocity: Double = 0.8
    @State private var aftertouch: Double = 0.0
    @State private var modWheel: Double = 0.5
    @State private var assignModToPitch = false
    
    let whiteWidth: CGFloat = 44
    let whiteSpacing: CGFloat = 2
    let blackWidth: CGFloat = 30
    let blackHeight: CGFloat = 100
    
    var keys: [PianoKey] {
        let base = (octave + 1) * 12
        return (0..<12).map { PianoKey(midi: base + $0) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
                // Octave stepper
//            HStack {
//                Button("◀︎") { octave = max(octave - 1, -1) }
//                Text("Octave: \(octave)").frame(minWidth: 80)
//                Button("▶︎") { octave = min(octave + 1, 9) }
//            }
//            .font(.title3)
            
            if let note = selectedNote {
                Text("Selected: \(midiNoteName(note)) (\(note)) Vel: \(Int(velocity*127)) AT: \(Int(aftertouch*127))")
                    .font(.headline)
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                    // Mod/Pitch wheel
//                ModWheel(value: $modWheel, assignToPitchBend: $assignModToPitch)
//                    .border(.red)
//                ModWheel(value: $modWheel, assignToPitchBend: $assignModToPitch)
//                    .border(.red)

                ZStack(alignment: .topLeading) {
                        // White keys
                    let whiteKeys = keys.filter { !$0.isBlack }
                    let whitePositions: [Int: CGFloat] = {
                        var map: [Int: CGFloat] = [:]
                        var x: CGFloat = 0
                        for key in whiteKeys {
                            map[key.midi % 12] = x
                            x += whiteWidth + whiteSpacing
                        }
                        return map
                    }()
                    
                    HStack(spacing: whiteSpacing) {
                        ForEach(whiteKeys) { key in
                            Rectangle()
                                .fill(selectedNote == key.midi ? Color.yellow : Color.white)
                                .frame(width: whiteWidth, height: 160)
                                .overlay(Rectangle().stroke(Color.black))
                                .gesture(keyGesture(key))
                        }
                    }
                    
                        // Black keys positioned absolutely
                    ForEach(keys.filter { $0.isBlack }) { key in
                        if let pos = blackXPosition(for: key.midi % 12, whiteMap: whitePositions) {
                            Rectangle()
                                .fill(selectedNote == key.midi ? Color.blue : Color.black)
                                .frame(width: blackWidth, height: blackHeight)
                                .overlay(Rectangle().stroke(Color.black))
                                .position(x: pos, y: blackHeight/2)
                                .gesture(keyGesture(key))
                        }
                    }
                }
                .border(.red)
            }
        }
        .padding()
    }
    
        // Compute black key X position
    func blackXPosition(for index: Int, whiteMap: [Int: CGFloat]) -> CGFloat? {
        let leftRightPairs: [Int: (Int, Int)] = [
            1: (0,2),   // C# between C & D
            3: (2,4),   // D# between D & E
            6: (5,7),   // F# between F & G
            8: (7,9),   // G# between G & A
            10:(9,11)   // A# between A & B
        ]
        guard let (l,r) = leftRightPairs[index],
              let xl = whiteMap[l], let xr = whiteMap[r] else { return nil }
        
        let center = (xl + (whiteWidth/2) + xr + (whiteWidth/2)) / 2
        return center
    }
    
        // Gesture
    func keyGesture(_ key: PianoKey) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if selectedNote != key.midi { selectedNote = key.midi }
                aftertouch = min(max(0, Double(-g.translation.height / 150)), 1)
            }
            .onEnded { _ in aftertouch = 0 }
    }
}


struct KeyBed: View {
    @State private var octave: Int = 3
    @State private var selectedNote: Int? = nil
    @State private var velocity: Double = 0.8
    @State private var aftertouch: Double = 0.0
    @State private var modWheel: Double = 0.5
    @State private var assignModToPitch = false
    
    let whiteWidth: CGFloat = 44
    let whiteSpacing: CGFloat = 2
    
    let blackWidth: CGFloat = 30
    let blackHeight: CGFloat = 100
    
    var keys: [PianoKey] {
        let base = (octave + 1) * 12
        return (0..<12).map { PianoKey(midi: base + $0) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Octave stepper
            //            HStack {
            //                Button("◀︎") { octave = max(octave - 1, -1) }
            //                Text("Octave: \(octave)").frame(minWidth: 80)
            //                Button("▶︎") { octave = min(octave + 1, 9) }
            //            }
            //            .font(.title3)
            
            if let note = selectedNote {
                Text("Selected: \(midiNoteName(note)) (\(note)) Vel: \(Int(velocity*127)) AT: \(Int(aftertouch*127))")
                    .font(.headline)
            }
            
            
            ZStack(alignment: .topLeading) {
                // White keys
                let whiteKeys = keys.filter { !$0.isBlack }
                let whitePositions: [Int: CGFloat] = {
                    var map: [Int: CGFloat] = [:]
                    var x: CGFloat = 0
                    
                    for key in whiteKeys {
                        map[key.midi % 12] = x
                        x += whiteWidth + whiteSpacing
                    }
                    return map
                }()
                
                HStack(spacing: whiteSpacing) {
                    ForEach(whiteKeys) { key in
                        whiteKey(key: key)
                    }
                }
                
                // Black keys positioned absolutely
                ForEach(keys.filter { $0.isBlack }) { key in
                    if let pos = blackXPosition(for: key.midi % 12, whiteMap: whitePositions) {
                        blackKey(key: key, pos: pos)
                    }
                }
            }
            .border(.red)
        }
        .padding()
    }
    
    
    private func whiteKey(key: PianoKey) -> some View {
        Rectangle()
            .fill(selectedNote == key.midi ? Color.yellow : Color.white)
            .frame(width: whiteWidth, height: 160)
            .overlay(Rectangle().stroke(Color.black))
            .gesture(keyGesture(key))
        
    }
    
    
    private func blackKey(key: PianoKey, pos: CGFloat) -> some View {
        Rectangle()
            .fill(selectedNote == key.midi ? Color.blue : Color.black)
            .frame(width: blackWidth, height: blackHeight)
            .overlay(Rectangle().stroke(Color.black))
            .position(x: pos, y: blackHeight/2)
            .gesture(keyGesture(key))
    }
    
    
    // Compute black key X position
    func blackXPosition(for index: Int, whiteMap: [Int: CGFloat]) -> CGFloat? {
        let leftRightPairs: [Int: (Int, Int)] = [
            1: (0,2),   // C# between C & D
            3: (2,4),   // D# between D & E
            6: (5,7),   // F# between F & G
            8: (7,9),   // G# between G & A
            10:(9,11)   // A# between A & B
        ]
        guard let (l,r) = leftRightPairs[index],
              let xl = whiteMap[l], let xr = whiteMap[r] else { return nil }
        
        let center = (xl + (whiteWidth/2) + xr + (whiteWidth/2)) / 2
        return center
    }
    
    // Gesture
    func keyGesture(_ key: PianoKey) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if selectedNote != key.midi { selectedNote = key.midi }
                aftertouch = min(max(0, Double(-g.translation.height / 150)), 1)
            }
            .onEnded { _ in aftertouch = 0 }
    }
}

//struct PianoKeyboardView_Previews: PreviewProvider {
//    static var previews: some View { PianoKeyboardView() }
//}

    // MARK: - Preview
#Preview {
//    PianoKeyboardView()
    KeyBed()
}
