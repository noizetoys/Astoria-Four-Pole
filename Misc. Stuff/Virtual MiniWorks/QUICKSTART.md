# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Create the Xcode Project

1. Open **Xcode**
2. **File → New → Project**
3. Select **macOS → App**
4. Fill in:
   - **Product Name**: `VirtualMiniWorks`
   - **Interface**: SwiftUI
   - **Language**: Swift
5. Click **Next** and choose where to save

### Step 2: Add the Files

1. **Delete** the default `ContentView.swift` file
2. Drag all `.swift` files from this package into your project
3. Make sure "Copy items if needed" is checked
4. Click **Finish**

### Step 3: Build and Run

1. Press **⌘R** (or click the Play button)
2. The Virtual MiniWorks window will open

### Step 4: Connect MIDI

#### Option A: Testing with Your Editor on the Same Mac

1. Open **Audio MIDI Setup** (in /Applications/Utilities)
2. Go to **Window → Show MIDI Studio**
3. Double-click **IAC Driver**
4. Check **"Device is online"**
5. You should see a "Bus 1" port

In Virtual MiniWorks:
- **Input Port**: Select your editor's MIDI output
- **Output Port**: Select your editor's MIDI input

#### Option B: Testing with External Hardware/Software

Just select the appropriate MIDI ports in the Virtual MiniWorks app.

### Step 5: Test Communication

1. In your editor/librarian, send a **Request Program** command
2. Watch the **MIDI Monitor** panel in Virtual MiniWorks
3. You should see:
   - The request appear (green arrow down)
   - The response being sent (blue arrow up)
4. Your editor should receive and display the program

## 📊 What Each Panel Does

### Left Panel: Device Controls

**MIDI Ports**
- Connect to your editor/librarian

**Program Selection**
- Choose which of the 20 programs is active
- Send current program or all programs

**Parameters**
- View/edit all parameters for current program
- Envelopes, LFO, Filter, etc.

**Global Settings**
- Device ID (must match your editor)
- MIDI channel
- Other device-wide settings

### Right Panel: MIDI Monitor

**Message List**
- Shows all MIDI traffic
- Green = Received (from your editor)
- Blue = Sent (to your editor)

**Message Detail**
- Click any message to see:
  - Full hex dump
  - Decoded structure
  - Timestamp

## 🎯 Common Test Scenarios

### Test 1: Single Program Request
1. Select Program 12 in Virtual MiniWorks
2. From your editor, request Program 12
3. Verify your editor receives the correct data

### Test 2: All Programs Request
1. From your editor, request "All Dump"
2. Check that your editor receives all 20 programs
3. Verify global settings are correct

### Test 3: Parameter Editing
1. Change the Cutoff parameter in Virtual MiniWorks
2. Send the program to your editor
3. Verify the editor shows the new value

### Test 4: Message Inspection
1. Send any request from your editor
2. Click the request in MIDI Monitor
3. Examine the hex bytes and decoded structure
4. Verify format matches specifications

## ❓ Quick Troubleshooting

**"No MIDI ports visible"**
→ Click "Refresh Ports" or check Audio MIDI Setup

**"Messages not being received"**
→ Verify Device ID matches between virtual device and editor

**"Editor doesn't receive response"**
→ Check that Output Port is selected correctly

**"Wrong program sent"**
→ Make sure the current program matches the request

## 📖 Need More Help?

See the full **README.md** for:
- Detailed architecture explanation
- Advanced troubleshooting
- Parameter value mappings
- Complete feature list

---

**Tip**: Keep both Virtual MiniWorks and your editor/librarian visible on screen so you can watch the MIDI communication in real-time!
