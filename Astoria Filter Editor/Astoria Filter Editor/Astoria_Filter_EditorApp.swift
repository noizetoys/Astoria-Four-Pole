//
//  Astoria_Filter_EditorApp.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/8/25.
//

import SwiftUI

@main
struct Astoria_Filter_EditorApp: App {
    @State private var deviceProfile = MiniworksDeviceProfile.newMachineConfiguration()
    @State private var showingFileManager = false
    
    
    var body: some Scene {
        WindowGroup {
            MainView(deviceProfile: $deviceProfile)
                .sheet(isPresented: $showingFileManager) {
                    FileManagerView(deviceProfile: $deviceProfile)
                        .frame(minWidth: 900, minHeight: 600)
                }
        }
        .commands {
//            fileManagerCommands
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
            }
            
            CommandGroup(after: CommandGroupPlacement.newItem) {
                Button("New Program") {
                    
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("New Profile") {
                    
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Divider()
                
                Menu("Import/Export") {
                    Button("Import Patch") {
                        
                    }
                    
                    Button("Import Profile") {
                        
                    }
                    
                    Button("Export Patch") {
                        
                    }
                    
                    Button("Export Profile") {
                        
                    }
                }
                
            }
            

        }
        .defaultSize(CGSize(width: 1200, height: 800))
    }
    
    
        // MARK: - Menu Commands
    
    private var fileManagerCommands: some Commands {
        CommandMenu("File Manager") {
            Button("Open File Manager...") {
                showingFileManager = true
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            
            
            Divider()
            
            
            Button("Quick Save") {
                Task {
                    await quickSave()
                }
            }
            .keyboardShortcut("s", modifiers: [.command])
            
            
            Button("Create Backup") {
                Task {
                    await createBackup()
                }
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
        }
    }
    
    
    // MARK: - Quick Actions
    
    private func quickSave() async {
        let fileManager = MiniworksFileManager.shared
        let name = "QuickSave_\(Date().timeIntervalSince1970)"
        
        try? await fileManager.saveProfile(deviceProfile, name: name)
    }
    
    
    private func createBackup() async {
        let fileManager = MiniworksFileManager.shared
        
        let _ = try? await fileManager.createBackup(of: deviceProfile)
    }
}
