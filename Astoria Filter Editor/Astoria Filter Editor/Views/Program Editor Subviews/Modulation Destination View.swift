//
//  Modulation Destination View.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

struct Modulation_Destination_View: View {
//    let destinations = ["Cutoff", "Resonance", "Panning"]
    @State private var destinations: [MiniWorksParameter] = []
    
    private var destinationNames: Set<String> {
        Set<String>(destinations.map(\.rawValue))
    }
    
    private let type: ModulationSource
    
    init(type: ModulationSource) {
        self.type = type
        debugPrint(message: "type: \(type) or \(type.rawValue)!)")
    }
    

    var body: some View {
        VStack {
            Text("Modulation Destinations")
                .multilineTextAlignment(.center)
            
            if destinationNames.isEmpty {
                Spacer()
                Text("None")
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            else {
                ForEach(Array(destinationNames).sorted(), id: \.self) { mod in
                    Color
                        .green
                        .cornerRadius(5)
                        .overlay {
                            Text(mod)
                        }
                }
                .background(.orange)
                .cornerRadius(10)
            }
        }
        .frame(maxHeight: .infinity)
//        .onAppear {
//            destinations = []
//        }
        .onReceive(NotificationCenter.default.publisher(for: .programParameterUpdated)) { notification in
            debugPrint(icon: "❎", message: "received notification: data: \(notification.userInfo?.debugDescription)", type: .info)
            
            guard
                let userInfo = notification.userInfo,
                let type = userInfo[SysExConstant.parameterType] as? MiniWorksParameter,
                type.isModulationSourceSelector
            else {
                debugPrint(message: "Invalid notification. Skipping.")
                return
            }
                
                
//            for (key, value) in userInfo {
//                print("key: \(key), value: \(value)")
//            }
            
//            let type = userInfo[SysExConstant.parameterType] as? MiniWorksParameter
            let value = userInfo[SysExConstant.parameterValue] as? UInt8
//            print("type: \(type?.rawValue ?? "nil"), value: \(value?.hexString ?? "No Value")")
//            print("isModulationSource: \(type?.isModulationSourceSelector ?? false)")
            let valueType = ModulationSource(rawValue: value ?? 0)
//            print("valueType : \(valueType?.rawValue)")
//            print("Current Type: \(self.type.rawValue), source: \(self.type.rawValue)")

            guard
//                let data = notification.userInfo,
//                let type = userInfo[SysExConstant.parameterType] as? MiniWorksParameter,
//                let value = userInfo[SysExConstant.parameterValue] as? UInt8,
//                let type,
                let value,
                type.isModulationSourceSelector,
//                  let source = ModulationSource(rawValue: value),
                let valueType,
                valueType == self.type
            else {
                debugPrint(icon: "❌❎", message: "Not a Modulation Source Selector. Skipping.\n \(notification.userInfo?.debugDescription)", type: .info)
                return
            }

            debugPrint(icon: "💕", message: "type: \(type), value: \(value), valueType: \(valueType)", type: .info)
            
            Task { @MainActor in
                if case .off = valueType {
                    debugPrint(icon: "📤", message: "\n -----> Turning off Modulation Source: \(type), self is: \(self.type)", type: .info)
                    self.destinations.removeAll { $0 == type }
                }
                else if valueType.relatedSources.contains(valueType){
                    debugPrint(icon: "✅", message: "Adding Modulation: \(type), self is: \(self.type)", type: .info)
                    destinations.append(type)
                    debugPrint(icon: "✅", message: "Modulation Destinations: [\(destinations)]", type: .info)
                }
            }
            
        }

    }
}


#Preview {
    Modulation_Destination_View(type: .lfo)
}
