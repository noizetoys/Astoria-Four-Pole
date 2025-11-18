//
//  PatchDragDropWithViewModel.swift
//
//  LEFT:  Grid of "patch" tiles (rounded rects with numbers).
//         - Tap to load patch into editor.
//         - Drag to drop onto editor.
//
//  RIGHT: Editor column that:
//         - Always accepts drops anywhere in the column
//         - Shows current patch parameters
//         - If a patch is already being edited, shows an alert
//           with 4 options when a new patch is dropped:
//
//           1. Save to device
//           2. Save to buffer
//           3. Discard data (throw away changes, then load new patch)
//           4. Cancel drop (keep editing existing patch)
//
//  This file is designed to be understandable and editable by someone
//  with limited SwiftUI experience.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine


// MARK: - Model: Patch / Program

/// Represents a single "patch" or "program" in your editor/librarian.
///
/// In a real project, this would likely be backed by SysEx and contain
/// many more fields. Here we only include three parameters.
struct Patch: Identifiable, Hashable, Codable {
    let id: UUID
    let programNumber: Int
    var name: String
    var cutoff: Double
    var resonance: Double
    var envelopeAmount: Double
    
    init(
        programNumber: Int,
        name: String,
        cutoff: Double,
        resonance: Double,
        envelopeAmount: Double
    ) {
        self.id = UUID()
        self.programNumber = programNumber
        self.name = name
        self.cutoff = cutoff
        self.resonance = resonance
        self.envelopeAmount = envelopeAmount
    }
}

// MARK: - ViewModel

/// Owns all patch-related state and logic.
///
/// - Holds the patch bank (`patches`)
/// - Tracks the patch currently loaded in the editor (`currentPatch`)
/// - Handles drops of new patch numbers
/// - Manages alert state and what to do when a new patch is dropped
///   while another patch is being edited.
final class PatchEditorViewModel: ObservableObject {
    
    /// All available patches.
    @Published var patches: [Patch]
    
    /// The patch currently being edited in the right-hand editor.
    @Published var currentPatch: Patch?
    
    /// When a new patch is dropped while `currentPatch` is non-nil,
    /// we remember its program number here until the user decides
    /// what to do via the alert.
    @Published var pendingDropProgramNumber: Int?
    
    /// Whether the "patch dropped" alert is visible.
    @Published var showDropAlert: Bool = false
    
    init(patches: [Patch] = Patch.samplePatches) {
        self.patches = patches
        self.currentPatch = nil
    }
    
    // MARK: - Lookup helper
    
    /// Return the patch with a given program number, if any.
    func patch(forProgramNumber number: Int) -> Patch? {
        patches.first(where: { $0.programNumber == number })
    }
    
    // MARK: - Drop handling entry point
    
    /// Called by the editor column when a patch number is dropped there.
    func handleDrop(programNumber: Int) {
        // Case 1: No patch currently being edited → just load new one.
        guard currentPatch != nil else {
            loadPatch(programNumber: programNumber)
            return
        }
        
        // Case 2: A patch *is* being edited → remember the dropped number
        // and show alert to ask the user what to do.
        pendingDropProgramNumber = programNumber
        showDropAlert = true
    }
    
    /// Actually load a patch into the editor.
    private func loadPatch(programNumber: Int) {
        currentPatch = patch(forProgramNumber: programNumber)
    }
    
    // MARK: - Alert options
    
    /// The possible user choices when dropping a new patch onto an existing one.
    enum DropResolution {
        case saveToDevice
        case saveToBuffer
        case discardData   // throw away changes to existing patch; load new one
        case cancelDrop    // keep editing existing patch; ignore new patch
    }
    
    /// Handle the user's decision from the alert.
    ///
    ///  - For `saveToDevice` / `saveToBuffer`:
    ///       you would send data to the device here, then load the new patch.
    ///  - For `discardData`:
    ///       we skip saving, but still load the new patch.
    ///  - For `cancelDrop`:
    ///       we do nothing and keep editing the current patch.
    func handleDropResolution(_ resolution: DropResolution) {
        // If there is no pending drop, nothing to do.
        guard let pendingNumber = pendingDropProgramNumber else {
            showDropAlert = false
            return
        }
        
        switch resolution {
            case .saveToDevice:
                if let current = currentPatch {
                    // TODO: Implement SysEx / MIDI write to device here.
                    print("DEBUG: Save current patch #\(current.programNumber) to DEVICE")
                }
                // After saving, we load the new patch.
                loadPatch(programNumber: pendingNumber)
                clearPendingDrop()
                
            case .saveToBuffer:
                if let current = currentPatch {
                    // TODO: Implement "buffer" save (temporary location) here.
                    print("DEBUG: Save current patch #\(current.programNumber) to BUFFER")
                }
                loadPatch(programNumber: pendingNumber)
                clearPendingDrop()
                
            case .discardData:
                // We *do not* save the existing patch anywhere.
                // We simply load the new pending patch.
                loadPatch(programNumber: pendingNumber)
                clearPendingDrop()
                
            case .cancelDrop:
                // Ignore the pending drop and keep editing the current patch.
                clearPendingDrop()
        }
    }
    
    /// Reset pending drop state and hide the alert.
    private func clearPendingDrop() {
        pendingDropProgramNumber = nil
        showDropAlert = false
    }
    
    // MARK: - Editing
    
    /// Update the currently edited patch with new parameter values.
    ///
    /// This is called whenever the sliders in the editor move.
    func updateCurrentPatch(_ updated: Patch) {
        currentPatch = updated
        
        // Keep the patches array in sync as well (so the bank reflects edits).
        if let index = patches.firstIndex(where: { $0.programNumber == updated.programNumber }) {
            patches[index] = updated
        }
    }
}

// MARK: - Root View

/// Root view used as the app entry point.
///
/// - Owns the ViewModel (`@StateObject`)
/// - Lays out the left palette and right editor column
/// - Presents the drop-resolution alert
struct PatchEditorRootView: View {
    
    @StateObject private var viewModel = PatchEditorViewModel()
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 16) {
                
                // LEFT: Palette of patches
                PatchPaletteView(viewModel: viewModel)
                    .frame(maxWidth: 280)
                    .padding()
                
                // RIGHT: Editor column (drop zone + editor)
                PatchEditorColumnView(viewModel: viewModel)
                    .padding()
            }
            .navigationTitle("Patch Drag & Drop Demo")
            // ALERT: Shown when a new patch is dropped onto an existing one.
            .alert(
                "Load New Patch?",
                isPresented: $viewModel.showDropAlert
            ) {
                Button("Save to Device") {
                    viewModel.handleDropResolution(.saveToDevice)
                }
                Button("Save to Buffer") {
                    viewModel.handleDropResolution(.saveToBuffer)
                }
                Button("Discard Data") {
                    viewModel.handleDropResolution(.discardData)
                }
                Button("Cancel Drop", role: .cancel) {
                    viewModel.handleDropResolution(.cancelDrop)
                }
            } message: {
                if let current = viewModel.currentPatch,
                   let pending = viewModel.pendingDropProgramNumber {
                    Text("""
                    You are currently editing program #\(current.programNumber) (\(current.name)).
                    A new patch (#\(pending)) was dropped.
                    
                    What would you like to do with the current patch before loading the new one?
                    """)
                } else {
                    Text("A new patch was dropped while a patch was being edited.")
                }
            }
        }
    }
}

// MARK: - LEFT SIDE: Palette

/// Left-hand palette that shows all patches and supports drag + tap.
struct PatchPaletteView: View {
    
    @ObservedObject var viewModel: PatchEditorViewModel
    
    // Simple layout customization
    private let columnCount: Int = 3
    private let paletteBackgroundColor: Color = Color.gray.opacity(0.15)
    private let paletteBorderColor: Color = Color.gray
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patches")
                .font(.headline)
            
            Text("Drag a patch into the editor on the right, or tap to load it.")
                .font(.caption)
                .foregroundColor(.gray)
            
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(paletteBorderColor, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(paletteBackgroundColor)
                )
                .overlay(
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(viewModel.patches) { patch in
                                PatchCellView(patch: patch)
                                    .onTapGesture {
                                        // Simple tap: just load this patch into the editor.
                                        viewModel.currentPatch = patch
                                    }
                                // DRAG SOURCE:
                                // We drag a String with the patch's program number, e.g. "7".
                                // This is extremely simple & robust across platforms.
                                    .onDrag {
                                        let text = "\(patch.programNumber)"
                                        return NSItemProvider(object: NSString(string: text))
                                    }
                            }
                        }
                        .padding(8)
                    }
                )
        }
    }
}

/// Single rounded-rect patch tile showing program number and name.
struct PatchCellView: View {
    
    let patch: Patch
    
    // Visual tweaks
    private let cornerRadius: CGFloat = 12
    private let minHeight: CGFloat = 50
    private let showsShadow: Bool = true
    
    var body: some View {
        VStack(spacing: 4) {
            Text("#\(patch.programNumber)")
                .font(.headline)
                .foregroundColor(.black)
            Text(patch.name)
                .font(.caption2)
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
                .shadow(radius: showsShadow ? 1 : 0, x: 0, y: showsShadow ? 1 : 0)
        )
    }
}

// MARK: - RIGHT SIDE: Editor Column

/// Right-hand editor column.
///
/// Key behavior:
/// - The **entire column** is a drop target (`.onDrop(of: [.plainText], ...)`)
/// - If no patch is loaded, dropping loads it immediately.
/// - If a patch is already loaded, the ViewModel shows an alert asking what to do.
/// - Contents (placeholder vs. editor) do not affect the drop zone; it always works.
struct PatchEditorColumnView: View {
    @ObservedObject var viewModel: PatchEditorViewModel
    @State private var isDropTargeted: Bool = false
    
    private let cornerRadius: CGFloat = 20
    private let editorBackgroundColor: Color = Color.white
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(editorBackgroundColor)
                    .shadow(radius: 3)
                
                VStack(spacing: 16) {
                    Text("Editor")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    if let current = viewModel.currentPatch {
                        // Pass a Binding<Patch> into the editor
                        PatchEditorView(
                            patch: Binding(
                                get: { viewModel.currentPatch ?? current },
                                set: { newValue in
                                    viewModel.updateCurrentPatch(newValue)
                                }
                            )
                        )
                    } else {
                        VStack(spacing: 8) {
                            Text("Drop a Patch Here")
                                .font(.title2)
                                .foregroundColor(.black)
                            Text("Drag a patch from the left and drop it anywhere in this area to load its values.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                .padding()
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isDropTargeted ? Color.blue : Color.gray,
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onDrop(of: [.plainText], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers: providers)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }
        
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let string = object as? String,
                  let programNumber = Int(string) else { return }
            
            DispatchQueue.main.async {
                viewModel.handleDrop(programNumber: programNumber)
            }
        }
        
        return true
    }
}

// MARK: - Patch Editor Controls

/// Actual patch editor view with sliders.
///
/// This view:
/// - Does NOT know about the ViewModel directly (keeps it reusable).
// BEFORE:
// struct PatchEditorView: View {
//     @State private var patch: Patch

// AFTER:
struct PatchEditorView: View {
    @Binding var patch: Patch
    // no local @State copy now
    
    private let midiRange: ClosedRange<Double> = 0...127
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Program #\(patch.programNumber)")
                        .font(.title3)
                        .foregroundColor(.black)
                    Text(patch.name)
                        .font(.headline)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                ParameterSliderRow(
                    title: "Cutoff",
                    value: $patch.cutoff,
                    range: midiRange,
                    unit: "0–127"
                )
                
                ParameterSliderRow(
                    title: "Resonance",
                    value: $patch.resonance,
                    range: midiRange,
                    unit: "0–127"
                )
                
                ParameterSliderRow(
                    title: "Env Amt",
                    value: $patch.envelopeAmount,
                    range: midiRange,
                    unit: "0–127"
                )
            }
            
            Spacer()
        }
    }
}

/// Small reusable "label + slider + numeric value" row.
struct ParameterSliderRow: View {
    
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    private let showsValueLabel: Bool = true
    private let decimalPlaces: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                Spacer()
                
                if showsValueLabel {
                    Text(formattedValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Slider(value: $value, in: range)
        }
    }
    
    private var formattedValue: String {
        if decimalPlaces == 0 {
            return "\(Int(value)) (\(unit))"
        } else {
            let format = "%.\(decimalPlaces)f"
            let string = String(format: format, value)
            return "\(string) (\(unit))"
        }
    }
}

// MARK: - Sample Data

extension Patch {
    static let samplePatches: [Patch] = (1...16).map { index in
        Patch(
            programNumber: index,
            name: "Patch \(index)",
            cutoff: Double.random(in: 0...127),
            resonance: Double.random(in: 0...127),
            envelopeAmount: Double.random(in: 0...127)
        )
    }
}

// MARK: - Preview

struct PatchEditorRootView_Previews: PreviewProvider {
    static var previews: some View {
        PatchEditorRootView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
