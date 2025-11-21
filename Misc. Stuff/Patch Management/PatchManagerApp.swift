import SwiftUI

@main
struct PatchManagerApp: App {
    var body: some Scene {
        WindowGroup {
            PatchLibraryView()
                .frame(minWidth: 1200, minHeight: 800)
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
                    // Trigger save
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}
