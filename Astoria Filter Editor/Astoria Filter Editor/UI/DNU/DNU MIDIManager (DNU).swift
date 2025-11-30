//
//  MIDIManager.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//
import CoreMIDI
import Combine


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
                devices.append(MIDIDevice(endpoint: source, type: .source))
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
