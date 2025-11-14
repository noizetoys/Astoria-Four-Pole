# 🎹 Virtual Waldorf 4 Pole Filter MIDI Device

**A complete macOS application for testing MIDI SysEx communication with your MiniWorks editor/librarian**

---

## 📦 What's Inside

This package contains everything you need to create a virtual MiniWorks 4 Pole Filter device:

- **17 Swift source files** - Complete working application
- **4 documentation files** - Setup guides and reference
- **2 resource files** - Helper scripts and configuration

## 🚀 Quick Start (5 minutes)

1. **Open Xcode** and create a new macOS App project
2. **Name it** "VirtualMiniWorks" 
3. **Delete** the default ContentView.swift
4. **Add all files** from the `Source/` folder to your project
5. **Build and run** (⌘R)

**👉 For step-by-step instructions, see:** `Documentation/QUICKSTART.md`

## 📂 Project Structure

```
VirtualMiniWorksProject/
├── Source/                          # All Swift source code (17 files)
│   ├── VirtualMiniWorksApp.swift   # Main app and UI
│   ├── MIDIManager.swift            # CoreMIDI handling
│   ├── VirtualDeviceState.swift    # Device state management
│   ├── [View components].swift      # UI components (5 files)
│   └── [Type definitions].swift     # Data types (9 files)
│
├── Documentation/                   # Guides and reference
│   ├── QUICKSTART.md               # ⭐ Start here!
│   ├── README.md                    # Complete documentation
│   ├── CHECKLIST.md                # Setup verification
│   └── PROJECT_OVERVIEW.md         # Architecture and design
│
└── Resources/                       # Helpers and config
    ├── setup.sh                     # Optional setup script
    └── Info.plist                   # App configuration
```

## ✨ What This Does

This virtual device:

✅ **Responds to SysEx requests** from your editor/librarian  
✅ **Sends properly formatted dumps** with correct checksums  
✅ **Shows all MIDI traffic** in real-time  
✅ **Displays 20 programs** with full parameter sets  
✅ **Allows parameter editing** and inspection  
✅ **Requires no physical hardware** to test your software  

## 🎯 Perfect For

- **Testing** your MiniWorks editor/librarian
- **Debugging** SysEx communication
- **Learning** CoreMIDI and SysEx protocols
- **Developing** without physical hardware

## 📖 Documentation Guide

Read these in order:

1. **QUICKSTART.md** - Get running in 5 minutes
2. **CHECKLIST.md** - Verify everything works
3. **README.md** - Full feature documentation
4. **PROJECT_OVERVIEW.md** - Architecture deep-dive

## 🔧 Requirements

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+
- Swift 5.9+

## 💡 First Time Setup

### Option 1: Manual Setup (Recommended)
Follow the instructions in `Documentation/QUICKSTART.md`

### Option 2: Helper Script
```bash
cd Resources
./setup.sh
```
Then follow the on-screen instructions.

## 🎮 What You Can Do

Once running, you can:

- **Select MIDI ports** to connect to your editor
- **Choose from 20 programs** pre-loaded from your sample dumps
- **View and edit parameters** (envelopes, LFO, filter, etc.)
- **Monitor MIDI traffic** with hex dump and decoded view
- **Send program dumps** individually or all at once
- **Respond automatically** to dump requests from your editor

## 🐛 Testing Your Editor/Librarian

1. Connect the virtual device to your editor's MIDI ports
2. Send a "Request Program" command from your editor
3. Watch the MIDI Monitor panel
4. Verify your editor receives and parses the response correctly

The virtual device automatically responds to all MiniWorks SysEx request types!

## 🎨 Screenshots

**Main Interface:**
- Left panel: Device controls (ports, programs, parameters, globals)
- Right panel: MIDI monitor (message list and detail view)

**MIDI Monitor Features:**
- Color-coded message direction (green=received, blue=sent)
- Full hex dump display
- Decoded message structure
- Timestamp information
- Filter by direction

## 🎓 Learning Resources

This project demonstrates:
- CoreMIDI port management
- SysEx message parsing and generation
- Checksum calculation
- Observable objects in SwiftUI
- Split-panel layouts
- Real-time data display

## ⚡ Key Features

### MIDI Communication
- Automatic port discovery
- Request/response handling
- Message history (last 100)
- Real-time monitoring

### Device Emulation
- 20 pre-loaded programs
- All 29 parameters per program
- Global device settings
- Proper checksum calculation

### Developer Tools
- Hex byte inspection
- Message decoding
- Timestamp tracking
- Direction filtering

## 🤝 Support

Having issues? Check:

1. **CHECKLIST.md** - Is everything set up correctly?
2. **README.md** - Troubleshooting section
3. MIDI Monitor panel - Are messages being received?
4. Device ID - Does it match your editor?

## 📝 Notes

- This is a **testing tool**, not a full synthesizer emulator
- No audio processing - only MIDI communication
- No file save/load (uses sample data from Raw_Dumps.swift)
- Changes to parameters are stored in memory only

## 🎉 Ready to Start?

**👉 Open:** `Documentation/QUICKSTART.md`

---

**Questions?** All documentation is in the `Documentation/` folder.

**Happy testing!** 🎹✨
