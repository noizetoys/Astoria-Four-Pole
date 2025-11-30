/*
 * MIDI Monitor Application
 *
 * A real-time MIDI monitoring tool that visualizes Control Change (CC) values
 * and Note On/Off events on a scrolling graph.
 *
 * MIDI Protocol:
 * - Uses MIDI 2.0 Universal MIDI Packet (UMP) format
 * - Supports MIDIEventList for modern packet handling
 * - Backward compatible with MIDI 1.0 messages via UMP translation
 *
 * Key Features:
 * - Real-time CC value visualization (continuous cyan line)
 * - Note velocity display (red dots at velocity value)
 * - Note event position markers (orange dots on CC line)
 * - Configurable CC number, Note number, and Note type
 * - MIDI device selection
 *
 * Architecture:
 * - MIDIManager: Handles CoreMIDI communication and device management (MIDI 2.0 UMP)
 * - GraphViewModel: Manages data points and timing for the graph
 * - MIDIGraphView: Renders the scrolling graph using SwiftUI Canvas
 * - ContentView: Main UI with graph and controls
 * - SettingsView: Configuration panel for MIDI parameters
 */

import SwiftUI
import CoreMIDI
import Combine

    // MARK: - MIDI Device Model

/**
 * Represents a MIDI input device.
 *
 * Properties:
 * - id: The CoreMIDI endpoint reference (MIDIEndpointRef)
 * - name: Human-readable name of the MIDI device
 *
 * Used for device selection in the Settings panel.
 */
struct MIDIDevice: Identifiable, Hashable {
    let id: MIDIEndpointRef
    let name: String
}









#Preview {
    ContentView()
}

    // MARK: - App Entry Point

/**
 * MIDIMonitorApp - Application entry point
 *
 * Defines the app structure and main window.
 *
 * Window Configuration:
 * - Minimum size: 800x500 pixels
 * - Content: ContentView (main interface)
 * - Resizable: Yes (inherits from WindowGroup)
 *
 * To run the app:
 * 1. Build and run in Xcode (Cmd+R)
 * 2. Or: Build for release and run standalone
 */
//@main
//struct MIDIMonitorApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .frame(minWidth: 800, minHeight: 500)
//        }
//    }
//}

/*
 * TROUBLESHOOTING GUIDE
 * =====================
 *
 * MIDI 2.0 UMP IMPLEMENTATION
 * - This app uses Universal MIDI Packet (UMP) format
 * - Supports both MIDI 1.0 and MIDI 2.0 messages
 * - Console output shows which protocol is being used ([MIDI 1.0] or [MIDI 2.0])
 *
 * PROBLEM: Not seeing note velocity dots (red dots)
 * SOLUTION:
 * 1. Check console output for "🎵 Note ON" or "🎵 Note OFF" messages
 *    - If you see these messages with [MIDI 1.0] or [MIDI 2.0], reception works
 *    - If not, check device connection and settings
 *
 * 2. Verify noteType setting matches your MIDI device:
 *    - Some devices send Note Off messages
 *    - Some devices send Note On with velocity 0 instead
 *    - Set noteType to .both to capture everything
 *
 * 3. Monitor the correct note:
 *    - Verify monitoredNote matches the note you're playing
 *    - Use Settings to change the monitored note number
 *
 * 4. Debug rendering:
 *    - Check console for "🔴 Drew X note markers" messages
 *    - If this appears, rendering is working
 *    - If not, check that dataPoints have hasNote=true and noteValue set
 *
 * PROBLEM: No MIDI data at all (CC or notes)
 * SOLUTION:
 * 1. Check device connection:
 *    - Open Settings and verify device appears in list
 *    - Click "Refresh Devices" if needed
 *
 * 2. Check device selection:
 *    - Make sure correct device is selected
 *    - Try "All Devices" to monitor all sources
 *
 * 3. Verify MIDI messages:
 *    - Use another MIDI app (MIDI Monitor) to confirm device sends data
 *    - Check that CC and note numbers match your configuration
 *
 * 4. Check console output:
 *    - Look for "🎚️ CC" messages for Control Changes
 *    - Look for "🎵 Note" messages for note events
 *    - Console shows [MIDI 1.0] or [MIDI 2.0] to indicate protocol
 *    - If you don't see these, MIDI is not being received
 *
 * PROBLEM: Graph not scrolling
 * SOLUTION:
 * 1. Check that GraphViewModel timer is running
 *    - Console should show "📊 Starting graph data collection"
 * 2. Verify MIDI data is being received (check header values)
 * 3. Check that dataPoints array is being updated
 *
 * DEBUGGING TIPS:
 * ===============
 *
 * Enable verbose UMP logging:
 * - In handleUMPPacket(), uncomment the print statement:
 *   print("📨 UMP: type=\(messageType) word0=\(String(format: "0x%08X", word0))")
 *
 * This will show ALL incoming UMP packets, useful for:
 * - Identifying which protocol your device uses (MIDI 1.0 vs 2.0)
 * - Verifying message format and packet structure
 * - Checking note numbers and CC numbers
 * - Seeing raw 32-bit word values
 *
 * Understanding UMP Types:
 * - Type 2 (0x2): MIDI 1.0 Channel Voice (32-bit packets)
 * - Type 4 (0x4): MIDI 2.0 Channel Voice (64-bit packets)
 *
 * Console output guide:
 * - 🔍 Device scanning
 * - 📱 Device found
 * - ✅ Connection status
 * - 🎹 MIDI setup (shows MIDI 2.0 UMP)
 * - 🎛️  Device selection
 * - 🎚️  CC value received (shows [MIDI 1.0] or [MIDI 2.0])
 * - 🎵 Note event received (shows [MIDI 1.0] or [MIDI 2.0])
 * - 📊 Graph lifecycle
 * - 📍 Note event detection
 * - 🎨 Graph rendering
 * - 🔴 Note markers drawn
 * - 🧹 Cleanup
 */
