//
//  Modulation Destination View.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/23/25.
//

import SwiftUI

struct Modulation_Destination_View: View {
    enum ModSourceFilter: String, Identifiable, CaseIterable {
        var id: Self { self }
        
        case sources = "Sources"
        case destinations = "Destinations"
    }
    
    
    @State private var sortFilter: ModSourceFilter = .sources
    
    let program: MiniWorksProgram
    

    var body: some View {
        VStack {
            
            Text("Modulation Sources:")
                .bold()
                .font(.title)
//            Picker("Mod ", selection: $sortFilter) {
//                ForEach(ModSourceFilter.allCases) { filter in
//                    Text(filter.rawValue)
//                        .tag(filter)
//                }
//            }
//            .padding(10)
            
            
            if sortFilter == .destinations {
                
                VStack(alignment: .leading, spacing: 5) {
                    if modDestinations.isEmpty {
                        Spacer()
                        
                        Text("No Destinations Selected")
                    }
                    else {
                        ForEach(Array(modDestinations.keys), id: \.self) { key in
                            destinationCell(key: key)
                        }
                    }
                    
                    Spacer()
                }
            }
            else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(program.modParameters, id: \.self) { parameter in
                        sourceCell(parameter: parameter)
                    }
                    
                    Spacer()
                }
            }
            
        }
        
    }
    
    
    private func destinationCell(key: ModulationSource) -> some View {
        VStack {
            HStack {
                Text(key.shortName)
                    .bold()
                Spacer()
            }
            
            ForEach(modDestinations[key] ?? [], id: \.self) { value in
                HStack {
                    Text(value)
                        .padding(.leading)
                    Spacer()
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .foregroundStyle(.black)
        .background {
            key.color
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
    
    
    private func sourceCell(parameter: ProgramParameter) -> some View {
        let shouldBeDim = parameter.modulationSource == nil || parameter.modulationSource == .off
        
        return VStack(alignment: .leading) {
            HStack {
                Text("\(parameter.type.modulationShortName):")
                    .bold()
                
                Text(parameter.modulationSource?.name ?? "Off")
                Spacer()
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.black)
        .background {
            parameter.type.color.opacity(shouldBeDim ? 0.5 : 1)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }

    }
    

    private var modDestinations: [ModulationSource: [String]] {
        var modDict: [ModulationSource: [String]] = [:]
        
        debugPrint(icon: "🔥", message: "Will This work????", type: .trace)
        
        for parameter in program.modParameters {
            print("\t\tParameter: \(parameter.type.modulationShortName)")
            if let parameterSource = parameter.modulationSource, parameterSource.isLocalModSource {
                print("paramaterSource: \(parameterSource)")
                
                if let values = modDict[parameterSource] {
                    modDict[parameterSource] = values + [parameter.type.modulationShortName]
                }
                else {
                    modDict[parameterSource] = [parameter.type.modulationShortName]
                }
                
                print("mods...\(modDict)")
            }
//            else {
//                print("Not a modulation source....")
//            }
        }
        
        return modDict
    }
    
    
}


#Preview {
    let viewModel = MainViewModel(profile:  MiniworksDeviceProfile.newMachineConfiguration())
    let program = MiniWorksProgram.init()
    // Source
//    program.cutoffModulationSource.modulationSource = ModulationSource.aftertouch
//    program.resonanceModulationSource.modulationSource = ModulationSource.breathControl
//    program.volumeModulationSource.modulationSource = ModulationSource.footcontroller
//    program.lfoSpeedModulationSource.modulationSource = ModulationSource.keytrack
//    program.panningModulationSource.modulationSource = ModulationSource.lfo

    // Destinations
    program.cutoffModulationSource.modulationSource = ModulationSource.lfo
    program.resonanceModulationSource.modulationSource = ModulationSource.vcaEnvelope
    program.volumeModulationSource.modulationSource = ModulationSource.lfo
    program.lfoSpeedModulationSource.modulationSource = ModulationSource.keytrack
    program.panningModulationSource.modulationSource = ModulationSource.lfo

//    viewModel.program = program
    
    return Modulation_Destination_View(program: program)
//    return Modulation_Destination_View(viewModel: viewModel)
        .frame(maxWidth: 220, maxHeight: 267)
}
