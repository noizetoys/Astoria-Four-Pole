//
//  Modulation Destination View.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

struct Modulation_Destination_View: View {
//    let destinations = ["Cutoff", "Resonance", "Panning"]
    let destinations: [String] = []

    var body: some View {
        VStack {
            Text("Modulation Destinations")
                .multilineTextAlignment(.center)
            
            if destinations.isEmpty {
                Spacer()
                Text("None")
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            else {
                ForEach(destinations, id: \.self) { mod in
                    Color
                        .green
                        .cornerRadius(5)
                    //                    .padding(.horizontal, 5)
                        .overlay {
                            Text(mod)
                        }
                }
                .background(.orange)
                .cornerRadius(10)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    Modulation_Destination_View()
}
