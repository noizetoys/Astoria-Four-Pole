import SwiftUI

    // ======================================================================
    // MARK: - WidthPreferenceKey
    // ======================================================================
    //
    // This PreferenceKey is used to "push" the width of the ADSR editor view
    // up the view tree. SwiftUI normally lays out views top-down, but
    // PreferenceKeys allow information (like geometry values) to flow
    // upward.
    //
    // We will use this to:
    // 1. Measure the width of the ADSR editor.
    // 2. Apply that exact width to the control HStack below it.
    // 3. Divide that width into 4 equal columns so controls align perfectly.
    //
    // The PreferenceKey stores a single CGFloat (the measured width).
    //
struct WidthPreferenceKey: PreferenceKey {
    
        /// Default value if nothing has been set.
    static var defaultValue: CGFloat = 0
    
        /// Combine values when multiple children update the same key.
        /// Here we take the max, though in this case there will only be one value.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}



    // ======================================================================
    // MARK: - ADSR Sections Enum
    // ======================================================================
    //
    // Represents the four traditional ADSR envelope segments. These are
    // used to generate four control columns and maintain a predictable,
    // type-safe structure.
    //
enum ADSRSection: CaseIterable {
    case attack, decay, sustain, release
    
        /// User-visible label for UI
    var label: String {
        switch self {
            case .attack:  return "Attack"
            case .decay:   return "Decay"
            case .sustain: return "Sustain"
            case .release: return "Release"
        }
    }
}



    // ======================================================================
    // MARK: - Placeholder ADSR Editor View
    // ======================================================================
    //
    // In your real app, this will be replaced by the ADSR envelope editor.
    // This view’s width is what we capture using a GeometryReader.
    //
struct ADSREditorView: View {
    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.2))
            .frame(height: 200)
            .overlay(Text("ADSR Editor"))
            .cornerRadius(12)
    }
}



    // ======================================================================
    // MARK: - Placeholder Knob Control
    // ======================================================================
    //
    // Replace with your actual rotary knob view.
    // This placeholder is simply to demonstrate layout.
    //
struct KnobView: View {
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(Text("●"))
    }
}



    // ======================================================================
    // MARK: - ADSR Control Column
    // ======================================================================
    //
    // A single vertical column of controls corresponding to one ADSR segment.
    // Each column contains:
    //   - Top label (e.g., "Attack")
    //   - Knob
    //   - Value label
    //
    // The important part is `.frame(maxWidth: .infinity)` which ensures that
    // the contents are centered within their allocated slice of the HStack.
    //
struct ADSRControlColumn: View {
    let section: ADSRSection
    
    var body: some View {
        VStack(spacing: 12) {
            Text(section.label)
            KnobView()
            Text("Value")
        }
        .frame(maxWidth: .infinity)   // centers content in each slice
    }
}



    // ======================================================================
    // MARK: - Main ADSRPage Layout
    // ======================================================================
    //
    // This view contains two major components:
    //
    //   1. The ADSR editor (large rectangle)
    //   2. The ADSR controls (4 evenly aligned columns)
    //
    // The challenge:
    // ----------------
    // We want the controls HStack to be EXACTLY the same width as the
    // ADSR editor above it. SwiftUI normally lets widths expand to fill
    // space, so without explicit measurement, the two views might not align.
    //
    // The solution:
    // ----------------
    // - Use a GeometryReader inside a background to measure the ADSR
    //   editor’s width.
    // - Pass that width upward using WidthPreferenceKey.
    // - Store it in @State (editorWidth).
    // - Apply that exact width to the controls layout.
    // - Divide that width into 4 equal slices.
    //
    // Result:
    // ----------------
    // The four control columns are centered perfectly under the four
    // conceptual ADSR sections, regardless of device size or dynamic layout.
    //
struct ADSRPage: View {
    
        /// Stores the live-updated width of the ADSR editor.
    @State private var editorWidth: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) {
            
                // -------------------------------------------------------------
                // ADSR EDITOR (measured using GeometryReader)
                // -------------------------------------------------------------
            ADSREditorView()
                .background(
                    GeometryReader { geo in
                            // Push the measured width upward via the preference key.
                        Color.clear.preference(
                            key: WidthPreferenceKey.self,
                            value: geo.size.width
                        )
                    }
                )
                .onPreferenceChange(WidthPreferenceKey.self) { width in
                        // Capture the updated width so we can apply it below.
                    editorWidth = width
                }
            
            
                // -------------------------------------------------------------
                // ADSR CONTROLS (aligned to ADSR editor width)
                // -------------------------------------------------------------
            HStack(spacing: 0) {
                ForEach(ADSRSection.allCases, id: \.self) { section in
                    
                    ADSRControlColumn(section: section)
                        // Each control column receives an exact quarter width
                        // of the ADSR editor.
                        .frame(width: editorWidth / 4)
                }
            }
                // The entire controls section gets the exact same width as the editor.
            .frame(width: editorWidth)
        }
        .padding()
    }
}



    // ======================================================================
    // MARK: - Preview
    // ======================================================================

#Preview {
    ADSRPage()
}
