//
//  Info Overlays.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 12/1/25.
//

import SwiftUI



// MARK: - Main View

struct ConnectionsViewOverlay: View {
    var body: some View {
        Color.red.opacity(0.9)
            .overlay {
                VStack {
                    Text("Select & Connect\nMIDI Input/Output ports")
                        .multilineTextAlignment(.center)
                        .bold()
                    Text("Input not required")
                }

            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
}


struct ProgramMatrixViewOverlay: View {
    var body: some View {
        Color.gray.opacity(0.95)
            .overlay {
                VStack(spacing: 20) {
                    Text("Select Program to Edit")
                        .bold()
                    
                    VStack(alignment: .leading) {
                        Text("Right Click to show Menu:")
                            .bold()
                        Text("New Program")
                        Text("Copy Program")
                        Text("Etc.")
                    }
                    
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
}


struct ProgramTitleViewOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(LinearGradient(colors: [.white, .green],
                                            startPoint: .leading,
                                            endPoint: .trailing).opacity(0.9))
            .overlay {
                VStack {
                    Text("Edit Program Name and Tags")
                        .bold()
                    Text("'Compare' edited and unedited program")
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct QuickActionsViewOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(LinearGradient(colors: [.red, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing)
                .opacity(0.9)
            )
            .overlay {
                VStack {
                    Text("Create, Send, and Receive Programs and Profiles")
                        .bold()
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


// MARK: - Editor View

struct VCFViewOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(LinearGradient(colors: [.red, .orange, .green, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing).opacity(0.9))
            .overlay {
                VStack {
                    Text("Modulate Filter Cutoff")
                        .bold()
                    Text("Modulation Source")
                        .italic()
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct LowPassFilterViewOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(LinearGradient(colors: [.yellow, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing).opacity(0.9))
            .overlay {
                VStack {
                    Text("24 db/oct Low Pass Filter with Resonance")
                        .bold()
                    
                    Text("Amount VCF Envelope affects Cutoff")
                    
                    Text("Cutoff and Resonance Modulation Controls")
                        .italic()
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


// MARK: - Middle

struct VCAViewOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(LinearGradient(colors: [.red, .orange, .green, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing).opacity(0.9))
            .overlay {
                VStack {
                    Text("Volume Level of Signal")
                        .bold()
                    
                    Text("Modulation Source")
                        .italic()
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct VolumeViewOverlay: View {
    var body: some View {
        Color.orange.opacity(0.9)
            .overlay {
                VStack {
                    Text("Initial Volume of VCA Envelope")
                        .bold()
                    
                    Text("Amount VCA affects Volume")
                    
                    Text("Modulation Controls")
                        .italic()
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct PanningViewOverlay: View {
    var body: some View {
        Color.blue.opacity(0.9)
            .overlay {
                VStack {
                    Text("Left/Right Panning of Signal")
                        .bold()
                    
                    Text("Modulation Controls")
                        .italic()
                    
                    Text("Gate Time between Triggers")
                    Text("Trigger Source and Mode")
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


// MARK: - Bottom

struct EnvelopeMonitorViewOverlay: View {
    var body: some View {
        Color.white.opacity(0.9)
            .overlay {
                VStack {
                    Text("Incoming Trigger Envelope (Edit Level 6)")
                        .bold()
                    Text("Envelope Attack and Release Trigger Points")
                    Text("Velocity Level")
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct LFOViewOverlay: View {
    var body: some View {
        Color.green.opacity(0.9)
            .overlay {
                VStack {
                    Text("Low Frequency Oscillator")
                        .bold()
                    
                    Text("Right Click on Wave to change Shape")
                    
                    Text("Speed Modulation Controls")
                    Text("Modulation Source")
                        .italic()
                }
                .foregroundStyle(.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct ModulationSourcesViewOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(Gradient(colors: [.yellow, .red, .orange, .blue, .green]).opacity(0.9))
            .overlay {
                VStack {
                    Text("Currently Selected")
                    Text("Modulation Sources")
                }
                .foregroundStyle(.black)
                .bold()
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

