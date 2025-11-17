//
//  MIDIMonitorView.swift
//  Virtual Waldorf 4 Pole Filter
//

import SwiftUI

struct MIDIMonitorView: View {
    @EnvironmentObject var midiManager: MIDIManager
    @State private var selectedTab = 0
    @State private var selectedMessage: MIDIMessage?
    @State private var autoScroll = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.blue)
                Text("MIDI Monitor")
                    .font(.headline)
                
                Spacer()
                
                // Tab Selector
                Picker("", selection: $selectedTab) {
                    Text("All").tag(0)
                    Text("Received").tag(1)
                    Text("Sent").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                // Auto-scroll toggle
                Toggle(isOn: $autoScroll) {
                    Image(systemName: "arrow.down.to.line")
                }
                .toggleStyle(.button)
                .help("Auto-scroll to new messages")
                
                // Clear button
                Button(action: {
                    midiManager.receivedMessages.removeAll()
                    midiManager.sentMessages.removeAll()
                    selectedMessage = nil
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .help("Clear all messages")
            }
            .padding()
            
            Divider()
            
            // Message List and Detail
            HSplitView {
                // Message List
                VStack(spacing: 0) {
                    if filteredMessages.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No MIDI messages")
                                .foregroundColor(.secondary)
                            Text("Messages will appear here when sent or received")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        List(filteredMessages, selection: $selectedMessage) { message in
                            MessageRow(message: message)
                        }
                    }
                }
                .frame(minWidth: 200, idealWidth: 300)
                
                Divider()
                
                // Message Detail
                if let message = selectedMessage {
                    MessageDetailView(message: message)
                        .frame(minWidth: 300)
                } else {
                    VStack {
                        Spacer()
                        Text("Select a message to view details")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .onChange(of: midiManager.receivedMessages.count) { _ in
            if autoScroll, let first = midiManager.receivedMessages.first {
                selectedMessage = first
            }
        }
        .onChange(of: midiManager.sentMessages.count) { _ in
            if autoScroll, let first = midiManager.sentMessages.first {
                selectedMessage = first
            }
        }
    }
    
    private var filteredMessages: [MIDIMessage] {
        switch selectedTab {
        case 1: return midiManager.receivedMessages
        case 2: return midiManager.sentMessages
        default:
            var combined = midiManager.receivedMessages + midiManager.sentMessages
            combined.sort { $0.timestamp > $1.timestamp }
            return combined
        }
    }
}

struct MessageRow: View {
    let message: MIDIMessage
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Direction indicator
            Image(systemName: message.direction == .received ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(message.direction == .received ? .green : .blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message.description)
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack {
                    Text(timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(message.byteCount) bytes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MessageDetailView: View {
    let message: MIDIMessage
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: message.direction == .received ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(message.direction == .received ? .green : .blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.description)
                        .font(.headline)
                    
                    Text(message.direction == .received ? "Received" : "Sent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Timestamp", value: timeString)
                DetailRow(label: "Byte Count", value: "\(message.byteCount)")
                DetailRow(label: "Direction", value: message.direction == .received ? "Received (In)" : "Sent (Out)")
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Hex Data
            VStack(alignment: .leading, spacing: 8) {
                Text("Hex Data")
                    .font(.headline)
                
                ScrollView {
                    Text(formatHexData(message.hexString))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
            
            // Decoded Data
            if let decoded = decodeMessage(message.data) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Decoded Message")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(decoded, id: \.0) { item in
                                HStack {
                                    Text(item.0)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Text(item.1)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)
                    .padding(8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func formatHexData(_ hex: String) -> String {
        let bytes = hex.split(separator: " ")
        var result = ""
        
        for (index, byte) in bytes.enumerated() {
            if index > 0 && index % 16 == 0 {
                result += "\n"
            }
            result += "\(byte) "
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    private func decodeMessage(_ data: Data) -> [(String, String)]? {
        guard data.count >= 5 else { return nil }
        
        let bytes = [UInt8](data)
        
        guard bytes[0] == 0xF0 && bytes.last == 0xF7 else { return nil }
        guard bytes[1] == 0x3E && bytes[2] == 0x04 else { return nil }
        
        var decoded: [(String, String)] = []
        
        decoded.append(("Start", "0xF0 (SysEx Start)"))
        decoded.append(("Manufacturer", "0x3E (Waldorf)"))
        decoded.append(("Machine", "0x04 (MiniWorks 4 Pole)"))
        decoded.append(("Device ID", "0x\(String(format: "%02X", bytes[3]))"))
        
        let commandByte = bytes[4]
        
        switch commandByte {
        case 0x00:
            decoded.append(("Command", "0x00 (Program Dump)"))
            if bytes.count > 5 {
                decoded.append(("Program #", "\(bytes[5] + 1)"))
            }
        case 0x01:
            decoded.append(("Command", "0x01 (Program Bulk Dump)"))
            if bytes.count > 5 {
                decoded.append(("Program #", "\(bytes[5] + 1)"))
            }
        case 0x08:
            decoded.append(("Command", "0x08 (All Dump)"))
            decoded.append(("Data", "20 Programs + Globals"))
        case 0x40:
            decoded.append(("Command", "0x40 (Program Dump Request)"))
            if bytes.count > 5 {
                decoded.append(("Program #", "\(bytes[5] + 1)"))
            }
        case 0x41:
            decoded.append(("Command", "0x41 (Program Bulk Dump Request)"))
            if bytes.count > 5 {
                decoded.append(("Program #", "\(bytes[5] + 1)"))
            }
        case 0x48:
            decoded.append(("Command", "0x48 (All Dump Request)"))
        default:
            decoded.append(("Command", "0x\(String(format: "%02X", commandByte)) (Unknown)"))
        }
        
        if bytes.count > 6 {
            let checksumIndex = bytes.count - 2
            decoded.append(("Checksum", "0x\(String(format: "%02X", bytes[checksumIndex]))"))
        }
        
        decoded.append(("End", "0xF7 (SysEx End)"))
        
        return decoded
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MIDIMonitorView()
        .environmentObject(MIDIManager.shared)
        .frame(width: 800, height: 600)
}
