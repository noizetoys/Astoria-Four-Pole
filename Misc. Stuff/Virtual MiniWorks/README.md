# Virtual Waldorf 4 Pole Filter MIDI Device

A macOS application that simulates a Waldorf MiniWorks 4 Pole Filter hardware device for testing MIDI SysEx communication with your editor/librarian software.

## Features

- **MIDI Port Selection**: Choose input and output MIDI ports
- **20 Programs**: Pre-loaded with sample programs from your dump files
- **Parameter Editing**: View and modify all parameters for the current program
- **Global Settings**: Configure device ID, MIDI channel, and other global parameters
- **MIDI Monitor**: Real-time display of all incoming and outgoing MIDI messages
- **SysEx Support**: 
  - Program Dump (single program)
  - Program Bulk Dump
  - All Dump (all 20 programs + globals)
  - Automatic response to dump requests

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Project Setup

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project: **File → New → Project**
3. Choose **macOS → App**
4. Project settings:
   - Product Name: `VirtualMiniWorks`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Organization Identifier: `com.yourcompany` (your choice)

### 2. Add Project Files

Add all the Swift files to your project:

**Main Files:**
- `VirtualMiniWorksApp.swift` (replace the default ContentView.swift)
- `MIDIManager.swift`
- `VirtualDeviceState.swift`

**View Components:**
- `MIDIPortSelector.swift`
- `ProgramSelector.swift`
- `ParameterView.swift`
- `GlobalSettingsView.swift`
- `MIDIMonitorView.swift`

**Type Definitions (from your uploads):**
- `Continuous_Controller_Values.swift`
- `Global_Types.swift`
- `MiniWorks_Errors.swift`
- `MiniWorks_Parameters.swift`
- `Misc_Program_Types.swift`
- `Mod_Sources.swift`
- `SysEx_Constants.swift`
- `SysEx_Message_Types.swift`
- `Raw_Dumps.swift`

### 3. Configure Entitlements

1. Select your project in the navigator
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Audio Input** (required for CoreMIDI)

### 4. Update SysEx_Constants.swift

Update the `DEV` property to use a default value:

```swift
static var DEV: UInt8 { 0x01 }
```

Or create a simple UserDefaults wrapper:

```swift
class MiniWorksUserDefaults {
    static let shared = MiniWorksUserDefaults()
    var deviceID: UInt8 = 0x01
}
```

## Usage

### Starting the Application

1. Build and run the project (⌘R)
2. The virtual device window will appear

### Connecting MIDI Ports

1. **Input Port (Receive)**: Select the MIDI port that your editor/librarian sends to
2. **Output Port (Send)**: Select the MIDI port that your editor/librarian receives from
3. Click "Refresh Ports" if you don't see your MIDI devices

> **Tip**: You may need to create a virtual MIDI bus using **Audio MIDI Setup** (found in Applications/Utilities)

### Testing Your Editor/Librarian

#### Test 1: Request Program from Device
1. From your editor/librarian, send a Program Dump Request
2. Watch the MIDI Monitor (right panel) - you should see the request appear
3. The virtual device will automatically respond with the requested program
4. Your editor/librarian should receive and display the program

#### Test 2: Request All Programs
1. Send an All Dump Request from your editor/librarian
2. The virtual device will send all 20 programs plus global settings
3. Verify your editor/librarian correctly receives and parses the data

#### Test 3: Examine SysEx Messages
1. Select any message in the MIDI Monitor
2. View the hex bytes in the detail panel
3. See the decoded message structure (header, command, data, checksum)

### Working with Programs

- **Select Program**: Click any program button (1-20) to make it current
- **View Parameters**: Scroll through the Parameters section to see all settings
- **Edit Parameters**: Adjust sliders and pickers (changes are stored in memory only)
- **Send Program**: Click "Send Program" to send the current program via MIDI
- **Send All**: Click "Send All" to send all programs and globals

### Global Settings

Adjust device-wide settings:
- **Device ID**: 0-126 (must match your editor/librarian)
- **MIDI Channel**: Omni or 1-16
- **MIDI Control**: Off, CtR (Control), or CtS (Signal)
- **Knob Mode**: Jump or Relative
- **Startup Program**: Default program on boot
- **Note Number**: Used for keytracking

## MIDI Monitor

The right panel shows all MIDI traffic:

- **Green arrow down**: Received messages (requests from editor/librarian)
- **Blue arrow up**: Sent messages (responses from virtual device)
- **Filter tabs**: View All, Received only, or Sent only
- **Auto-scroll**: Automatically selects new messages
- **Clear**: Remove all messages from the log

### Message Detail

Select any message to see:
- Full timestamp
- Byte count
- Direction (In/Out)
- Complete hex dump (16 bytes per line)
- Decoded message structure

## Troubleshooting

### No MIDI Ports Visible
- Make sure your MIDI devices are connected
- Try clicking "Refresh Ports"
- Create a virtual MIDI bus in Audio MIDI Setup if testing on the same computer

### Messages Not Being Received
- Verify both input and output ports are selected
- Check that the device ID matches between the virtual device and your editor
- Ensure your editor is sending to the correct MIDI port

### Virtual Device Not Responding to Requests
- Check the MIDI Monitor to confirm requests are being received
- Verify the SysEx format matches the expected structure (F0 3E 04...)
- Ensure the device ID in the request matches the virtual device's ID

### Parameter Values Look Wrong
- Some parameters are bipolar (-64 to +63), displayed as 0-127 internally
- LFO Shape, Trigger Source/Mode have discrete values, not continuous ranges
- Check the MiniWorks documentation for the correct value mappings

## Architecture

### MIDIManager
- Handles all CoreMIDI operations
- Manages port connections
- Sends and receives SysEx messages
- Maintains message history for the monitor
- Automatically responds to dump requests

### VirtualDeviceState
- Stores all 20 programs and their parameters
- Manages global device settings
- Handles parameter updates
- Generates SysEx dumps on request
- Calculates checksums

### Views
- **ContentView**: Main app layout with split panels
- **MIDIPortSelector**: Port configuration
- **ProgramSelector**: Program switching and quick actions
- **ParameterView**: Parameter display and editing
- **GlobalSettingsView**: Device-wide settings
- **MIDIMonitorView**: Message logging and inspection

## License

This is a test utility for development purposes.

## Support

For issues or questions about the virtual device, check:
1. MIDI connections are established
2. Device IDs match
3. Messages appear in the MIDI Monitor
4. SysEx format is correct (check decoded view)
