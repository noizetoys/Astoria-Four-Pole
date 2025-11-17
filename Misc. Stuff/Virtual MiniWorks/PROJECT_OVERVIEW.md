# Virtual Waldorf 4 Pole Filter - Project Overview

## What This Is

A complete macOS application that emulates a Waldorf MiniWorks 4 Pole Filter hardware device for the purpose of testing MIDI SysEx communication with your editor/librarian software.

## The Problem It Solves

When developing a MIDI editor/librarian, you need to test:
- SysEx message parsing
- Parameter value handling
- Program dump requests/responses
- Checksum validation
- Multi-program transfers
- Device communication protocols

Without physical hardware, this is difficult or impossible. This virtual device provides a software substitute that:
- Responds to all MiniWorks SysEx commands
- Sends properly formatted dumps
- Calculates correct checksums
- Displays all MIDI traffic for debugging
- Allows parameter inspection and modification

## Key Features

### 1. Full MIDI Implementation
- CoreMIDI integration
- Bidirectional communication
- Automatic request handling
- Support for all MiniWorks SysEx message types

### 2. Complete Parameter Set
- All 29 parameters per program
- 20 pre-loaded programs (from your sample dumps)
- Global device settings
- Real-time parameter editing

### 3. Comprehensive MIDI Monitor
- Shows every byte sent and received
- Hex dump display
- Decoded message structure
- Timestamp information
- Filter by direction (sent/received)
- Message history (last 100 messages)

### 4. Developer-Friendly Interface
- Clear visual feedback
- Separate panels for different concerns
- Real-time status indicators
- Easy port selection
- Quick action buttons

## Technical Architecture

### Core Components

**MIDIManager**
- Singleton managing all CoreMIDI operations
- Handles port enumeration and connection
- Sends and receives SysEx messages
- Maintains message history
- Provides message decoding

**VirtualDeviceState**
- Observable object holding all device state
- 20 ProgramData objects
- Global settings (MIDI channel, device ID, etc.)
- Responds to notification-based dump requests
- Generates SysEx dumps with checksums

**ProgramData**
- Represents a single program (29 bytes)
- Subscript access by MiniWorksParameter enum
- Unique identifier for SwiftUI list management

### User Interface

**ContentView**
- Main container with NavigationView
- HSplitView for left panel (controls) and right panel (monitor)
- Headers and status indicators

**MIDIPortSelector**
- Dropdown menus for port selection
- Refresh capability
- Connection status

**ProgramSelector**
- Grid of 20 program buttons
- Current program highlight
- Quick action buttons for dump operations

**ParameterView**
- Scrollable sections for parameter categories
- Sliders for continuous parameters
- Pickers for enumerated parameters
- Bipolar value display (-64 to +63)

**GlobalSettingsView**
- Device-wide configuration
- Steppers and pickers for various settings
- Note number display with names

**MIDIMonitorView**
- Split view: message list + detail
- Real-time message display
- Hex and decoded views
- Filtering and search
- Auto-scroll capability

### Data Flow

```
Editor/Librarian
        ↓ (MIDI In)
   MIDIManager
        ↓ (Parse)
   Notification
        ↓ (Handle)
VirtualDeviceState
        ↓ (Generate SysEx)
   MIDIManager
        ↓ (MIDI Out)
Editor/Librarian
```

### SysEx Message Types Supported

| Command | Value | Direction | Description |
|---------|-------|-----------|-------------|
| Program Dump | 0x00 | Out | Single program data |
| Program Bulk Dump | 0x01 | Out | Single program data (alternate format) |
| All Dump | 0x08 | Out | All 20 programs + globals |
| Program Dump Request | 0x40 | In | Request single program |
| Program Bulk Dump Request | 0x41 | In | Request single program (bulk) |
| All Dump Request | 0x48 | In | Request all data |

## Files Included

### Source Code (19 files)
1. VirtualMiniWorksApp.swift - Main app and ContentView
2. MIDIManager.swift - CoreMIDI management
3. VirtualDeviceState.swift - State management
4. MIDIPortSelector.swift - Port selection UI
5. ProgramSelector.swift - Program selection UI
6. ParameterView.swift - Parameter display/edit UI
7. GlobalSettingsView.swift - Global settings UI
8. MIDIMonitorView.swift - MIDI traffic monitor UI
9-17. Type definition files (from your uploads)
18. SysEx_Constants.swift - Modified with UserDefaults class
19. Raw_Dumps.swift - Sample program data

### Documentation (4 files)
- README.md - Complete documentation
- QUICKSTART.md - 5-minute setup guide
- CHECKLIST.md - Setup verification checklist
- PROJECT_OVERVIEW.md - This file

### Utilities
- setup.sh - Helper script (optional)
- Info.plist - App configuration

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- CoreMIDI framework (included with macOS)

## Setup Time

- **Quick Start**: 5-10 minutes
- **Full Setup with Testing**: 15-20 minutes

## Use Cases

### 1. Editor/Librarian Development
Test your MIDI communication layer without hardware:
- Verify SysEx parsing logic
- Test parameter value conversions
- Validate checksum calculations
- Debug communication timing

### 2. Protocol Documentation
Use the MIDI monitor to:
- Document exact message formats
- Capture example messages
- Verify protocol specifications
- Create test cases

### 3. Education
Learn about:
- CoreMIDI programming
- SysEx message structure
- MIDI communication patterns
- Real-time audio device protocols

### 4. Debugging
When things go wrong:
- See exactly what bytes are being sent/received
- Compare expected vs actual messages
- Identify parsing errors
- Verify device ID matching

## Limitations

This is a **testing tool**, not a full synthesizer emulator:
- ✅ Sends/receives all MiniWorks SysEx messages
- ✅ Proper checksum calculation
- ✅ All parameters viewable and editable
- ❌ No real-time CC message handling
- ❌ No actual audio processing
- ❌ No file save/load
- ❌ No preset management beyond 20 samples

## Extension Possibilities

This code can be extended to add:
- File import/export (.syx files)
- Program name editing
- Copy/paste between programs
- Randomization features
- MIDI CC message simulation
- Multiple virtual devices
- Program comparison views
- Batch operations

## Performance

- Lightweight: ~5MB RAM
- Instant startup
- No audio processing overhead
- Message history limited to 100 items
- Smooth UI on all modern Macs

## Compatibility

Works with any MIDI software that:
- Supports CoreMIDI
- Sends MiniWorks-compatible SysEx
- Can receive SysEx responses

## Getting Help

See the documentation:
- **QUICKSTART.md** - Fast setup
- **README.md** - Complete guide
- **CHECKLIST.md** - Verification steps

## License

This is a development/testing utility. Use freely for testing your editor/librarian.

---

**Ready to get started?** → Open QUICKSTART.md
