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

    // MARK: - Note Type Enum

/**
 * Defines which type of MIDI note messages to monitor.
 *
 * Cases:
 * - noteOn: Only monitor Note On messages (0x90-0x9F)
 * - noteOff: Only monitor Note Off messages (0x80-0x8F)
 * - both: Monitor both Note On and Note Off messages
 *
 * Note: Some MIDI devices send Note On with velocity 0 instead of Note Off.
 * This is handled automatically in the MIDI packet parser.
 */
enum NoteType: String, CaseIterable, Identifiable {
    case noteOn = "Note On"
    case noteOff = "Note Off"
    case both = "Both"
    
    var id: String { rawValue }
}

    // MARK: - MIDI Manager

/**
 * MIDIManager - Handles all MIDI input and device management using MIDI 2.0 UMP
 *
 * MIDI 2.0 Implementation:
 * - Uses MIDIEventList instead of MIDIPacketList
 * - Processes Universal MIDI Packets (UMP)
 * - Supports both MIDI 1.0 and MIDI 2.0 messages through UMP format
 *
 * Responsibilities:
 * 1. Manages CoreMIDI client and input port (MIDI 2.0 protocol)
 * 2. Discovers and tracks available MIDI devices
 * 3. Handles device selection (specific device or all devices)
 * 4. Parses incoming MIDI UMP packets
 * 5. Filters messages based on monitored CC/note
 * 6. Publishes CC and Note values to the UI
 *
 * Published Properties (Observable by SwiftUI):
 * - ccValue: Current value of the monitored Control Change (0-127)
 * - noteValue: Current velocity of the monitored note (0-127)
 * - availableDevices: List of connected MIDI input devices
 * - selectedDevice: Currently selected MIDI device (nil = all devices)
 *
 * Configuration Properties:
 * - monitoredCC: Which CC number to monitor (default: 2 = Breath Control)
 * - monitoredNote: Which note to monitor (default: 48 = C3)
 * - noteType: Which note messages to capture (.noteOn, .noteOff, .both)
 *
 * UMP Format Support:
 * - MIDI 1.0 Channel Voice Messages (Type 2): 32-bit packets
 * - MIDI 2.0 Channel Voice Messages (Type 4): 64-bit packets
 * - Automatic scaling of MIDI 2.0 16-bit values to MIDI 1.0 7-bit range
 *
 * Usage:
 * 1. Initialize: MIDIManager automatically sets up MIDI and discovers devices
 * 2. Configure: Set monitoredCC, monitoredNote, noteType as needed
 * 3. Select Device: Call selectDevice() or connectToAllDevices()
 * 4. Observe: SwiftUI views can observe ccValue and noteValue changes
 */
class MIDIManager: ObservableObject {
        // MARK: Published Properties
    
        /// Current value of the monitored Control Change (0-127)
    @Published var ccValue: UInt8 = 0
    
        /// Current velocity value of the monitored note (0-127)
        /// Updates when Note On/Off occurs (based on noteType setting)
    @Published var noteValue: UInt8 = 0
    
        /// List of all available MIDI input devices
    @Published var availableDevices: [MIDIDevice] = []
    
        /// Currently selected MIDI device (nil = monitoring all devices)
    @Published var selectedDevice: MIDIDevice?
    
        // MARK: Configuration Properties
    
        /// Which Control Change number to monitor (0-127)
        /// Default: 2 (Breath Control)
    var monitoredCC: UInt8 = 2
    
        /// Which note number to monitor (0-127)
        /// Default: 48 (C3)
    var monitoredNote: UInt8 = 48
    
        /// Which type of note messages to monitor
        /// Options: .noteOn, .noteOff, .both
    var noteType: NoteType = .noteOn
    
        // MARK: Private CoreMIDI Properties
    
        /// CoreMIDI client reference
    private var midiClient = MIDIClientRef()
    
        /// CoreMIDI input port reference (configured for MIDI 2.0 UMP protocol)
    private var inputPort = MIDIPortRef()
    
        /// Set of currently connected MIDI source endpoints
    private var connectedSources: Set<MIDIEndpointRef> = []
    
        // MARK: Initialization
    
    /**
     * Initializes the MIDI manager with MIDI 2.0 UMP support.
     *
     * Automatically:
     * 1. Sets up CoreMIDI client and input port (MIDI 2.0 protocol)
     * 2. Discovers available MIDI devices
     * 3. Auto-selects first device if available
     */
    init() {
        setupMIDI()
        refreshDevices()
    }
    
        // MARK: Device Management
    
    /**
     * Refreshes the list of available MIDI input devices.
     *
     * This method:
     * 1. Queries CoreMIDI for all available sources
     * 2. Retrieves device names
     * 3. Updates the availableDevices array
     * 4. Auto-selects first device if none is currently selected
     *
     * Call this when:
     * - A new MIDI device is connected
     * - User clicks "Refresh Devices" button
     * - Notification received that MIDI setup changed
     */
    func refreshDevices() {
        var devices: [MIDIDevice] = []
        let sourceCount = MIDIGetNumberOfSources()
        
        print("🔍 Scanning for MIDI devices... Found \(sourceCount) sources")
        
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            var nameRef: Unmanaged<CFString>?
            let status = MIDIObjectGetStringProperty(source, kMIDIPropertyName, &nameRef)
            
            if status == noErr, let nameRef = nameRef {
                let name = nameRef.takeRetainedValue() as String
                devices.append(MIDIDevice(id: source, name: name))
                print("  📱 Found device: \(name)")
            }
        }
        
        DispatchQueue.main.async {
            self.availableDevices = devices
            
                // Auto-select first device if none selected
            if self.selectedDevice == nil && !devices.isEmpty {
                print("  ✅ Auto-selecting: \(devices[0].name)")
                self.selectDevice(devices[0])
            }
        }
    }
    
    /**
     * Selects a specific MIDI device for monitoring.
     *
     * Parameters:
     * - device: The MIDIDevice to monitor, or nil to disconnect
     *
     * This method:
     * 1. Disconnects all currently connected sources
     * 2. Connects to the specified device
     * 3. Updates selectedDevice property
     *
     * To monitor all devices, call connectToAllDevices() instead.
     */
    func selectDevice(_ device: MIDIDevice?) {
        print("🎛️  Selecting device: \(device?.name ?? "None")")
        
            // Disconnect all current sources
        for source in connectedSources {
            MIDIPortDisconnectSource(inputPort, source)
        }
        connectedSources.removeAll()
        
        selectedDevice = device
        
            // Connect to selected device
        if let device = device {
            MIDIPortConnectSource(inputPort, device.id, nil)
            connectedSources.insert(device.id)
            print("  ✅ Connected to: \(device.name)")
        }
    }
    
    /**
     * Connects to all available MIDI devices simultaneously.
     *
     * This method:
     * 1. Disconnects any currently selected device
     * 2. Connects to all available MIDI sources
     * 3. Sets selectedDevice to nil (indicating "All Devices")
     *
     * Useful when you want to monitor multiple MIDI controllers at once.
     */
    func connectToAllDevices() {
        print("🎛️  Connecting to all MIDI devices...")
        
            // Disconnect current sources
        for source in connectedSources {
            MIDIPortDisconnectSource(inputPort, source)
        }
        connectedSources.removeAll()
        
        selectedDevice = nil
        
            // Connect to all sources
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, source, nil)
            connectedSources.insert(source)
        }
        print("  ✅ Connected to \(sourceCount) devices")
    }
    
        // MARK: CoreMIDI Setup
    
    /**
     * Sets up CoreMIDI client and input port with MIDI 2.0 UMP protocol.
     *
     * This method:
     * 1. Creates a MIDI client with notification handler
     * 2. Creates an input port with MIDIEventList (UMP) handler
     * 3. Configures port protocol to MIDI 2.0
     * 4. Handles any errors during setup
     *
     * The notification handler responds to MIDI setup changes (devices added/removed).
     * The event list handler processes incoming MIDI UMP packets.
     *
     * UMP Protocol:
     * - Universal MIDI Packet format (32-bit aligned)
     * - Supports both MIDI 1.0 and MIDI 2.0 messages
     * - Automatically handles protocol conversion
     *
     * Called automatically during initialization.
     */
    private func setupMIDI() {
        var status: OSStatus
        
        print("🎹 Setting up CoreMIDI with MIDI 2.0 UMP...")
        
            // Create MIDI client with notification handler
        status = MIDIClientCreateWithBlock("MIDIMonitorClient" as CFString, &midiClient) { [weak self] notification in
            self?.handleMIDINotification(notification.pointee)
        }
        guard status == noErr else {
            print("  ❌ Error creating MIDI client: \(status)")
            return
        }
        print("  ✅ MIDI client created")
        
            // Create input port with MIDIEventList (UMP) handler
            // This replaces MIDIInputPortCreateWithBlock for MIDI 2.0 support
        status = MIDIInputPortCreateWithProtocol(
            midiClient,
            "MIDIMonitorInput" as CFString,
            ._2_0,  // Use MIDI 2.0 protocol
            &inputPort
        ) { [weak self] eventList, _ in
            self?.handleMIDIEventList(eventList)
        }
        guard status == noErr else {
            print("  ❌ Error creating input port: \(status)")
            return
        }
        print("  ✅ MIDI 2.0 UMP input port created")
    }
    
    /**
     * Handles MIDI notifications (device changes, etc.)
     *
     * Parameters:
     * - notification: The MIDI notification received from CoreMIDI
     *
     * When the MIDI setup changes (device added/removed), this method
     * automatically refreshes the device list.
     */
    private func handleMIDINotification(_ notification: MIDINotification) {
        if notification.messageID == .msgSetupChanged {
            print("📢 MIDI setup changed - refreshing devices...")
            refreshDevices()
        }
    }
    
        // MARK: MIDI Message Processing (UMP)
    
    /**
     * Processes a MIDI event list received from the input port (MIDI 2.0 UMP).
     *
     * Parameters:
     * - eventList: Pointer to the MIDI event list containing UMP packets
     *
     * An event list can contain multiple UMP packets. This method
     * iterates through all packets and processes each one.
     *
     * UMP Event List Structure:
     * - Contains one or more UMP packets
     * - Each packet is 32-bit aligned (can be 32, 64, 96, or 128 bits)
     * - Packets are accessed sequentially using MIDIEventListNext
     */
    private func handleMIDIEventList(_ eventList: UnsafePointer<MIDIEventList>) {
        let listPointer = UnsafeMutablePointer(mutating: eventList)
        
            // Access the event list
        var packet = listPointer.pointee.packet
        
            // Process each packet in the list
        for _ in 0..<eventList.pointee.numPackets {
            handleUMPPacket(packet)
            packet = MIDIEventPacketNext(&packet).pointee
        }
    }
    
    /**
     * Parses and handles a single UMP packet.
     *
     * Parameters:
     * - packet: The UMP packet to process
     *
     * Universal MIDI Packet (UMP) Format:
     * - All packets start with 32-bit word containing message type and data
     * - Word 0 bits 28-31: Message Type
     *   - Type 2 (0x2): MIDI 1.0 Channel Voice Messages (32-bit)
     *   - Type 4 (0x4): MIDI 2.0 Channel Voice Messages (64-bit)
     *
     * MIDI 1.0 Channel Voice (Type 2) - 32 bits:
     * - Bits 28-31: Message Type (2)
     * - Bits 24-27: Group (0-15)
     * - Bits 20-23: Status nibble (8=Note Off, 9=Note On, B=CC, etc.)
     * - Bits 16-19: Channel (0-15)
     * - Bits 8-15: Data byte 1 (note/CC number)
     * - Bits 0-7: Data byte 2 (velocity/CC value)
     *
     * MIDI 2.0 Channel Voice (Type 4) - 64 bits:
     * - Similar structure but with 16-bit or 32-bit data fields
     * - Higher resolution for velocity, CC values, etc.
     *
     * This method filters messages based on:
     * 1. Message type (MIDI 1.0 or 2.0 Channel Voice)
     * 2. Status (Control Change, Note On, Note Off)
     * 3. Monitored CC number (monitoredCC)
     * 4. Monitored note number (monitoredNote)
     * 5. Note type setting (noteType)
     *
     * When a matching message is found, it updates ccValue or noteValue
     * on the main thread (since these are @Published properties).
     */
    private func handleUMPPacket(_ packet: MIDIEventPacket) {
            // UMP packets are stored as an array of 32-bit words
        let words = Mirror(reflecting: packet.words).children.map { $0.value as! UInt32 }
        
        guard words.count > 0 else { return }
        
        let word0 = words[0]
        
            // Extract message type from bits 28-31
        let messageType = (word0 >> 28) & 0xF
        
            // Debug: Print all incoming UMP packets (uncomment to debug)
            // print("📨 UMP: type=\(messageType) word0=\(String(format: "0x%08X", word0))")
        
            // Handle MIDI 1.0 Channel Voice Messages (Type 2)
        if messageType == 0x2 {
            handleMIDI1ChannelVoice(word0)
        }
            // Handle MIDI 2.0 Channel Voice Messages (Type 4)
        else if messageType == 0x4 {
            guard words.count > 1 else { return }
            let word1 = words[1]
            handleMIDI2ChannelVoice(word0, word1)
        }
    }
    
    /**
     * Handles MIDI 1.0 Channel Voice Messages (UMP Type 2).
     *
     * Parameters:
     * - word0: The 32-bit UMP word containing the MIDI 1.0 message
     *
     * Bit Layout:
     * - Bits 28-31: Message Type (2)
     * - Bits 24-27: Group
     * - Bits 20-23: Status (8=NoteOff, 9=NoteOn, B=CC)
     * - Bits 16-19: Channel
     * - Bits 8-15: Data1 (note/CC number)
     * - Bits 0-7: Data2 (velocity/CC value)
     */
    private func handleMIDI1ChannelVoice(_ word0: UInt32) {
        let status = (word0 >> 20) & 0xF     // Extract status nibble
        let channel = (word0 >> 16) & 0xF    // Extract channel (not used currently)
        let data1 = UInt8((word0 >> 8) & 0x7F)  // Data byte 1 (7-bit)
        let data2 = UInt8(word0 & 0x7F)          // Data byte 2 (7-bit)
        
            // Process based on status
        switch status {
            case 0xB:  // Control Change
                if data1 == monitoredCC {
                    print("🎚️  CC\(monitoredCC) = \(data2) [MIDI 1.0]")
                    DispatchQueue.main.async {
                        self.ccValue = data2
                    }
                }
                
            case 0x9:  // Note On
                if data1 == monitoredNote {
                    if data2 > 0 {
                            // Note On with velocity > 0
                        if noteType == .noteOn || noteType == .both {
                            print("🎵 Note ON: note=\(data1) velocity=\(data2) [MIDI 1.0]")
                            DispatchQueue.main.async {
                                self.noteValue = data2
                            }
                        }
                    } else {
                            // Note On with velocity 0 (some devices use this as Note Off)
                        if noteType == .noteOff || noteType == .both {
                            print("🎵 Note OFF (velocity 0): note=\(data1) [MIDI 1.0]")
                            DispatchQueue.main.async {
                                self.noteValue = 0
                            }
                        }
                    }
                }
                
            case 0x8:  // Note Off
                if data1 == monitoredNote {
                    if noteType == .noteOff || noteType == .both {
                        print("🎵 Note OFF: note=\(data1) velocity=\(data2) [MIDI 1.0]")
                        DispatchQueue.main.async {
                            self.noteValue = data2
                        }
                    }
                }
                
            default:
                break
        }
    }
    
    /**
     * Handles MIDI 2.0 Channel Voice Messages (UMP Type 4).
     *
     * Parameters:
     * - word0: First 32-bit UMP word (status and channel info)
     * - word1: Second 32-bit UMP word (data with higher resolution)
     *
     * MIDI 2.0 provides higher resolution data (16-bit or 32-bit values).
     * We scale these down to MIDI 1.0's 7-bit range (0-127) for compatibility.
     *
     * Word 0 Layout:
     * - Bits 28-31: Message Type (4)
     * - Bits 24-27: Group
     * - Bits 20-23: Status
     * - Bits 16-19: Channel
     * - Bits 0-15: Additional info (varies by message)
     *
     * Word 1 Layout (varies by message type):
     * - For CC: Bits 0-31 contain 32-bit CC value
     * - For Note: Bits 16-31 contain 16-bit velocity
     */
    private func handleMIDI2ChannelVoice(_ word0: UInt32, _ word1: UInt32) {
        let status = (word0 >> 20) & 0xF
        let channel = (word0 >> 16) & 0xF
        let data1 = UInt8((word0 >> 8) & 0x7F)  // Note/CC number (still 7-bit)
        
            // Process based on status
        switch status {
            case 0xB:  // Control Change (MIDI 2.0)
                if data1 == monitoredCC {
                        // MIDI 2.0 CC value is 32-bit in word1
                        // Scale from 32-bit (0 - 0xFFFFFFFF) to 7-bit (0-127)
                    let fullValue = word1
                    let scaledValue = UInt8(UInt64(fullValue) * 127 / 0xFFFFFFFF)
                    
                    print("🎚️  CC\(monitoredCC) = \(scaledValue) [MIDI 2.0, raw=\(String(format: "0x%08X", fullValue))]")
                    DispatchQueue.main.async {
                        self.ccValue = scaledValue
                    }
                }
                
            case 0x9:  // Note On (MIDI 2.0)
                if data1 == monitoredNote {
                        // MIDI 2.0 velocity is 16-bit in upper half of word1
                        // Scale from 16-bit (0 - 0xFFFF) to 7-bit (0-127)
                    let fullVelocity = UInt16((word1 >> 16) & 0xFFFF)
                    let scaledVelocity = UInt8(UInt32(fullVelocity) * 127 / 0xFFFF)
                    
                    if scaledVelocity > 0 {
                        if noteType == .noteOn || noteType == .both {
                            print("🎵 Note ON: note=\(data1) velocity=\(scaledVelocity) [MIDI 2.0, raw=\(String(format: "0x%04X", fullVelocity))]")
                            DispatchQueue.main.async {
                                self.noteValue = scaledVelocity
                            }
                        }
                    } else {
                        if noteType == .noteOff || noteType == .both {
                            print("🎵 Note OFF (velocity 0): note=\(data1) [MIDI 2.0]")
                            DispatchQueue.main.async {
                                self.noteValue = 0
                            }
                        }
                    }
                }
                
            case 0x8:  // Note Off (MIDI 2.0)
                if data1 == monitoredNote {
                    if noteType == .noteOff || noteType == .both {
                        let fullVelocity = UInt16((word1 >> 16) & 0xFFFF)
                        let scaledVelocity = UInt8(UInt32(fullVelocity) * 127 / 0xFFFF)
                        
                        print("🎵 Note OFF: note=\(data1) velocity=\(scaledVelocity) [MIDI 2.0]")
                        DispatchQueue.main.async {
                            self.noteValue = scaledVelocity
                        }
                    }
                }
                
            default:
                break
        }
    }
    
        // MARK: Cleanup
    
    /**
     * Cleanup when MIDIManager is deallocated.
     *
     * Disconnects all MIDI sources and disposes of CoreMIDI resources.
     */
    deinit {
        print("🧹 Cleaning up MIDI resources...")
        for source in connectedSources {
            MIDIPortDisconnectSource(inputPort, source)
        }
        MIDIPortDispose(inputPort)
        MIDIClientDispose(midiClient)
    }
}

    // MARK: - Data Point Model

/**
 * DataPoint - Represents a single point on the scrolling graph
 *
 * Properties:
 * - id: Unique identifier for SwiftUI list rendering
 * - value: The CC value at this point in time (0-127)
 * - hasNote: Whether a note event occurred at this point
 * - noteValue: The velocity of the note event (if hasNote is true)
 * - timestamp: When this data point was created
 *
 * The graph displays:
 * - CC values as a connected cyan line
 * - Note velocities as red dots (when hasNote = true)
 * - Note positions as orange dots on the CC line (when hasNote = true)
 */
struct DataPoint: Identifiable {
    let id = UUID()
    let value: CGFloat          // CC value (0-127)
    let hasNote: Bool            // Does this point have a note event?
    let noteValue: CGFloat?      // Note velocity if hasNote is true
    let timestamp: Date          // When this point was created
    
    init(value: CGFloat, hasNote: Bool = false, noteValue: CGFloat? = nil) {
        self.value = value
        self.hasNote = hasNote
        self.noteValue = noteValue
        self.timestamp = Date()
    }
}

    // MARK: - Graph View Model

/**
 * GraphViewModel - Manages the scrolling graph data and timing
 *
 * Responsibilities:
 * 1. Maintains an array of DataPoint objects for the graph
 * 2. Runs a timer that samples MIDI values at regular intervals
 * 3. Detects note events and marks the EXACT point where they occur
 * 4. Manages the scrolling behavior (adding/removing data points)
 *
 * How Note Display Works:
 * 1. When a note event occurs (noteValue changes), we mark THAT SPECIFIC point
 * 2. Only the data point at that moment gets hasNote=true with the velocity
 * 3. Subsequent points do NOT show the note marker unless another note occurs
 * 4. This creates a single dot (or pair of dots) at each note event
 *
 * Key Settings:
 * - maxDataPoints: Maximum number of points to keep (older points are removed)
 * - Timer interval: 0.05 seconds (50ms) = 20 updates per second
 *
 * Usage:
 * 1. Create: let viewModel = GraphViewModel()
 * 2. Start: viewModel.start(midiManager: midiManager)
 * 3. Observe: @ObservedObject var viewModel: GraphViewModel
 * 4. Stop: viewModel.stop() (called automatically on deinit)
 */
class GraphViewModel: ObservableObject {
        // MARK: Published Properties
    
        /// Array of data points displayed on the graph
        /// Newest points are at the end, oldest at the beginning
    @Published var dataPoints: [DataPoint] = []
    
        // MARK: Configuration
    
        /// Maximum number of data points to keep in memory
        /// When exceeded, oldest points are removed (creating the scrolling effect)
        /// Default: 200 points ≈ 10 seconds of data at 20 Hz
    private let maxDataPoints = 200
    
        // MARK: Private State
    
        /// Timer that triggers data sampling
    private var timer: Timer?
    
        /// Last recorded note velocity value
        /// Used to detect when the note value changes
    private var lastNoteValue: UInt8 = 0
    
        // MARK: Start/Stop
    
    /**
     * Starts the graph data collection.
     *
     * Parameters:
     * - midiManager: The MIDIManager to observe for CC and note values
     *
     * This method:
     * 1. Creates a repeating timer (50ms interval = 20 Hz)
     * 2. On each tick, samples the current CC and note values
     * 3. Detects note events (when noteValue changes)
     * 4. Creates DataPoint objects - ONLY the point where the note changed has the marker
     * 5. Manages the dataPoints array (adding new, removing old)
     *
     * The timer captures weak references to prevent retain cycles.
     */
    func start(midiManager: MIDIManager) {
        print("📊 Starting graph data collection (20 Hz)")
        print("   - Max data points: \(maxDataPoints)")
        print("   - Note markers: Only at exact moment of note event")
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self, weak midiManager] _ in
            guard let self = self, let midiManager = midiManager else { return }
            
                // Sample current values from MIDI manager
            let ccVal = CGFloat(midiManager.ccValue)
            let currentNoteValue = midiManager.noteValue
            
                // DETECTION: Check if note value changed (new note event)
            let noteChanged = currentNoteValue != self.lastNoteValue
            
                // CRITICAL: Only mark THIS point if the note changed RIGHT NOW
            var noteVal: CGFloat? = nil
            if noteChanged {
                    // New note event detected!
                self.lastNoteValue = currentNoteValue
                noteVal = CGFloat(currentNoteValue)
                print("📍 Note event at this exact point: velocity=\(currentNoteValue)")
            }
                // If noteChanged is false, noteVal stays nil - no marker on this point
            
                // Create new data point with current state
                // hasNote and noteValue are ONLY set if a note event happened on THIS tick
            let newPoint = DataPoint(
                value: ccVal,
                hasNote: noteVal != nil,
                noteValue: noteVal
            )
            
                // Update on main thread (required for @Published property)
            DispatchQueue.main.async {
                self.dataPoints.append(newPoint)
                
                    // SCROLLING: Remove oldest points when we exceed max
                    // This creates the left-scrolling effect
                if self.dataPoints.count > self.maxDataPoints {
                    self.dataPoints.removeFirst(self.dataPoints.count - self.maxDataPoints)
                }
            }
        }
    }
    
    /**
     * Stops the graph data collection.
     *
     * Invalidates and releases the timer. Call this when:
     * - The view disappears
     * - The app is closing
     * - You want to pause data collection
     */
    func stop() {
        print("📊 Stopping graph data collection")
        timer?.invalidate()
        timer = nil
    }
    
        // MARK: Cleanup
    
    /**
     * Cleanup when GraphViewModel is deallocated.
     * Ensures the timer is stopped.
     */
    deinit {
        stop()
    }
}

    // MARK: - Graph View

/**
 * MIDIGraphView - Renders the scrolling MIDI data visualization
 *
 * This view uses SwiftUI Canvas for high-performance rendering of:
 * 1. CC values as a connected cyan line
 * 2. Note velocities as red dots (at the velocity Y position)
 * 3. Note event positions as orange dots (on the CC line)
 *
 * Coordinate System:
 * - X-axis: Time (left = older, right = newer)
 * - Y-axis: MIDI value (bottom = 0, top = 127)
 *
 * Graph Layout:
 * - xOffset: 40px from left (space for Y-axis labels)
 * - yOffset: 10px from top
 * - graphWidth: Available width - 50px
 * - graphHeight: Available height - 20px
 *
 * Rendering Order (back to front):
 * 1. Background (black)
 * 2. Grid lines (gray)
 * 3. Y-axis labels (white)
 * 4. CC line (cyan, connected)
 * 5. CC data points (cyan dots)
 * 6. Note velocity markers (red dots with glow)
 * 7. Note position markers (orange dots with glow)
 *
 * Performance:
 * - Canvas is used for efficient rendering of many shapes
 * - Only redraws when viewModel.dataPoints changes
 * - Renders ~200 points per frame at 60 FPS
 */
struct MIDIGraphView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                    // LAYER 1: Background
                Color.black.opacity(0.9)
                
                    // LAYER 2: Grid lines (horizontal)
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                    // LAYER 3: Y-axis labels
                HStack {
                    VStack {
                        Text("127")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text("96")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("64")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text("32")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("0")
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .frame(width: 30)
                    
                    Spacer()
                }
                .padding(.leading, 5)
                
                    // LAYER 4-7: Graph content (Canvas for performance)
                Canvas { context, size in
                        // Calculate graph dimensions
                    let graphWidth = size.width - 50    // Leave space for Y-axis labels
                    let graphHeight = size.height - 20   // Leave space for padding
                    let xOffset: CGFloat = 40            // Start position (after Y-axis)
                    let yOffset: CGFloat = 10            // Top padding
                    
                        // Need at least 2 points to draw a line
                    guard viewModel.dataPoints.count > 1 else {
                        print("⚠️  Not enough data points to render graph")
                        return
                    }
                    
                        // Calculate horizontal spacing between points
                        // Divide available width by number of gaps between points
                    let xStep = graphWidth / CGFloat(viewModel.dataPoints.count - 1)
                    
                    print("🎨 Rendering graph: \(viewModel.dataPoints.count) points, xStep=\(xStep)")
                    
                        // DRAW CC LINE: Connected cyan line through all points
                    var path = Path()
                    for (index, point) in viewModel.dataPoints.enumerated() {
                            // Calculate X position (time axis)
                        let x = xOffset + CGFloat(index) * xStep
                        
                            // Calculate Y position (value axis)
                            // Normalize value to 0.0-1.0 range, then map to screen coordinates
                        let normalizedValue = point.value / 127.0
                        let y = yOffset + graphHeight - (normalizedValue * graphHeight)
                        
                        if index == 0 {
                                // First point: move to position
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                                // Subsequent points: draw line from previous point
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                        // Stroke the path with cyan color
                    context.stroke(
                        path,
                        with: .color(.cyan),
                        lineWidth: 2
                    )
                    
                        // DRAW CC DATA POINTS: Small cyan dots on the line
                    for (index, point) in viewModel.dataPoints.enumerated() {
                        let x = xOffset + CGFloat(index) * xStep
                        let normalizedValue = point.value / 127.0
                        let y = yOffset + graphHeight - (normalizedValue * graphHeight)
                        
                            // Create a small circle at this point
                        let pointPath = Circle()
                            .path(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
                        
                        context.fill(pointPath, with: .color(.cyan))
                    }
                    
                        // DRAW NOTE MARKERS: Red velocity dots and orange position dots
                    var noteMarkersDrawn = 0
                    for (index, point) in viewModel.dataPoints.enumerated() {
                            // Only draw markers if this point has a note event
                        if let noteValue = point.noteValue {
                            let x = xOffset + CGFloat(index) * xStep
                            
                                // RED DOT: Draw velocity value marker
                                // This shows the actual note velocity on the Y-axis
                            let normalizedVelocity = noteValue / 127.0
                            let velocityY = yOffset + graphHeight - (normalizedVelocity * graphHeight)
                            
                            let velocityPath = Circle()
                                .path(in: CGRect(x: x - 4, y: velocityY - 4, width: 8, height: 8))
                            
                            context.fill(velocityPath, with: .color(.red))
                            
                                // Add subtle glow to velocity marker
                            context.fill(
                                Circle().path(in: CGRect(x: x - 6, y: velocityY - 6, width: 12, height: 12)),
                                with: .color(.red.opacity(0.3))
                            )
                            
                                // ORANGE DOT: Draw position marker on CC line
                                // This shows where the note event occurred relative to the CC value
                            let ccValue = point.value
                            let normalizedCC = ccValue / 127.0
                            let ccY = yOffset + graphHeight - (normalizedCC * graphHeight)
                            
                            let positionPath = Circle()
                                .path(in: CGRect(x: x - 3, y: ccY - 3, width: 6, height: 6))
                            
                            context.fill(positionPath, with: .color(.orange))
                            
                                // Add subtle glow to position marker
                            context.fill(
                                Circle().path(in: CGRect(x: x - 5, y: ccY - 5, width: 10, height: 10)),
                                with: .color(.orange.opacity(0.3))
                            )
                            
                            noteMarkersDrawn += 1
                        }
                    }
                    
                    if noteMarkersDrawn > 0 {
                        print("  🔴 Drew \(noteMarkersDrawn) note markers")
                    }
                }
                .padding(.trailing, 10)
            }
        }
    }
}

    // MARK: - Settings View

/**
 * SettingsView - Configuration panel for MIDI monitoring parameters
 *
 * This modal sheet allows users to configure:
 * 1. MIDI input device selection
 * 2. Which Control Change (CC) number to monitor
 * 3. Which note number to monitor
 * 4. Which note message type to capture (On/Off/Both)
 *
 * The view is presented as a sheet from the main ContentView.
 * Changes are applied when the user clicks "Done".
 *
 * Layout:
 * - ScrollView wrapper for small screens
 * - Grouped sections with headers
 * - Preset buttons for common values
 * - Fixed size: 500x450 pixels
 *
 * Bindings:
 * - monitoredCC: Two-way binding to CC number (updates MIDIManager on Done)
 * - monitoredNote: Two-way binding to note number (updates MIDIManager on Done)
 * - noteType: Two-way binding to note message type (updates MIDIManager on Done)
 * - showSettings: Controls modal presentation (set to false to dismiss)
 */
struct SettingsView: View {
    @ObservedObject var midiManager: MIDIManager
    @Binding var monitoredCC: Int
    @Binding var monitoredNote: Int
    @Binding var noteType: NoteType
    @Binding var showSettings: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                    // Header
                HStack {
                    Text("MIDI Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") {
                            // Update MIDI manager with new values
                        midiManager.monitoredCC = UInt8(monitoredCC)
                        midiManager.monitoredNote = UInt8(monitoredNote)
                        midiManager.noteType = noteType
                        showSettings = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
                
                Divider()
                
                    // MIDI Device Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("MIDI Input Device")
                        .font(.headline)
                    
                    Picker("Device", selection: Binding(
                        get: { midiManager.selectedDevice },
                        set: { midiManager.selectDevice($0) }
                    )) {
                        Text("All Devices").tag(nil as MIDIDevice?)
                        ForEach(midiManager.availableDevices) { device in
                            Text(device.name).tag(device as MIDIDevice?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button("Refresh Devices") {
                        midiManager.refreshDevices()
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                    // CC Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Control Change (CC) to Monitor")
                        .font(.headline)
                    
                    HStack {
                        TextField("CC Number", value: $monitoredCC, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Text("(0-127)")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(getCCName(monitoredCC))
                            .foregroundColor(.secondary)
                    }
                    
                        // Common CC presets
                    HStack(spacing: 8) {
                        Text("Presets:")
                            .foregroundColor(.secondary)
                        Button("Breath (2)") { monitoredCC = 2 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("Modulation (1)") { monitoredCC = 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("Volume (7)") { monitoredCC = 7 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("Expression (11)") { monitoredCC = 11 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                
                Divider()
                
                    // Note Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note to Monitor")
                        .font(.headline)
                    
                    HStack {
                        TextField("Note Number", value: $monitoredNote, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Text("(0-127)")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(getNoteName(monitoredNote))
                            .foregroundColor(.secondary)
                    }
                    
                        // Common note presets
                    HStack(spacing: 8) {
                        Text("Presets:")
                            .foregroundColor(.secondary)
                        Button("C3 (48)") { monitoredNote = 48 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("C4 (60)") { monitoredNote = 60 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("C5 (72)") { monitoredNote = 72 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                
                Divider()
                
                    // Note Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note Message Type")
                        .font(.headline)
                    
                    Picker("Note Type", selection: $noteType) {
                        ForEach(NoteType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
    
    private func getCCName(_ cc: Int) -> String {
        switch cc {
            case 0: return "Bank Select"
            case 1: return "Modulation Wheel"
            case 2: return "Breath Controller"
            case 4: return "Foot Controller"
            case 5: return "Portamento Time"
            case 7: return "Channel Volume"
            case 10: return "Pan"
            case 11: return "Expression"
            case 64: return "Sustain Pedal"
            case 65: return "Portamento"
            case 66: return "Sostenuto"
            case 67: return "Soft Pedal"
            case 71: return "Resonance"
            case 72: return "Release Time"
            case 73: return "Attack Time"
            case 74: return "Cutoff"
            default: return "CC \(cc)"
        }
    }
    
    private func getNoteName(_ noteNumber: Int) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (noteNumber / 12) - 1
        let note = notes[noteNumber % 12]
        return "\(note)\(octave)"
    }
}

    // MARK: - Main Content View

/**
 * ContentView - Main application interface
 *
 * This is the root view of the application, displaying:
 * 1. Header with app title and current monitoring parameters
 * 2. Device info bar showing connected MIDI device
 * 3. Legend explaining the graph visualization
 * 4. Real-time scrolling graph (MIDIGraphView)
 * 5. Settings button (gear icon) to open configuration
 *
 * State Management:
 * - @StateObject midiManager: Manages MIDI communication (lifecycle tied to view)
 * - @StateObject graphViewModel: Manages graph data (lifecycle tied to view)
 * - @State showSettings: Controls settings sheet presentation
 * - @State monitoredCC: Currently monitored CC number (synced with MIDIManager)
 * - @State monitoredNote: Currently monitored note number (synced with MIDIManager)
 * - @State noteType: Note message type filter (synced with MIDIManager)
 *
 * Lifecycle:
 * - onAppear: Configures MIDIManager and starts GraphViewModel
 * - onDisappear: Stops GraphViewModel
 *
 * UI Layout (top to bottom):
 * 1. Black header bar with title, parameters, values, and settings button
 * 2. Device connection status bar
 * 3. Legend showing visualization elements
 * 4. Scrolling graph (fills remaining space)
 *
 * Settings Integration:
 * - Gear button opens SettingsView as a sheet
 * - Settings changes are applied to MIDIManager when user clicks "Done"
 * - UI updates automatically via @Published properties
 */
struct ContentView: View {
    @StateObject private var midiManager = MIDIManager()
    @StateObject private var graphViewModel = GraphViewModel()
    @State private var showSettings = false
    @State private var monitoredCC: Int = 2       // Default: Breath Control (CC2)
    @State private var monitoredNote: Int = 48    // Default: C3
    @State private var noteType: NoteType = .both // Default: Monitor both On and Off
    
    var body: some View {
        VStack(spacing: 0) {
                // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MIDI Monitor")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    HStack(spacing: 4) {
                        Text("CC\(monitoredCC): \(getCCName(monitoredCC))")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                        Text("•")
                            .foregroundColor(.gray)
                        Text("\(getNoteName(monitoredNote)) (\(noteType.rawValue))")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                    // Current values display
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text("CC\(monitoredCC):")
                            .foregroundColor(.gray)
                        Text("\(midiManager.ccValue)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .frame(width: 50, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("\(getNoteName(monitoredNote)):")
                            .foregroundColor(.gray)
                        Text("\(midiManager.noteValue)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                
                    // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
                // Device info bar
            HStack {
                Image(systemName: "cable.connector")
                    .foregroundColor(.green)
                Text(midiManager.selectedDevice?.name ?? "All Devices")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.5))
            
                // Legend
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(width: 30, height: 3)
                    Text("CC\(monitoredCC) Value")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text("\(getNoteName(monitoredNote)) Velocity")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Note Event Position")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.6))
            
                // Graph
            MIDIGraphView(viewModel: graphViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .onAppear {
            midiManager.monitoredCC = UInt8(monitoredCC)
            midiManager.monitoredNote = UInt8(monitoredNote)
            midiManager.noteType = noteType
            graphViewModel.start(midiManager: midiManager)
        }
        .onDisappear {
            graphViewModel.stop()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                midiManager: midiManager,
                monitoredCC: $monitoredCC,
                monitoredNote: $monitoredNote,
                noteType: $noteType,
                showSettings: $showSettings
            )
        }
    }
    
    private func getCCName(_ cc: Int) -> String {
        switch cc {
            case 1: return "Modulation"
            case 2: return "Breath"
            case 7: return "Volume"
            case 11: return "Expression"
            default: return "CC\(cc)"
        }
    }
    
    private func getNoteName(_ noteNumber: Int) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (noteNumber / 12) - 1
        let note = notes[noteNumber % 12]
        return "\(note)\(octave)"
    }
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
