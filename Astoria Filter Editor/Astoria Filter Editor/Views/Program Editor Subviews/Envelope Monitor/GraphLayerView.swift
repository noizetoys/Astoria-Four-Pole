//
//  GraphLayerView.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/29/25.
//

import SwiftUI


    // MARK: - NSViewRepresentable

/**
 * GraphLayerView - Bridge to SwiftUI
 *
 * Simplified (like LFO):
 * - Passes simple configuration values
 * - No @ObservedObject
 * - View handles everything
 */
struct GraphLayerView: NSViewRepresentable {
    var ccNumber: UInt8
    var channel: UInt8
    
        /// NEW: Control bindings
    @Binding var isDisplayActive: Bool
    @Binding var showVelocity: Bool
    @Binding var showPosition: Bool

    
    
    func makeNSView(context: Context) -> GraphContainerView {
        debugPrint(icon: "🔨", message: "Creating GraphContainerView", type: .trace)
        let view = GraphContainerView()
        view.configure(ccNumber: ccNumber,
                       channel: channel,
                       isActive: isDisplayActive,
                       showVelocity: showVelocity,
                       showPosition: showPosition)
        return view
    }
    
    
    func updateNSView(_ nsView: GraphContainerView, context: Context) {
            // Only update if configuration changed
        nsView.configure(ccNumber: ccNumber,
                         channel: channel,
                         isActive: isDisplayActive,
                         showVelocity: showVelocity,
                         showPosition: showPosition)
    }
    
    
    static func dismantleNSView(_ nsView: GraphContainerView, coordinator: ()) {
        debugPrint(icon: "💀", message: "Dismantling GraphContainerView", type: .trace)
    }
}
