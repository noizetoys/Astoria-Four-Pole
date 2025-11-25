import SwiftUI
import SwiftData

@main
struct PatchManagerEnhancedApp: App {
    @State private var viewModel = PatchLibraryViewModel()
    
    var body: some Scene {
        WindowGroup {
            PatchLibraryView(viewModel: viewModel)
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    // Load data on startup
                }
                .onDisappear {
                    // Save data on quit
                    viewModel.saveAll()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Configuration") {
                    // Trigger new configuration
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button("Save Configuration") {
                    viewModel.saveCurrentConfiguration()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(viewModel.currentConfiguration == nil)
                
                Divider()
                
                Button("Undo") {
                    viewModel.undoManager.undo(viewModel: viewModel)
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!viewModel.undoManager.canUndo)
                
                Button("Redo") {
                    viewModel.undoManager.redo(viewModel: viewModel)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!viewModel.undoManager.canRedo)
            }
            
            CommandGroup(after: .importExport) {
                Button("Export Patches...") {
                    // Show export dialog
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Export Configuration...") {
                    // Show export dialog
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(viewModel.currentConfiguration == nil)
                
                Button("Import...") {
                    // Show import dialog
                }
                .keyboardShortcut("i", modifiers: .command)
            }
        }
    }
}
