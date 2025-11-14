# Virtual MiniWorks - Project Checklist

Use this checklist to ensure everything is set up correctly.

## ✅ Initial Setup

- [ ] Xcode is installed (version 15.0 or later)
- [ ] Created new macOS App project
- [ ] Project name is "VirtualMiniWorks"
- [ ] Interface is set to SwiftUI
- [ ] Language is set to Swift

## ✅ File Organization

### Main Application Files
- [ ] VirtualMiniWorksApp.swift (main app and ContentView)
- [ ] MIDIManager.swift
- [ ] VirtualDeviceState.swift

### View Components
- [ ] MIDIPortSelector.swift
- [ ] ProgramSelector.swift
- [ ] ParameterView.swift
- [ ] GlobalSettingsView.swift
- [ ] MIDIMonitorView.swift

### Type Definitions
- [ ] Continuous_Controller_Values.swift
- [ ] Global_Types.swift
- [ ] MiniWorks_Errors.swift
- [ ] MiniWorks_Parameters.swift
- [ ] Misc_Program_Types.swift
- [ ] Mod_Sources.swift
- [ ] SysEx_Constants.swift
- [ ] SysEx_Message_Types.swift
- [ ] Raw_Dumps.swift

### Documentation
- [ ] README.md
- [ ] QUICKSTART.md
- [ ] This checklist (CHECKLIST.md)

## ✅ Project Configuration

- [ ] Deleted default ContentView.swift
- [ ] All Swift files added to project target
- [ ] Build succeeds with no errors
- [ ] Deployment target set to macOS 13.0 or later

## ✅ MIDI Setup (for testing)

- [ ] Audio MIDI Setup opened
- [ ] IAC Driver enabled (if testing on same machine)
- [ ] Virtual MIDI bus created (if needed)
- [ ] Know which ports to connect to

## ✅ First Run

- [ ] App builds and runs (⌘R)
- [ ] Window appears with all panels
- [ ] No console errors or warnings
- [ ] MIDI ports appear in dropdowns
- [ ] All 20 programs visible

## ✅ Basic Functionality

- [ ] Can select input MIDI port
- [ ] Can select output MIDI port
- [ ] Can switch between programs
- [ ] Parameters update when switching programs
- [ ] Can adjust parameter sliders
- [ ] Can modify global settings

## ✅ MIDI Communication

- [ ] MIDI Monitor shows received messages
- [ ] MIDI Monitor shows sent messages
- [ ] Can send single program dump
- [ ] Can send all programs dump
- [ ] Device responds to dump requests
- [ ] Message details show hex data
- [ ] Message details show decoded info

## ✅ Testing with Editor/Librarian

- [ ] Editor can connect to virtual device
- [ ] Can request single program from editor
- [ ] Virtual device sends correct response
- [ ] Editor receives and displays program
- [ ] Can request all programs from editor
- [ ] Editor receives all 20 programs
- [ ] Device ID matching works correctly

## 🐛 Known Limitations

Things that are NOT part of this virtual device:
- ⚠️ Real-time MIDI CC messages (only SysEx)
- ⚠️ Actual audio processing
- ⚠️ Saving/loading from files
- ⚠️ MIDI learn functionality
- ⚠️ Program name editing
- ⚠️ Undo/redo
- ⚠️ Preset library management

## 📝 Notes

Space for your own notes:

_______________________________________________

_______________________________________________

_______________________________________________

_______________________________________________

## 🎉 Success!

When all items are checked:
✨ Your Virtual MiniWorks device is fully operational!

You can now:
- Test your editor/librarian thoroughly
- Debug SysEx communication issues  
- Verify parameter parsing
- Examine message structure
- Develop without physical hardware

---

**Questions or Issues?**
See README.md for detailed troubleshooting and architecture info.
