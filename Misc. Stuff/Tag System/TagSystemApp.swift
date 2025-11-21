import SwiftUI

@main
struct TagSystemApp: App {
    var body: some Scene {
        WindowGroup {
            TagSystemView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
