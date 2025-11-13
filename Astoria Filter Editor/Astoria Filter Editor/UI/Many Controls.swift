import SwiftUI

// ============================================================================
// TUTORIAL: SwiftUI Custom Controls - Complete Collection
// ============================================================================
// This file contains four fully functional custom controls with detailed
// explanations, customization options, and usage examples.
//
// CONTENTS:
// 1. CircularFaderKnob - Rotary knob (7 o'clock to 5 o'clock, 300°)
// 2. LinearSlider - Horizontal slider with gradient track
// 3. RotarySwitch - Discrete position switch with snap-to behavior
// 4. Joystick - 2D control with spring-back and dead zone
// 5. ControlsDemoView - Complete demo app using all controls
// 6. CustomizationExamples - Real-world customization examples
//
// HOW TO USE:
// 1. Copy this entire file into your Xcode project
// 2. Use any control in your views with @State bindings
// 3. Customize colors, sizes, and behaviors as needed
// 4. Run ControlsDemoView to see all controls in action
//
// AUTHOR: SwiftUI Custom Controls Tutorial
// LICENSE: Free to use and modify
// ============================================================================


// ============================================================================
// CONTROL 1: CIRCULAR FADER KNOB
// ============================================================================
// A circular knob control with rotating indicator, min/max labels, and
// gradient-filled center. Range: 7 o'clock (210°) to 5 o'clock (-30°/330°).
//
// HOW IT WORKS:
// - Uses @Binding for two-way data flow (parent controls the value)
// - Converts 0-1 value to 300° angle range
// - DragGesture calculates angle from touch position using atan2
// - Handles wraparound at 0°/360° boundary
// - Uses .trim() to draw partial circles for tracks
// - Uses .rotationEffect() to position indicator and labels
//
// ARCHITECTURE:
// - Computed properties recalculate on value changes (efficient)
// - Separate view properties for each visual element (maintainable)
// - Gesture updates binding directly (reactive)
// ============================================================================

struct CircularFaderKnob: View {
    // MARK: - State
    // WHY: @Binding allows parent to control and observe the value
    @Binding var value: Double // Range: 0.0 (min) to 1.0 (max)
    
    // CUSTOMIZATION: Overall knob diameter in points
    var size: CGFloat = 200
    
    // CUSTOMIZATION: Track (circular path) styling
    var trackWidth: CGFloat = 4
    var trackColor: Color = .gray
    var activeTrackColor: Color = .blue
    
    // CUSTOMIZATION: Indicator (position marker) styling
    var indicatorSize: CGFloat = 16
    var indicatorColor: Color = .blue
    
    // CUSTOMIZATION: Min/Max label styling
    var labelSize: CGFloat = 40
    var labelColor: Color = .gray
    var labelDistance: CGFloat = 30 // Distance from knob edge
    
    // CUSTOMIZATION: Gradient colors for knob center (3D effect)
    var gradientColors: [Color] = [.gray, .black]
    
    // MARK: - Computed Properties
    
    // WHY: Radius is needed for all circular calculations
    // HOW: Simply half the diameter
    private var radius: CGFloat {
        size / 2
    }
    
    // WHY: Track sits inside the knob edge for visual spacing
    // HOW: Subtract 20 points from radius to create inset
    private var trackRadius: CGFloat {
        radius - 20
    }
    
    // CUSTOMIZATION: Angular range configuration
    // WHY: 7 o'clock = 210°, 5 o'clock = -30° (or 330°)
    // This gives us a 300° sweep, avoiding the bottom 60° of the circle
    // which is common in audio/music controls
    private var startAngle: Angle {
        .degrees(210)
    }
    
    private var endAngle: Angle {
        .degrees(-30)
    }
    
    // WHY: Total degrees available for rotation
    // HOW: 210° to 330° (going clockwise) = 300° total
    private var totalSweep: Double {
        300
    }
    
    // WHY: Convert our 0-1 value to an angle within our range
    // HOW: Map linearly: 0 → 210°, 0.5 → 360°, 1.0 → 510° (wraps to 150°)
    private var currentAngle: Angle {
        .degrees(startAngle.degrees + (value * totalSweep))
    }
    
    // WHY: Calculate how much of the circle to draw for the track
    // HOW: 300° out of 360° = 0.833 (83.3% of full circle)
    private var trimAmount: CGFloat {
        totalSweep / 360.0
    }
    
    var body: some View {
        ZStack {
            // WHY: Layer visual elements from back to front
            knobBody       // Background gradient circle
            trackPath      // Inactive track (shows full range)
            activeTrackPath // Active track (shows current value)
            indicator      // Position marker
            minLabel       // Minimum value label (-)
            maxLabel       // Maximum value label (+)
        }
        .frame(width: size + (labelDistance * 2),
               height: size + (labelDistance * 2))
        // WHY: DragGesture enables user interaction
        .gesture(dragGesture)
    }
    
    // MARK: - View Components
    
    // WHY: Main knob body provides visual depth with gradient
    // HOW: RadialGradient from top-left creates lighting effect
    private var knobBody: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: gradientColors),
                    center: .topLeading, // WHY: Creates top-left highlight
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: size - 60, height: size - 60)
        // WHY: Drop shadow creates 3D depth effect
            .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 5)
            .overlay(
                // WHY: Inner shadow for additional depth
                // HOW: Stroke + blur + mask creates shadow effect
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 2)
                    .blur(radius: 4)
                    .offset(x: 0, y: 2)
                    .mask(Circle().fill(LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )))
            )
    }
    
    // WHY: The full track shows the entire available range
    // HOW: Use .trim() to draw only the 300° arc
    private var trackPath: some View {
        Circle()
            .trim(from: 0, to: trimAmount)
            .stroke(trackColor, style: StrokeStyle(
                lineWidth: trackWidth,
                lineCap: .round // WHY: Rounded ends look better
            ))
            .frame(width: trackRadius * 2, height: trackRadius * 2)
        // WHY: Rotate to position the arc at our start angle
        // HOW: Add 90° because .trim() starts at 3 o'clock (0°)
            .rotationEffect(startAngle + .degrees(90))
    }
    
    // WHY: Shows the "filled" portion from min to current value
    // HOW: Same as trackPath but trim to current value percentage
    private var activeTrackPath: some View {
        Circle()
            .trim(from: 0, to: CGFloat(value) * trimAmount)
            .stroke(activeTrackColor, style: StrokeStyle(
                lineWidth: trackWidth,
                lineCap: .round
            ))
            .frame(width: trackRadius * 2, height: trackRadius * 2)
            .rotationEffect(startAngle + .degrees(90))
    }
    
    // WHY: Small circle that travels along the track showing exact position
    // HOW: Position at 12 o'clock, then rotate to current angle
    private var indicator: some View {
        Circle()
            .fill(indicatorColor)
            .frame(width: indicatorSize, height: indicatorSize)
        // WHY: Shadow makes indicator stand out from track
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        // WHY: offset(y:) moves up to 12 o'clock position
        // Then rotationEffect moves to actual angle
            .offset(y: -trackRadius)
            .rotationEffect(currentAngle)
    }
    
    // WHY: Shows minimum value marker at 7 o'clock position
    // HOW: Position circle at 12 o'clock, rotate to start angle
    private var minLabel: some View {
        ZStack {
            Circle()
                .fill(labelColor)
                .frame(width: labelSize, height: labelSize)
            
            Text("−")
                .font(.system(size: labelSize * 0.6, weight: .bold))
                .foregroundColor(.white)
        }
        // WHY: Position outside knob edge by radius + distance
        .offset(y: -(radius + labelDistance))
        .rotationEffect(startAngle)
    }
    
    // WHY: Shows maximum value marker at 5 o'clock position
    // HOW: Same as minLabel but at end angle
    private var maxLabel: some View {
        ZStack {
            Circle()
                .fill(labelColor)
                .frame(width: labelSize, height: labelSize)
            
            Text("+")
                .font(.system(size: labelSize * 0.6, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(y: -(radius + labelDistance))
        .rotationEffect(endAngle)
    }
    
    // MARK: - Gesture Handling
    
    // WHY: Allows user to drag and rotate the knob
    // HOW: minimumDistance: 0 means immediate response (no drag threshold)
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                updateValue(for: gesture.location)
            }
    }
    
    // WHY: Convert touch location to angle, then to value
    // HOW: 1. Find center point
    //      2. Calculate angle from center to touch using atan2
    //      3. Convert angle to value using angleToValue()
    //      4. Clamp to 0-1 range
    private func updateValue(for location: CGPoint) {
        // WHY: Calculate center of the entire view (including labels)
        let center = CGPoint(
            x: (size + labelDistance * 2) / 2,
            y: (size + labelDistance * 2) / 2
        )
        
        // WHY: atan2 gives us angle in radians from center to touch point
        // HOW: atan2(y, x) returns angle from -π to π
        let angle = atan2(
            location.y - center.y,
            location.x - center.x
        )
        
        // WHY: Convert radians to degrees and normalize to 0-360
        // HOW: * 180 / .pi converts radians to degrees
        //      + 90 adjusts because atan2(0,1) = 0° but we want 90°
        var degrees = angle * 180 / .pi + 90
        if degrees < 0 { degrees += 360 }
        
        // WHY: Convert angle to value within our valid range
        let newValue = angleToValue(degrees: degrees)
        
        // WHY: Clamp to 0-1 range to prevent invalid values
        value = min(max(newValue, 0), 1)
    }
    
    // WHY: Maps an angle (in degrees) back to our 0-1 value range
    // HOW: 1. Calculate offset from start angle
    //      2. Handle wraparound at 0°/360° boundary
    //      3. Clamp to valid range (0 to totalSweep)
    //      4. Normalize to 0-1
    //
    // EXAMPLE: If user drags to 360° (12 o'clock):
    //   normalizedAngle = 360 - 210 = 150
    //   return 150 / 300 = 0.5
    private func angleToValue(degrees: Double) -> Double {
        // WHY: Calculate offset from start position
        var normalizedAngle = degrees - startAngle.degrees
        
        // WHY: Handle wraparound at 0°/360° boundary
        // EXAMPLE: Dragging from 350° to 10° gives -340°, but should be +20°
        if normalizedAngle < -180 { normalizedAngle += 360 }
        if normalizedAngle > 180 { normalizedAngle -= 360 }
        
        // WHY: Clamp to valid range and normalize to 0-1
        normalizedAngle = min(max(normalizedAngle, 0), totalSweep)
        return normalizedAngle / totalSweep
    }
}


// ============================================================================
// CONTROL 2: LINEAR SLIDER
// ============================================================================
// A horizontal slider with custom thumb, gradient track, and value labels.
//
// HOW IT WORKS:
// - Thumb position calculated as percentage of track width
// - Active track width extends from start to thumb center
// - DragGesture converts x position directly to value
// - No complex angle math needed (linear mapping)
//
// ARCHITECTURE:
// - Thumb offset is proportional to value (simple linear relationship)
// - Active track uses gradient for visual appeal
// - Labels positioned at fixed start/end positions
// ============================================================================

struct LinearSlider: View {
    // MARK: - State
    @Binding var value: Double // Range: 0.0 to 1.0
    
    // CUSTOMIZATION: Slider dimensions
    var width: CGFloat = 300
    var height: CGFloat = 60
    var trackHeight: CGFloat = 6
    
    // CUSTOMIZATION: Track styling
    var trackColor: Color = .gray
    var activeTrackColors: [Color] = [.blue, .purple] // WHY: Gradient colors
    
    // CUSTOMIZATION: Thumb (draggable circle) styling
    var thumbSize: CGFloat = 30
    var thumbColor: Color = .white
    var thumbBorderColor: Color = .blue
    var thumbBorderWidth: CGFloat = 3
    
    // CUSTOMIZATION: Label styling
    var showLabels: Bool = true
    var minLabel: String = "MIN"
    var maxLabel: String = "MAX"
    var labelColor: Color = .gray
    
    // CUSTOMIZATION: Value display
    var showValue: Bool = true
    var valueFormatter: (Double) -> String = { value in
        "\(Int(value * 100))%"
    }
    
    // MARK: - Computed Properties
    
    // WHY: Calculate thumb horizontal position along track
    // HOW: Multiply value by available track width
    //      Available width = total width - thumb size
    //      (thumb can't go beyond edges)
    private var thumbOffset: CGFloat {
        let trackWidth = width - thumbSize
        return CGFloat(value) * trackWidth
    }
    
    // WHY: Active track width based on current value
    // HOW: Same as thumbOffset but add half thumb size
    //      (track extends to center of thumb, not edge)
    private var activeTrackWidth: CGFloat {
        let trackWidth = width - thumbSize
        return CGFloat(value) * trackWidth + (thumbSize / 2)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // WHY: Value display above slider for immediate feedback
            if showValue {
                Text(valueFormatter(value))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(thumbBorderColor)
            }
            
            ZStack(alignment: .leading) {
                // WHY: Layer components: background → active → thumb
                backgroundTrack
                activeTrack
                thumb
            }
            .frame(width: width, height: height)
            .gesture(dragGesture)
            
            // WHY: Min/Max labels below slider for reference
            if showLabels {
                labels
            }
        }
    }
    
    // MARK: - View Components
    
    // WHY: Shows full slider range in lighter color
    // HOW: Full width rounded rectangle with horizontal padding
    //      Padding accounts for thumb size at edges
    private var backgroundTrack: some View {
        RoundedRectangle(cornerRadius: trackHeight / 2)
            .fill(trackColor.opacity(0.3))
            .frame(height: trackHeight)
            .padding(.horizontal, thumbSize / 2)
    }
    
    // WHY: Shows progress from start to current value with gradient
    // HOW: Variable width based on value, gradient from start to end
    private var activeTrack: some View {
        RoundedRectangle(cornerRadius: trackHeight / 2)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: activeTrackColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: activeTrackWidth, height: trackHeight)
            .padding(.leading, thumbSize / 2)
    }
    
    // WHY: Draggable control element that user interacts with
    // HOW: Circle with border, shadow, and horizontal offset
    private var thumb: some View {
        Circle()
            .fill(thumbColor)
            .frame(width: thumbSize, height: thumbSize)
            .overlay(
                Circle()
                    .strokeBorder(thumbBorderColor, lineWidth: thumbBorderWidth)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .offset(x: thumbOffset)
    }
    
    // WHY: Shows min/max labels for context
    // HOW: HStack with Spacer pushes labels to edges
    private var labels: some View {
        HStack {
            Text(minLabel)
                .font(.caption)
                .foregroundColor(labelColor)
            Spacer()
            Text(maxLabel)
                .font(.caption)
                .foregroundColor(labelColor)
        }
        .frame(width: width)
    }
    
    // MARK: - Gesture Handling
    
    // WHY: Enables drag interaction along horizontal axis
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                updateValue(for: gesture.location)
            }
    }
    
    // WHY: Convert horizontal x position to value
    // HOW: 1. Calculate available track width (total - thumb)
    //      2. Subtract thumb radius from x to get position on track
    //      3. Divide by track width to get 0-1 value
    //      4. Clamp to valid range
    //
    // EXAMPLE: If user touches at x=150 on 300px slider with 30px thumb:
    //   trackWidth = 300 - 30 = 270
    //   normalizedX = 150 - 15 = 135
    //   value = 135 / 270 = 0.5
    private func updateValue(for location: CGPoint) {
        let trackWidth = width - thumbSize
        let normalizedX = location.x - (thumbSize / 2)
        let newValue = Double(normalizedX / trackWidth)
        
        // WHY: Clamp to 0-1 range to prevent invalid values
        value = min(max(newValue, 0), 1)
    }
}


// ============================================================================
// CONTROL 3: ROTARY SWITCH
// ============================================================================
// A rotary switch with discrete positions (like a volume dial with detents).
// Each position has a label and icon. Snaps to nearest position.
//
// HOW IT WORKS:
// - Positions arranged in arc from 7 o'clock to 5 o'clock (270°)
// - Degrees per position calculated by dividing range by count
// - Drag gesture finds nearest position and snaps to it
// - Indicator rotates with spring animation for smooth transitions
//
// ARCHITECTURE:
// - positions array defines available selections
// - selectedIndex tracks current selection (not continuous value)
// - Snap-to behavior rounds angle to nearest position
// - Spring animation provides tactile feedback
// ============================================================================

struct RotarySwitch: View {
    // MARK: - State
    @Binding var selectedIndex: Int
    
    // CUSTOMIZATION: Switch configuration
    // WHY: Array of positions allows flexible configuration
    var positions: [RotaryPosition] = [
        RotaryPosition(label: "OFF", icon: "power"),
        RotaryPosition(label: "LOW", icon: "speaker.wave.1"),
        RotaryPosition(label: "MED", icon: "speaker.wave.2"),
        RotaryPosition(label: "HIGH", icon: "speaker.wave.3"),
        RotaryPosition(label: "MAX", icon: "speaker.wave.3.fill")
    ]
    
    // CUSTOMIZATION: Switch size
    var size: CGFloat = 200
    
    // CUSTOMIZATION: Color scheme
    var backgroundColor: Color = .black
    var activeColor: Color = .blue
    var inactiveColor: Color = .gray
    var indicatorColor: Color = .red
    
    // CUSTOMIZATION: Label positioning
    var labelDistance: CGFloat = 50
    
    // MARK: - Computed Properties
    
    private var radius: CGFloat { size / 2 }
    
    // WHY: Calculate degrees between each discrete position
    // HOW: Divide total range (270°) by gaps between positions
    //      With 5 positions, there are 4 gaps: 270 / 4 = 67.5° each
    private var degreesPerPosition: Double {
        guard positions.count > 1 else { return 0 }
        return 270.0 / Double(positions.count - 1)
    }
    
    // WHY: Starting angle at 7 o'clock position
    // HOW: 225° = -45° from top = 7 o'clock
    private var startAngle: Double { 225 }
    
    // WHY: Current angle based on selected index
    // HOW: Start angle minus (index * degrees per position)
    //      Subtract because we're going clockwise from 7 o'clock
    private var currentAngle: Angle {
        .degrees(startAngle - (Double(selectedIndex) * degreesPerPosition))
    }
    
    var body: some View {
        ZStack {
            dialBody
            
            // WHY: ForEach creates marker for each position
            ForEach(0..<positions.count, id: \.self) { index in
                positionMarker(at: index)
            }
            
            indicator
            
            // WHY: ForEach creates label for each position
            ForEach(0..<positions.count, id: \.self) { index in
                positionLabel(at: index)
            }
        }
        .frame(width: size + (labelDistance * 2),
               height: size + (labelDistance * 2))
        .gesture(dragGesture)
    }
    
    // MARK: - View Components
    
    // WHY: Main dial body with gradient and border
    private var dialBody: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.gray.opacity(0.8), backgroundColor]),
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(Color.gray.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
    }
    
    // WHY: Shows small dots at each available position on the dial
    // HOW: Calculate angle for this index, position circle at that angle
    private func positionMarker(at index: Int) -> some View {
        let angle = startAngle - (Double(index) * degreesPerPosition)
        let isSelected = index == selectedIndex
        
        return Circle()
            .fill(isSelected ? activeColor : inactiveColor)
            .frame(width: 8, height: 8)
            .offset(y: -(radius - 20))
            .rotationEffect(.degrees(angle))
    }
    
    // WHY: Red indicator line that points to current selection
    // HOW: Rounded rectangle rotated to current angle with spring animation
    private var indicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(indicatorColor)
            .frame(width: 6, height: radius - 30)
            .offset(y: -(radius - 30) / 2 - 5)
            .shadow(color: indicatorColor.opacity(0.5), radius: 4)
            .rotationEffect(currentAngle)
        // WHY: Spring animation provides satisfying snap-to feel
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentAngle)
    }
    
    // WHY: Shows label and icon for each position around dial
    // HOW: Position at angle, then counter-rotate text to keep it upright
    private func positionLabel(at index: Int) -> some View {
        let angle = startAngle - (Double(index) * degreesPerPosition)
        let position = positions[index]
        let isSelected = index == selectedIndex
        
        return VStack(spacing: 4) {
            Image(systemName: position.icon)
                .font(.system(size: 20))
            Text(position.label)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
        }
        .foregroundColor(isSelected ? activeColor : inactiveColor)
        .offset(y: -(radius + labelDistance))
        .rotationEffect(.degrees(angle))
        // WHY: Counter-rotate so text is always readable
        // First rotation positions label around circle,
        // second rotation makes text face up
        .rotationEffect(.degrees(-angle))
    }
    
    // MARK: - Gesture Handling
    
    // WHY: Snap to nearest position on drag
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                updateSelection(for: gesture.location)
            }
    }
    
    // WHY: Calculate which position is nearest to touch angle
    // HOW: 1. Calculate angle from center to touch
    //      2. Normalize angle relative to start position
    //      3. Divide by degrees per position and round
    //      4. Clamp to valid index range
    private func updateSelection(for location: CGPoint) {
        let center = CGPoint(
            x: (size + labelDistance * 2) / 2,
            y: (size + labelDistance * 2) / 2
        )
        
        // WHY: Calculate angle from center using atan2
        let angle = atan2(
            location.y - center.y,
            location.x - center.x
        )
        
        var degrees = angle * 180 / .pi + 90
        if degrees < 0 { degrees += 360 }
        
        // WHY: Normalize angle to start position
        var normalizedAngle = startAngle - degrees
        if normalizedAngle < 0 { normalizedAngle += 360 }
        if normalizedAngle > 360 { normalizedAngle -= 360 }
        
        // WHY: Find closest position by rounding
        // EXAMPLE: If normalizedAngle is 140° and degreesPerPosition is 67.5°
        //   140 / 67.5 = 2.07 → rounds to 2 → position index 2
        let positionIndex = Int(round(normalizedAngle / degreesPerPosition))
        let clampedIndex = min(max(positionIndex, 0), positions.count - 1)
        
        if clampedIndex != selectedIndex {
            selectedIndex = clampedIndex
        }
    }
}

// WHY: Separate struct for position configuration
// HOW: Each position has label text and SF Symbol name
struct RotaryPosition {
    let label: String
    let icon: String
}


// ============================================================================
// CONTROL 4: 2D JOYSTICK
// ============================================================================
// A 2D joystick control with spring-back animation and dead zone.
// Returns x,y coordinates in -1 to 1 range.
//
// HOW IT WORKS:
// - Position is CGPoint with x,y in -1 to 1 range
// - Drag gesture calculates distance from center
// - Distance is clamped to circular boundary (not square)
// - Dead zone near center registers as zero (prevents drift)
// - Spring-back returns stick to center when released
//
// ARCHITECTURE:
// - position binding is normalized (-1 to 1) for easy use in games
// - Stick offset converts normalized position to pixel offset
// - Distance calculation uses Pythagorean theorem
// - Spring animation provides realistic physics feel
// ============================================================================

struct Joystick: View {
    // MARK: - State
    // WHY: CGPoint allows 2D position with x and y
    @Binding var position: CGPoint // Range: -1 to 1 for both x and y
    
    // CUSTOMIZATION: Joystick dimensions
    var size: CGFloat = 200        // Base diameter
    var stickSize: CGFloat = 60    // Movable stick diameter
    
    // CUSTOMIZATION: Color scheme
    var baseColor: Color = .gray
    var stickColor: Color = .blue
    var crosshairColor: Color = .white
    
    // CUSTOMIZATION: Behavior
    var deadZone: CGFloat = 0.1           // Percentage of radius (0.1 = 10%)
    var springBack: Bool = true           // Return to center when released
    var showCrosshair: Bool = true        // Show center guides
    var maxDistance: CGFloat? = nil       // Max distance (nil = radius)
    
    @State private var isDragging = false
    
    // MARK: - Computed Properties
    
    private var radius: CGFloat { size / 2 }
    private var stickRadius: CGFloat { stickSize / 2 }
    
    // WHY: Maximum distance stick can travel from center
    // HOW: Default is base radius minus stick radius (touches edge)
    //      Can be customized to allow different range
    private var maxTravelDistance: CGFloat {
        maxDistance ?? (radius - stickRadius)
    }
    
    // WHY: Convert normalized position (-1 to 1) to pixel offset
    // HOW: Multiply by maxTravelDistance to get actual pixel movement
    private var stickOffset: CGSize {
        CGSize(
            width: position.x * maxTravelDistance,
            height: position.y * maxTravelDistance
        )
    }
    
    // WHY: Calculate distance from center as 0 to 1 value
    // HOW: Use Pythagorean theorem: distance = sqrt(x² + y²)
    private var distanceFromCenter: CGFloat {
        sqrt(position.x * position.x + position.y * position.y)
    }
    
    // WHY: Check if stick is within dead zone
    // HOW: Compare normalized distance to dead zone threshold
    private var isInDeadZone: Bool {
        distanceFromCenter < deadZone
    }
    
    var body: some View {
        ZStack {
            base
            
            if showCrosshair {
                crosshair
            }
            
            stick
        }
        .frame(width: size, height: size)
        .gesture(dragGesture)
    }
    
    // MARK: - View Components
    
    // WHY: Outer boundary and visual base of joystick
    // HOW: Multiple circles layered for depth effect
    private var base: some View {
        ZStack {
            // WHY: Main base circle with gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            baseColor.opacity(0.3),
                            baseColor.opacity(0.1)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
            
            // WHY: Border ring defines outer boundary
            Circle()
                .strokeBorder(baseColor.opacity(0.5), lineWidth: 2)
            
            // WHY: Inner shadow creates recessed effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .black.opacity(0.1),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: radius * 0.6
                    )
                )
        }
        .frame(width: size, height: size)
    }
    
    // WHY: Visual guides showing center position (X marks the spot)
    // HOW: Horizontal line + vertical line + center dot
    private var crosshair: some View {
        ZStack {
            // WHY: Horizontal center line
            Rectangle()
                .fill(crosshairColor.opacity(0.3))
                .frame(width: size * 0.6, height: 1)
            
            // WHY: Vertical center line
            Rectangle()
                .fill(crosshairColor.opacity(0.3))
                .frame(width: 1, height: size * 0.6)
            
            // WHY: Center dot for precise centering
            Circle()
                .fill(crosshairColor.opacity(0.5))
                .frame(width: 4, height: 4)
        }
    }
    
    // WHY: Draggable control element (the stick user moves)
    // HOW: Circle with gradient, shadow that changes on drag
    private var stick: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        stickColor,
                        stickColor.opacity(0.8)
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: stickRadius
                )
            )
            .frame(width: stickSize, height: stickSize)
            .overlay(
                Circle()
                    .strokeBorder(stickColor.opacity(0.5), lineWidth: 2)
            )
        // WHY: Shadow changes based on drag state for depth feedback
            .shadow(
                color: .black.opacity(isDragging ? 0.4 : 0.2),
                radius: isDragging ? 8 : 4,
                x: 0,
                y: isDragging ? 4 : 2
            )
            .offset(stickOffset)
        // WHY: Spring animation for smooth, realistic movement
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: stickOffset)
    }
    
    // MARK: - Gesture Handling
    
    // WHY: Enable drag with spring-back on release
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                isDragging = true
                updatePosition(for: gesture.location)
            }
            .onEnded { _ in
                isDragging = false
                // WHY: Spring back to center provides arcade-style feel
                if springBack {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        position = .zero
                    }
                }
            }
    }
    
    // WHY: Convert touch location to normalized 2D position
    // HOW: 1. Calculate offset from center in pixels
    //      2. Calculate distance from center
    //      3. Clamp to circular boundary (not square)
    //      4. Normalize to -1 to 1 range
    //      5. Apply dead zone
    private func updatePosition(for location: CGPoint) {
        let center = CGPoint(x: size / 2, y: size / 2)
        
        // WHY: Calculate offset from center in pixels
        var offset = CGPoint(
            x: location.x - center.x,
            y: location.y - center.y
        )
        
        // WHY: Calculate distance from center using Pythagorean theorem
        let distance = sqrt(offset.x * offset.x + offset.y * offset.y)
        
        // WHY: Clamp to circular boundary (not square)
        // HOW: If distance exceeds max, scale down proportionally
        //      This creates a circular boundary, not a square one
        // EXAMPLE: If touch is at distance 150 but max is 100:
        //   ratio = 100 / 150 = 0.667
        //   offset.x *= 0.667 (scales down)
        //   offset.y *= 0.667 (scales down)
        if distance > maxTravelDistance {
            let ratio = maxTravelDistance / distance
            offset.x *= ratio
            offset.y *= ratio
        }
        
        // WHY: Normalize to -1 to 1 range for easy use in game logic
        var normalizedX = offset.x / maxTravelDistance
        var normalizedY = offset.y / maxTravelDistance
        
        // WHY: Apply dead zone to prevent drift from small movements
        // HOW: Calculate total distance, if below threshold set to zero
        let normalizedDistance = sqrt(normalizedX * normalizedX + normalizedY * normalizedY)
        if normalizedDistance < deadZone {
            normalizedX = 0
            normalizedY = 0
        }
        
        position = CGPoint(x: normalizedX, y: normalizedY)
    }
}


// ============================================================================
// DEMO APP: Using All Four Controls
// ============================================================================
// This demonstrates how to integrate all controls into a working app.
// Each control uses @State in the parent view for data flow.
// ============================================================================

struct ControlsDemoView: View {
    // WHY: Each control needs @State for its value
    @State private var knobValue: Double = 0.5
    @State private var sliderValue: Double = 0.7
    @State private var switchIndex: Int = 2
    @State private var joystickPosition: CGPoint = .zero
    
    var body: some View {
        ScrollView {
            VStack(spacing: 50) {
                // ================================================
                // CIRCULAR KNOB DEMO
                // ================================================
                VStack(spacing: 20) {
                    Text("Circular Fader Knob")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    CircularFaderKnob(value: $knobValue)
                    
                    Text("\(Int(knobValue * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    // WHY: Reset button for testing
                    Button("Reset to 50%") {
                        withAnimation(.spring()) {
                            knobValue = 0.5
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
                
                Divider()
                
                // ================================================
                // LINEAR SLIDER DEMO
                // ================================================
                VStack(spacing: 20) {
                    Text("Linear Slider")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    LinearSlider(
                        value: $sliderValue,
                        minLabel: "0",
                        maxLabel: "100"
                    )
                    
                    // WHY: Show value in different format
                    Text("Value: \(String(format: "%.2f", sliderValue))")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundColor(.purple)
                    
                    Button("Reset to 70%") {
                        withAnimation(.spring()) {
                            sliderValue = 0.7
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
                
                Divider()
                
                // ================================================
                // ROTARY SWITCH DEMO
                // ================================================
                VStack(spacing: 20) {
                    Text("Rotary Switch")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    RotarySwitch(selectedIndex: $switchIndex)
                    
                    // WHY: Show current selection details
                    let positions = [
                        RotaryPosition(label: "OFF", icon: "power"),
                        RotaryPosition(label: "LOW", icon: "speaker.wave.1"),
                        RotaryPosition(label: "MED", icon: "speaker.wave.2"),
                        RotaryPosition(label: "HIGH", icon: "speaker.wave.3"),
                        RotaryPosition(label: "MAX", icon: "speaker.wave.3.fill")
                    ]
                    
                    HStack {
                        Image(systemName: positions[switchIndex].icon)
                            .font(.system(size: 30))
                        Text(positions[switchIndex].label)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to MED") {
                        withAnimation(.spring()) {
                            switchIndex = 2
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
                
                Divider()
                
                // ================================================
                // JOYSTICK DEMO
                // ================================================
                VStack(spacing: 20) {
                    Text("2D Joystick")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Joystick(position: $joystickPosition)
                    
                    // WHY: Show x,y coordinates and distance from center
                    VStack(spacing: 8) {
                        HStack(spacing: 20) {
                            VStack {
                                Text("X")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(String(format: "%.2f", joystickPosition.x))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack {
                                Text("Y")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(String(format: "%.2f", joystickPosition.y))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // WHY: Calculate distance from center
                        let distance = sqrt(
                            joystickPosition.x * joystickPosition.x +
                            joystickPosition.y * joystickPosition.y
                        )
                        
                        Text("Distance: \(String(format: "%.2f", distance))")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    Button("Reset to Center") {
                        withAnimation(.spring()) {
                            joystickPosition = .zero
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
            }
            .padding()
        }
        .background(Color(white: 0.9))
    }
}


// ============================================================================
// CUSTOMIZATION EXAMPLES
// ============================================================================
// These examples show how to customize each control for different use cases
// ============================================================================

struct CustomizationExamples: View {
    @State private var volume: Double = 0.5
    @State private var temperature: Double = 0.8
    @State private var driveMode: Int = 1
    @State private var cameraPosition: CGPoint = .zero
    
    var body: some View {
        ScrollView {
            VStack(spacing: 50) {
                // ================================================
                // EXAMPLE 1: Volume Control (Green Theme)
                // ================================================
                VStack(spacing: 15) {
                    Text("Volume Control")
                        .font(.headline)
                    
                    CircularFaderKnob(
                        value: $volume,
                        size: 180,
                        trackColor: .green.opacity(0.3),
                        activeTrackColor: .green,
                        indicatorColor: .green,
                        labelColor: .green.opacity(0.6),
                        gradientColors: [.gray, .black, .green.opacity(0.2)]
                    )
                    
                    Text("Volume: \(Int(volume * 100))%")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
                
                Divider()
                
                // ================================================
                // EXAMPLE 2: Temperature Slider (Blue to Red)
                // ================================================
                VStack(spacing: 15) {
                    Text("Temperature Control")
                        .font(.headline)
                    
                    LinearSlider(
                        value: $temperature,
                        width: 280,
                        activeTrackColors: [.blue, .orange, .red],
                        thumbBorderColor: temperature < 0.33 ? .blue : (temperature < 0.66 ? .orange : .red),
                        minLabel: "COLD",
                        maxLabel: "HOT",
                        valueFormatter: { value in
                            let temp = Int(value * 100)
                            return "\(temp)°"
                        }
                    )
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
                
                Divider()
                
                // ================================================
                // EXAMPLE 3: Drive Mode Switch (3 positions)
                // ================================================
                VStack(spacing: 15) {
                    Text("Drive Mode Selector")
                        .font(.headline)
                    
                    RotarySwitch(
                        selectedIndex: $driveMode,
                        positions: [
                            RotaryPosition(label: "ECO", icon: "leaf.fill"),
                            RotaryPosition(label: "NORMAL", icon: "car.fill"),
                            RotaryPosition(label: "SPORT", icon: "bolt.fill")
                        ],
                        size: 160,
                        backgroundColor: .black,
                        activeColor: .orange,
                        indicatorColor: .orange,
                        labelDistance: 45
                    )
                    
                    Text("Mode: \(["ECO", "NORMAL", "SPORT"][driveMode])")
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
                
                Divider()
                
                // ================================================
                // EXAMPLE 4: Camera Control Joystick (No Spring-Back)
                // ================================================
                VStack(spacing: 15) {
                    Text("Camera Pan/Tilt Control")
                        .font(.headline)
                    
                    Joystick(
                        position: $cameraPosition,
                        size: 180,
                        stickSize: 50,
                        baseColor: .blue.opacity(0.4),
                        stickColor: .blue,
                        deadZone: 0.15,
                        springBack: false // WHY: Camera stays at position
                    )
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("Pan")
                                .font(.caption)
                            Text(String(format: "%.2f", cameraPosition.x))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                        
                        VStack {
                            Text("Tilt")
                                .font(.caption)
                            Text(String(format: "%.2f", cameraPosition.y))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset Camera") {
                        withAnimation(.spring()) {
                            cameraPosition = .zero
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(20)
            }
            .padding()
        }
        .background(Color(white: 0.9))
    }
}


// ============================================================================
// PREVIEW PROVIDERS
// ============================================================================
// WHY: Previews allow quick testing in Xcode without running the app
// HOW: Each preview uses a StatefulPreviewWrapper to provide @State
// ============================================================================

struct CircularFaderKnob_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper()
    }
    
    struct StatefulPreviewWrapper: View {
        @State private var value: Double = 0.5
        
        var body: some View {
            VStack(spacing: 40) {
                CircularFaderKnob(value: $value)
                Text("\(Int(value * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
            }
            .padding()
            .background(Color(white: 0.1))
        }
    }
}

struct LinearSlider_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper()
    }
    
    struct StatefulPreviewWrapper: View {
        @State private var value: Double = 0.5
        
        var body: some View {
            VStack(spacing: 40) {
                LinearSlider(value: $value)
                Text("\(Int(value * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
            }
            .padding()
        }
    }
}

struct RotarySwitch_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper()
    }
    
    struct StatefulPreviewWrapper: View {
        @State private var index: Int = 2
        
        var body: some View {
            VStack(spacing: 40) {
                RotarySwitch(selectedIndex: $index)
                
                let positions = [
                    RotaryPosition(label: "OFF", icon: "power"),
                    RotaryPosition(label: "LOW", icon: "speaker.wave.1"),
                    RotaryPosition(label: "MED", icon: "speaker.wave.2"),
                    RotaryPosition(label: "HIGH", icon: "speaker.wave.3"),
                    RotaryPosition(label: "MAX", icon: "speaker.wave.3.fill")
                ]
                
                Text(positions[index].label)
                    .font(.system(size: 24, weight: .bold))
            }
            .padding()
        }
    }
}

struct Joystick_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper()
    }
    
    struct StatefulPreviewWrapper: View {
        @State private var position: CGPoint = .zero
        
        var body: some View {
            VStack(spacing: 40) {
                Joystick(position: $position)
                
                VStack {
                    Text("X: \(String(format: "%.2f", position.x))")
                    Text("Y: \(String(format: "%.2f", position.y))")
                }
                .font(.system(size: 18, design: .monospaced))
            }
            .padding()
        }
    }
}

struct ControlsDemo_Previews: PreviewProvider {
    static var previews: some View {
        ControlsDemoView()
    }
}

struct CustomizationExamples_Previews: PreviewProvider {
    static var previews: some View {
        CustomizationExamples()
    }
}


// ============================================================================
// USAGE NOTES AND BEST PRACTICES
// ============================================================================
//
// QUICK START:
// 1. Copy this entire file into your Xcode project
// 2. Import SwiftUI in your view file (already at top of this file)
// 3. Use any control with @State binding:
//
//    @State private var volume: Double = 0.5
//    CircularFaderKnob(value: $volume)
//
// DATA BINDING:
// - Always use @Binding in controls for two-way data flow
// - Parent view uses @State to own the data
// - Changes in control update parent automatically
// - Example:
//     struct MyView: View {
//         @State private var level: Double = 0.5
//         var body: some View {
//             CircularFaderKnob(value: $level) // $ creates binding
//         }
//     }
//
// PERFORMANCE:
// - Computed properties recalculate efficiently
// - Avoid @State inside controls (use @Binding instead)
// - Animations are optimized by SwiftUI
// - Controls handle 60fps smooth updates
//
// CUSTOMIZATION:
// - All color, size, and behavior properties can be customized
// - Look for properties marked with CUSTOMIZATION in comments
// - Create your own variants by changing default values
// - Example:
//     CircularFaderKnob(
//         value: $volume,
//         size: 250,
//         activeTrackColor: .green,
//         indicatorColor: .green
//     )
//
// GESTURE HANDLING:
// - DragGesture with minimumDistance: 0 for immediate response
// - Always clamp values to valid ranges (prevents crashes)
// - Use animations for smooth transitions
// - Gestures work on iOS, iPadOS, and macOS
//
// ACCESSIBILITY (Recommended Enhancements):
// - Add .accessibilityValue() to show current value
// - Add .accessibilityLabel() for screen readers
// - Add .accessibilityAdjustableAction() for VoiceOver adjustments
// - Test with VoiceOver enabled
// - Example:
//     CircularFaderKnob(value: $volume)
//         .accessibilityLabel("Volume")
//         .accessibilityValue("\(Int(volume * 100)) percent")
//
// HAPTIC FEEDBACK (Optional Enhancement):
// - Add UIImpactFeedbackGenerator for tactile feedback
// - Trigger on value changes or position snaps
// - Example in gesture handler:
//     let impact = UIImpactFeedbackGenerator(style: .light)
//     impact.impactOccurred()
//
// COMMON PATTERNS:
// - Circular controls: angle → value conversion using atan2
// - Linear controls: position → value (direct pixel mapping)
// - Snap controls: round to nearest discrete position
// - 2D controls: distance clamping for circular boundaries
//
// ANGLE MATH REFERENCE:
// - SwiftUI uses radians, we convert to degrees for readability
// - 0° = 3 o'clock (right), 90° = 6 o'clock (bottom)
// - atan2(y, x) returns angle from center to point
// - Use .rotationEffect() to rotate views around center
//
// COORDINATE SYSTEM:
// - Origin (0,0) is top-left corner
// - X increases to the right
// - Y increases downward
// - Center of circle is at (radius, radius)
//
// TROUBLESHOOTING:
// - If knob doesn't respond: Check @Binding is connected
// - If values jump: Check angle wraparound handling
// - If position is wrong: Verify center point calculations
// - If gestures conflict: Use .highPriorityGesture() modifier
//
// ADVANCED CUSTOMIZATIONS:
//
// 1. Add value snapping (quantize to steps):
//    In updateValue():
//    let steps = 10
//    value = round(newValue * Double(steps)) / Double(steps)
//
// 2. Add logarithmic scaling (for volume/frequency):
//    let logValue = pow(10, value * 2) / 100 // 0.01 to 1.0
//
// 3. Add bipolar mode (-1 to 1 with center at 0):
//    let bipolarValue = (value * 2) - 1
//
// 4. Add custom animations:
//    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
//
// 5. Add custom labels (replace +/-):
//    Change minLabel and maxLabel from Text to custom views
//
// LICENSE:
// This code is provided as-is for educational and commercial use.
// Free to use, modify, and distribute.
// No attribution required but appreciated.
//
// ============================================================================
