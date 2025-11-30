//
//  MIDIMonitorView_Example.swift
//  Example usage of self-contained MIDI graph
//

import SwiftUI

/**
 * Example: How to use the new self-contained MIDIGraphView
 *
 * Old way (with ViewModel):
 * ```
 * @StateObject var viewModel = GraphViewModel()
 * MIDIGraphView(viewModel: viewModel)
 * ```
 *
 * New way (self-contained):
 * ```
 * MIDIGraphView(ccNumber: .breathControl, channel: 0)
 * ```
 *
 * That's it! The view handles everything internally.
 */

struct MIDIMonitorView: View {
    // Just configuration state
    @State private var selectedCC: ContinuousController = .breathControl
    @State private var selectedChannel: UInt8 = 0
    
    var body: some View {
        VStack {
            // Controls
            HStack {
                Picker("CC Number:", selection: $selectedCC) {
                    Text("Breath Control (2)").tag(ContinuousController.breathControl)
                    Text("Modulation (1)").tag(ContinuousController.modulationWheel)
                    // Add more as needed
                }
                .frame(width: 200)
                
                Picker("Channel:", selection: $selectedChannel) {
                    ForEach(0..<16) { channel in
                        Text("Channel \(channel + 1)").tag(UInt8(channel))
                    }
                }
                .frame(width: 150)
            }
            .padding()
            
            // Self-contained graph
            MIDIGraphView(ccNumber: selectedCC, channel: selectedChannel)
                .frame(height: 300)
                .border(Color.gray.opacity(0.3))
        }
        .padding()
    }
}

#Preview {
    MIDIMonitorView()
        .frame(width: 800, height: 400)
}
