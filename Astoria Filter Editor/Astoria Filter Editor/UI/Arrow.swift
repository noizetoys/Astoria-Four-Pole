import SwiftUI

// MARK: - Overview
//  ArrowPickerGlowView
//
//  This view draws an arrow with a color picker *inside the shaft* and an
//  animated glow that flows from the tail of the arrow to the tip.
//
//  Features:
//  - Color Picker in the shaft: None (default), Red, Green, Blue.
//  - When "None" is selected:
//      * Arrow is dull gray.
//      * Glow is disabled.
//  - When a color is selected:
//      * Arrow fill and stroke use that color (semi-transparent).
//      * A glow band travels from tail → tip, then jumps back and repeats.
//  - A Direction Picker (up, down, left, right) rotates the arrow & glow.
//  - Sliders:
//      * Glow speed in cycles per second (passes per second).
//      * Glow intensity (brightness of the glow band).
//
//  Important implementation details:
//  - The arrow is drawn as a right-pointing `ArrowShape`, then rotated to
//    match the selected direction.
//  - The glow is driven by a `TimelineView(.animation)`, which gives you
//    a time value you can map to a 0–1 "phase" of the animation.
//  - The **glow is inside a container ZStack the same size as the arrow, and
//    that container is masked with a full-size ArrowShape**. This guarantees
//    that the visible glow always matches the arrow’s shape and size, rather
//    than being limited to the width of the picker or gradient band.
//

// MARK: - Models

/// Which color mode the arrow is in.
enum ArrowSelection: String, CaseIterable, Identifiable {
    case none
    case red
    case green
    case blue
    
    var id: String { rawValue }
    
    /// Label for the UI picker.
    var label: String {
        switch self {
            case .none:  return "None"
            case .red:   return "Red"
            case .green: return "Green"
            case .blue:  return "Blue"
        }
    }
    
    /// Base SwiftUI color used for this mode.
    /// `nil` means "no active color" (we use gray instead).
    var color: Color? {
        switch self {
            case .none:  return nil
            case .red:   return .red
            case .green: return .green
            case .blue:  return .blue
        }
    }
}

/// Direction for the arrow.
///
/// The underlying shape is drawn pointing right, then rotated by this angle.
enum ArrowDirection: String, CaseIterable, Identifiable {
    case right
    case left
    case up
    case down
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
            case .right: return "Right"
            case .left:  return "Left"
            case .up:    return "Up"
            case .down:  return "Down"
        }
    }
    
    /// Rotation applied to the right-pointing base arrow.
    var rotationAngle: Angle {
        switch self {
            case .right: return .degrees(0)
            case .left:  return .degrees(180)
            case .up:    return .degrees(-90)
            case .down:  return .degrees(90)
        }
    }
}

// MARK: - Arrow Shape

/// A right-pointing arrow shape that fills its given rect.
///
/// The arrow has:
/// - A rectangular shaft (centered vertically).
/// - A triangular head at the right side.
struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width  = rect.width
        let height = rect.height
        
        // Proportions for head and shaft.
        let headWidth   = width * 0.30
        let shaftWidth  = width - headWidth
        let shaftHeight = height * 0.45
        
        // Vertical extents of the shaft.
        let shaftTopY    = rect.midY - shaftHeight / 2
        let shaftBottomY = rect.midY + shaftHeight / 2
        
        // Construct the arrow outline (clockwise).
        path.move(to: CGPoint(x: rect.minX, y: shaftTopY))                     // shaft top-left
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: shaftTopY))     // shaft top-right
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: rect.minY))     // head top
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))                  // tip
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: rect.maxY))     // head bottom
        path.addLine(to: CGPoint(x: rect.minX + shaftWidth, y: shaftBottomY))  // shaft bottom-right
        path.addLine(to: CGPoint(x: rect.minX, y: shaftBottomY))               // shaft bottom-left
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Main View


struct ArrowPickerGlowView: View {
    // MARK: State
    
    /// Current color selection.
    @State private var selection: ArrowSelection = .none
    
    /// Current arrow direction.
    @State private var direction: ArrowDirection = .right
    
    /// Glow speed in cycles per second (passes from tail → tip).
    @State private var glowSpeedCPS: Double = 0.5
    
    /// Glow intensity from 0 (almost invisible) to 1 (full strength).
    @State private var glowIntensity: Double = 0.9
    
    // MARK: Derived Properties
    
    /// Whether a real color is active (vs. "None").
    private var hasColor: Bool {
        selection != .none
    }
    
    /// Base fill color for the arrow body.
    private var baseColor: Color {
        guard let color = selection.color else {
            return Color.gray.opacity(0.35)   // dull gray when no color
        }
        return color.opacity(0.55)           // semi-transparent when active
    }
    
    /// Outline color for the arrow, same family as body.
    private var strokeColor: Color {
        baseColor.opacity(hasColor ? 0.9 : 0.7)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // Direction picker (segmented control).
            HStack {
                Text("Direction")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Direction", selection: $direction) {
                    ForEach(ArrowDirection.allCases) { dir in
                        Text(dir.label).tag(dir)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // Main arrow + glow + color picker section.
            GeometryReader { geo in
                // Arrow geometry: tweak these ratios to change overall size.
                let arrowWidth  = min(geo.size.width * 0.7, 280)
                let arrowHeight = arrowWidth * 0.35  // relatively shallow arrow
                
                ZStack {
                    // This whole ZStack holds BOTH the arrow+glow and the picker overlay.
                    // We rotate this container once, so the picker sits inside the shaft
                    // in ALL directions (right/left/up/down).
                    ZStack {
                        // --- Arrow + Glow (base coordinate system: right-pointing) ---
                        TimelineView(.animation) { timeline in
                            let now = timeline.date.timeIntervalSinceReferenceDate
                            
                            // phase ranges from 0.0 to 1.0 over time:
                            //  phase = fractional part of (time * cyclesPerSecond)
                            let phase: Double = (hasColor && glowSpeedCPS > 0)
                            ? (now * glowSpeedCPS).truncatingRemainder(dividingBy: 1.0)
                            : 0.0
                            
                            ZStack {
                                // 1. Arrow body and outline.
                                ArrowShape()
                                    .fill(baseColor)
                                    .overlay(
                                        ArrowShape()
                                            .stroke(strokeColor, lineWidth: 2)
                                    )
                                
                                // 2. Glow band moving along the arrow.
                                if let activeColor = selection.color,
                                   glowSpeedCPS > 0,
                                   hasColor {
                                    
                                    // ZStack that has the same size as the arrow.
                                    // We place the gradient band inside this container
                                    // and then mask the whole container with ArrowShape.
                                    ZStack {
                                        // Width of the glowing band.
                                        let bandWidth = arrowWidth * 0.45
                                        
                                        // Total distance for the center of the band to travel
                                        // from "off the tail" to "off the tip".
                                        let travel = arrowWidth + bandWidth
                                        
                                        // Center position at phase = 0 (start) and phase = 1 (end).
                                        let startX = -travel / 2
                                        let endX   =  travel / 2
                                        
                                        // Interpolate between start and end based on phase.
                                        let xOffset = startX + phase * (endX - startX)
                                        
                                        // The gradient itself: transparent -> bright -> transparent.
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .clear,
                                                activeColor.opacity(glowIntensity),
                                                .clear
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(width: bandWidth, height: arrowHeight * 1.2)
                                        .offset(x: xOffset)
                                        .blur(radius: 10)
                                    }
                                    // Match the size of the arrow.
                                    .frame(width: arrowWidth, height: arrowHeight)
                                    // Mask with a full-size ArrowShape, so the glow
                                    // is visible ONLY inside the arrow silhouette.
                                    .mask(
                                        ArrowShape()
                                            .fill(style: FillStyle(eoFill: false, antialiased: true))
                                    )
                                }
                            }
                            // Constrain arrow+glow to the chosen size.
                            .frame(width: arrowWidth, height: arrowHeight)
                        }
                        
                        // --- Picker overlay in the shaft (same coordinate system) ---
                        //
                        // Because this overlay shares the same coordinate space
                        // as the base right-pointing arrow, it naturally sits
                        // inside the horizontal shaft. We rotate the WHOLE
                        // container ZStack (see below), so when the arrow points
                        // up or down, the picker rotates with it and becomes
                        // vertical, occupying the shaft area in that direction.
                        Picker("", selection: $selection) {
                            ForEach(ArrowSelection.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)       // non-segmented menu picker
                        .frame(width: arrowWidth * 0.7)
                    }
                    // This rotation is applied to BOTH the arrow+glow and the picker,
                    // keeping the picker aligned in the shaft no matter the direction.
                    .frame(width: arrowWidth, height: arrowHeight)
                    .rotationEffect(direction.rotationAngle)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 160)
            .padding(.horizontal)
            
            // Glow controls: speed & intensity.
            VStack(alignment: .leading, spacing: 16) {
                // Glow speed slider.
                VStack(alignment: .leading, spacing: 4) {
                    Text("Glow Speed (cycles per second)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $glowSpeedCPS, in: 0.1...3.0, step: 0.05) {
                        Text("Glow Speed")
                    }
                    
                    Text(String(format: "%.2f cycles/s", glowSpeedCPS))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Glow intensity slider.
                VStack(alignment: .leading, spacing: 4) {
                    Text("Glow Intensity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $glowIntensity, in: 0.1...1.0, step: 0.05) {
                        Text("Glow Intensity")
                    }
                    
                    Text(String(format: "%.2f", glowIntensity))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .background(Color.black.opacity(0.96).ignoresSafeArea())
    }
}

// MARK: - How to Integrate
//
// To use this in an app, create your own App and ContentView, e.g.:
//
// struct ContentView: View {
//     var body: some View {
//         ArrowPickerGlowView()
//     }
// }
//
// @main
// struct MyApp: App {
//     var body: some Scene {
//         WindowGroup {
//             ContentView()
//         }
//     }
// }
//
// Customization pointers are in the comments above at the relevant lines:
// - Change arrow proportions in `ArrowShape`.
// - Change `arrowWidth` / `arrowHeight` calculation in `GeometryReader`.
// - Adjust glow band width and motion in the glow ZStack.

#Preview {
    ArrowPickerGlowView()
}
