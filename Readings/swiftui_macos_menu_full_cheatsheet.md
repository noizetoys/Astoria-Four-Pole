# SwiftUI macOS Menu Cheatsheet

Comprehensive reference for **creating, customizing, editing, and
dynamically modifying macOS menus in SwiftUI**.

------------------------------------------------------------------------

# 📐 Diagram: macOS Menu Architecture (High-Level)

    +---------------------------------------------------------------+
    |                       macOS Menu Bar                          |
    +---------------------------------------------------------------+
    | App | File | Edit | View | Window | Help | Custom Menus (...) |
    +---------------------------------------------------------------+

    App (AppName)
    ├── About
    ├── Preferences / Settings
    ├── Services
    ├── Hide / Quit
    │
    File
    ├── New
    ├── Open…
    ├── Save / Save As…
    ├── Custom (After Save) ← CommandGroup(after: .saveItem)
    │
    Edit
    ├── Undo / Redo
    ├── Cut / Copy / Paste
    ├── Custom Replacements
    │
    View
    ├── Sidebar
    ├── Toolbar
    ├── Zoom
    ├── Custom View Actions
    │
    Window
    ├── Minimize
    ├── Zoom
    ├── Arrange Windows
    │
    Help
    └── Search

    Custom Menus (User-Defined)
    ├── Tools
    │   ├── SubTools
    │   │   ├── Deep Tools
    │   │   └── Utilities
    │   └── Toggles
    │
    └── Developer
        ├── Diagnostics
        ├── Toggles
        └── Optional Children

------------------------------------------------------------------------

# 🧰 SwiftUI Commands: Overview

SwiftUI menus are created/modified using:

-   `Commands`
-   `CommandMenu`
-   `CommandGroup`
-   `CommandGroupPlacement`
-   `MenuBarExtra`
-   `Menu` (view-level)
-   `contextMenu`

------------------------------------------------------------------------

# 1️⃣ Creating Custom Menus in the macOS Menu Bar

``` swift
struct ToolsCommands: Commands {
    @State private var enabled = true

    var body: some Commands {
        CommandMenu("Tools") {
            Button("Run Tool") { print("Running Tool") }

            Toggle("Enable Feature", isOn: $enabled)

            Divider()

            Button("Quit Tools") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
```

Register:

``` swift
.commands {
    ToolsCommands()
}
```

------------------------------------------------------------------------

# 2️⃣ Nested Menus

``` swift
struct NestedCommands: Commands {
    var body: some Commands {
        CommandMenu("Utilities") {
            Menu("Converters") {
                Button("JSON → XML") {}
                Button("XML → JSON") {}

                Menu("Advanced") {
                    Button("Lossless Merge") {}
                    Button("Pretty Print") {}
                }
            }
        }
    }
}
```

------------------------------------------------------------------------

# 3️⃣ Editing / Replacing System Menus

## Replace "About This App"

``` swift
.commands {
    CommandGroup(replacing: .appInfo) {
        Button("About MyApp…") { showAboutWindow() }
    }
}
```

## Insert after "Save"

``` swift
.commands {
    CommandGroup(after: .saveItem) {
        Button("Export…") {}
    }
}
```

## Remove a system-defined group

``` swift
.commandsRemoved {
    CommandGroupPlacement.textFormatting
}
```

Removes the entire **Format** menu.

------------------------------------------------------------------------

# 4️⃣ Adding Items to the Menu Bar (MenuBarExtra)

For macOS 13+:

``` swift
@main
struct MyApp: App {
    var body: some Scene {
        MenuBarExtra("Monitor", systemImage: "gauge") {
            Button("Refresh") {}
            Divider()
            Toggle("Auto Refresh", isOn: .constant(true))
        }
        .menuBarExtraStyle(.window)
    }
}
```

------------------------------------------------------------------------

# 5️⃣ Application Menus Using `Menu` View (Inside App UI)

Not in macOS menu bar, but useful inside toolbars or popovers.

``` swift
Menu("Options") {
    Button("Start") {}
    Button("Stop") {}
    Divider()
    Toggle("Loop", isOn: .constant(true))
}
```

Nested:

``` swift
Menu("Settings") {
    Menu("Theme") {
        Button("Light") {}
        Button("Dark") {}
    }
}
```

------------------------------------------------------------------------

# 6️⃣ Context Menus (Right-Click)

``` swift
Text("Right-click me")
    .contextMenu {
        Button("Copy") {}
        Button("Delete") {}
        Menu("Advanced") {
            Button("View Info") {}
        }
    }
```

------------------------------------------------------------------------

# 7️⃣ Dynamic Menu Items (Add/Remove at Runtime)

``` swift
struct DynamicCommands: Commands {
    @State private var showDebug = false

    var body: some Commands {
        CommandMenu("Debug") {

            Toggle("Show Debug Menu", isOn: $showDebug)

            if showDebug {
                Button("Dump State") {}
                Button("Reset Cache") {}
            }
        }
    }
}
```

------------------------------------------------------------------------

# 8️⃣ Enable / Disable Items Dynamically

``` swift
Button("Export") {}
    .disabled(project.items.isEmpty)
```

------------------------------------------------------------------------

# 9️⃣ Keyboard Shortcuts

``` swift
Button("Save") {}
    .keyboardShortcut("s", modifiers: .command)
```

Function key:

``` swift
Button("Toggle Panel") {}
    .keyboardShortcut(.f2, modifiers: [.command])
```

------------------------------------------------------------------------

# 🔟 Full Custom Menu Example

``` swift
struct AppMenuCommands: Commands {
    @AppStorage("isDarkMode") private var darkMode = false
    @State private var showAdvanced = false

    var body: some Commands {

        // Replace About Menu
        CommandGroup(replacing: .appInfo) {
            Button("About Pro Editor…") { }
        }

        // Custom File Tools Menu
        CommandMenu("File Tools") {
            Button("Import…") {}
            Button("Export…") {}

            Menu("Recent Files") {
                Button("ProjectA") {}
                Button("ProjectB") {}
            }
        }

        // Developer Menu
        CommandMenu("Developer") {
            Toggle("Show Advanced", isOn: $showAdvanced)

            if showAdvanced {
                Menu("Diagnostics") {
                    Button("Dump Memory") {}
                    Button("Run Benchmark") {}
                }

                Divider()

                Button("Clear Logs") {}
            }
        }

        // Add new item after standard Save
        CommandGroup(after: .saveItem) {
            Button("Save All") {}
        }
    }
}
```

------------------------------------------------------------------------

# 1️⃣1️⃣ Removing Entire System Menus

Remove Format menu:

``` swift
.commandsRemoved {
    CommandGroupPlacement.textFormatting
}
```

Remove Window arrangement menu:

``` swift
.commands {
    CommandGroup(replacing: .windowArrangement) { }
}
```

------------------------------------------------------------------------

# 📘 Summary Table

  -------------------------------------------------------------------------------------
  Feature                   API                          Example
  ------------------------- ---------------------------- ------------------------------
  Add new top-level menu    `CommandMenu`                `CommandMenu("Tools") { … }`

  Add items to existing     `CommandGroup(after:)`       After Save
  group                                                  

  Replace system menu       `CommandGroup(replacing:)`   Replace appInfo
  section                                                

  Remove system menu        `commandsRemoved`            Remove textFormatting

  Menu bar extra            `MenuBarExtra`               Status-bar menu

  Nested menu               `Menu`                       Children menus

  Dynamic items             SwiftUI conditions           `if showAdvanced { … }`
  -------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 🎉 End of Cheatsheet

This document consolidates all examples, diagrams, and instructions for
manipulating macOS menus using SwiftUI.
