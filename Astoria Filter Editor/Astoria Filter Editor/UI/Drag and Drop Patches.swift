
import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - Patch Model

/// Represents a single "patch" or "program" in the editor librarian.
///
/// In a real project, this would be backed by SysEx and contain many more
/// parameters. For this demo we keep three parameters and a program number.
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

// MARK: - View Model

/// View model that owns all patch-related state and logic.
///
/// Responsibilities:
/// - Hold the patch bank (`patches`)
/// - Track the patch currently being edited (`currentPatch`)
/// - Track the "original" version of the current patch for undo/revert
/// - Maintain undo/redo stacks per loaded patch
/// - Handle patch selection and unsaved-change confirmation
/// - Handle drag/drop loading of patches
final class PatchEditorViewModel: ObservableObject {
    
    /// All patches in the bank.
    @Published var patches: [Patch]
    
    /// The patch currently loaded into the editor on the right.
    @Published var currentPatch: Patch?
    
    /// Snapshot of the patch as it was when first loaded into the editor.
    /// Used to detect if the user has made edits (for undo/revert prompts).
    private var originalPatch: Patch?
    
    // Undo/Redo history for the currently loaded patch.
    private var undoStack: [Patch] = []
    private var redoStack: [Patch] = []
    
    // MARK: - Unsaved changes when selecting/dropping a new patch
    
    /// Whether the "unsaved changes" alert is visible.
    @Published var showUnsavedSelectionAlert: Bool = false
    
    /// The program number of the patch the user is trying to switch *to*
    /// (by tap, double-tap, or drop) when there are unsaved changes.
    @Published var pendingSelectionProgramNumber: Int? = nil
    
    // Computed helper: whether currentPatch differs from originalPatch.
    var hasUnsavedChanges: Bool {
        guard let current = currentPatch, let original = originalPatch else {
            return false
        }
        return current != original
    }
    
    // Computed helpers for enabling/disabling Undo/Redo buttons.
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    // MARK: - Initialization
    
    init(patches: [Patch] = Patch.samplePatches) {
        self.patches = patches
        self.currentPatch = nil
    }
    
    // MARK: - Lookup
    
    /// Find a patch with a given program number.
    func patch(forProgramNumber number: Int) -> Patch? {
        patches.first(where: { $0.programNumber == number })
    }
    
    // MARK: - Core loading logic
    
    /// Load the patch with the given program number into the editor,
    /// and take a snapshot as the "original" for undo/revert.
    /// Also resets undo/redo history for the newly loaded patch.
    private func loadPatch(programNumber: Int) {
        guard let new = patch(forProgramNumber: programNumber) else { return }
        currentPatch = new
        originalPatch = new
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    // MARK: - Selection (tap / double-click / drop) with unsaved changes
    
    /// Called when the user *requests* loading a patch (via tap, double-tap,
    /// or drop). This method decides whether to:
    /// - switch immediately (no edits), or
    /// - show an "unsaved changes" alert (if edited).
    func userRequestedLoadPatch(programNumber: Int) {
        // If there is no current patch, just load it.
        guard hasUnsavedChanges else {
            loadPatch(programNumber: programNumber)
            return
        }
        
        // There ARE edits: remember the target program and show alert.
        pendingSelectionProgramNumber = programNumber
        showUnsavedSelectionAlert = true
    }
    
    // MARK: - Editing the current patch
    
    /// Update the currently edited patch with new parameter values.
    /// Called by the editor view when sliders move.
    func updateCurrentPatch(_ updated: Patch) {
        // If we have a previous value, record it in the undo stack.
        if let current = currentPatch, updated != current {
            undoStack.append(current)
            // Any new edit invalidates the redo history.
            redoStack.removeAll()
        }
        
        currentPatch = updated
        
        // Keep the bank in sync so the user can see edits reflected in the array.
        if let index = patches.firstIndex(where: { $0.programNumber == updated.programNumber }) {
            patches[index] = updated
        }
    }
    
    // MARK: - Undo / Redo
    
    /// Undo the last edit to the current patch, if possible.
    func undo() {
        guard let current = currentPatch, let last = undoStack.popLast() else {
            return
        }
        // Move the current state to the redo stack,
        // then restore the previous state.
        redoStack.append(current)
        currentPatch = last
        
        if let index = patches.firstIndex(where: { $0.programNumber == last.programNumber }) {
            patches[index] = last
        }
    }
    
    /// Redo the last undone edit to the current patch, if possible.
    func redo() {
        guard let current = currentPatch, let next = redoStack.popLast() else {
            return
        }
        // Move the current state onto the undo stack,
        // then restore the redone state.
        undoStack.append(current)
        currentPatch = next
        
        if let index = patches.firstIndex(where: { $0.programNumber == next.programNumber }) {
            patches[index] = next
        }
    }
    
    // MARK: - Unsaved-changes resolution
    
    /// Possible choices when the user tries to load another patch while
    /// the current patch has been edited.
    enum UnsavedSelectionResolution {
        case saveChanges       // overwrite existing patch in bank, then switch
        case saveAsNewPatch    // duplicate edited patch into a new slot, then switch to target
        case discardChanges    // revert to original, then switch
        case exportToFile      // export edited patch to a file, then switch
        case cancel            // keep editing current patch; do not switch
    }
    
    /// Handle the user's choice from the unsaved-changes alert.
    func handleUnsavedSelectionResolution(_ resolution: UnsavedSelectionResolution) {
        guard let targetProgram = pendingSelectionProgramNumber else {
            showUnsavedSelectionAlert = false
            return
        }
        
        switch resolution {
            case .saveChanges:
                // Overwrite the current patch in the bank with the edited values.
                if let current = currentPatch,
                   let idx = patches.firstIndex(where: { $0.programNumber == current.programNumber }) {
                    patches[idx] = current
                    // The edited state becomes the new "original".
                    originalPatch = current
                    // TODO: Persist to file or device here if desired.
                }
                // Now switch to the requested patch.
                loadPatch(programNumber: targetProgram)
                
            case .saveAsNewPatch:
                if let current = currentPatch {
                    // Create a copy with a new program number at the end of the bank.
                    let nextProgramNumber = (patches.map { $0.programNumber }.max() ?? 0) + 1
                    let newPatch = Patch(
                        programNumber: nextProgramNumber,
                        name: current.name + " (Copy)",
                        cutoff: current.cutoff,
                        resonance: current.resonance,
                        envelopeAmount: current.envelopeAmount
                    )
                    patches.append(newPatch)
                    print("DEBUG: Saved edited patch as new program #\(nextProgramNumber)")
                }
                // After saving-as-new, switch to the requested target patch.
                loadPatch(programNumber: targetProgram)
                
            case .discardChanges:
                // Throw away any edits by restoring original into the bank.
                if let original = originalPatch,
                   let idx = patches.firstIndex(where: { $0.programNumber == original.programNumber }) {
                    patches[idx] = original
                }
                // Then switch to the requested patch.
                loadPatch(programNumber: targetProgram)
                
            case .exportToFile:
                if let current = currentPatch {
                    // TODO: Implement file export (SysEx, JSON, etc.) here.
                    // For now we just print a debug message.
                    print("DEBUG: Export edited patch #\(current.programNumber) to file")
                }
                // After exporting, still proceed to switch to the requested patch.
                loadPatch(programNumber: targetProgram)
                
            case .cancel:
                // Do nothing: keep editing the current patch.
                break
        }
        
        // Clear pending selection + alert in all cases.
        pendingSelectionProgramNumber = nil
        showUnsavedSelectionAlert = false
    }
    
    // MARK: - Drag & Drop Loading
    
    /// Called when a patch number is dropped onto the editor column.
    ///
    /// We reuse the same unsaved-changes logic as selection by calling
    /// `userRequestedLoadPatch(programNumber:)`.
    func handleDrop(programNumber: Int) {
        userRequestedLoadPatch(programNumber: programNumber)
    }
}

// MARK: - Root View

/// Root view: owns the view model, lays out palette + editor, presents alerts.
struct PatchEditorRootView: View {
    
    @StateObject private var viewModel = PatchEditorViewModel()
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 16) {
                // LEFT: Palette of patches
                PatchPaletteView(viewModel: viewModel)
                    .frame(maxWidth: 280)
                    .padding()
                
                // RIGHT: Editor column with drop zone
                PatchEditorColumnView(viewModel: viewModel)
                    .padding()
            }
            .navigationTitle("Patch Drag & Drop Demo")
            // Alert for unsaved changes when selecting/dropping a different patch.
            .alert(
                "Unsaved Changes",
                isPresented: $viewModel.showUnsavedSelectionAlert
            ) {
                Button("Save Changes") {
                    viewModel.handleUnsavedSelectionResolution(.saveChanges)
                }
                Button("Save as New Patch") {
                    viewModel.handleUnsavedSelectionResolution(.saveAsNewPatch)
                }
                Button("Discard Changes") {
                    viewModel.handleUnsavedSelectionResolution(.discardChanges)
                }
                Button("Export to File") {
                    viewModel.handleUnsavedSelectionResolution(.exportToFile)
                }
                Button("Cancel", role: .cancel) {
                    viewModel.handleUnsavedSelectionResolution(.cancel)
                }
            } message: {
                if let current = viewModel.currentPatch,
                   let pending = viewModel.pendingSelectionProgramNumber {
                    Text("""
                    You have unsaved changes on program #\(current.programNumber) (\(current.name)).
                    You are trying to switch to program #\(pending).
                    
                    What would you like to do?
                    """)
                } else {
                    Text("You have unsaved changes. What would you like to do?")
                }
            }
        }
    }
}

// MARK: - LEFT SIDE: Palette

/// Left-hand palette that shows all patches and supports drag + tap / double-tap.
struct PatchPaletteView: View {
    
    @ObservedObject var viewModel: PatchEditorViewModel
    
    // Layout customization
    private let columnCount: Int = 4
    private let paletteBackgroundColor: Color = Color.gray.opacity(0.15)
    private let paletteBorderColor: Color = Color.gray
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patches")
                .font(.headline)
            
            Text("Drag a patch into the editor on the right, or tap/double-tap to load it.")
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
                                // Double-tap / double-click to request load via ViewModel.
                                    .onTapGesture(count: 2) {
                                        viewModel.userRequestedLoadPatch(programNumber: patch.programNumber)
                                    }
                                // Optional: single tap also requests load (can remove if you want only double-tap).
                                    .onTapGesture {
                                        viewModel.userRequestedLoadPatch(programNumber: patch.programNumber)
                                    }
                                // Drag: send program number as plain text.
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

/// Right-hand editor column that always accepts drops anywhere in the area,
/// and exposes Undo/Redo buttons at the top.
struct PatchEditorColumnView: View {
    
    @ObservedObject var viewModel: PatchEditorViewModel
    
    /// Used to visually indicate when something is being dragged over the column.
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
                    // Header row: title + Undo/Redo buttons.
                    HStack {
                        Text("Editor")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("Undo") {
                            viewModel.undo()
                        }
                        .disabled(!viewModel.canUndo)
                        
                        Button("Redo") {
                            viewModel.redo()
                        }
                        .disabled(!viewModel.canRedo)
                    }
                    
                    if let current = viewModel.currentPatch {
                        // Bind directly into the view model's currentPatch.
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
            // Single drop zone for the entire editor column.
            .onDrop(of: [UTType.plainText], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers: providers)
            }
        }
    }
    
    /// Convert dropped data into a program number and forward to ViewModel.
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard
            let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) })
        else {
            return false
        }
        
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let string = object as? String,
                  let programNumber = Int(string) else {
                return
            }
            
            DispatchQueue.main.async {
                viewModel.handleDrop(programNumber: programNumber)
            }
        }
        
        return true
    }
}

// MARK: - Patch Editor Controls

/// Editor for a single patch, bound directly into the ViewModel's `currentPatch`.
struct PatchEditorView: View {
    
    @Binding var patch: Patch
    
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

/// Simple "label + slider + numeric value" row.
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
