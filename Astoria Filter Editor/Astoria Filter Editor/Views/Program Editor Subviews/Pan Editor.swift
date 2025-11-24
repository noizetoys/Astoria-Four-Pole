//
//  Pan Editor.swift
//  Astoria Filter Editor
//
//  Created by James Majors on 11/22/25.
//

import SwiftUI

struct Pan_Editor: View {
    var program: MiniWorksProgram
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("Panning")
                    .bold()
                
                PanControl(value: program.panning.knobBinding)
                    .padding()
//                    .frame(maxHeight: 40)
                
                
                HStack {
                    VStack(alignment: .leading) {
                        GroupBox {
                            Text("GateTime")
                            
                            Slider(value: program.gateTime.doubleBinding, in: 0...127)
                                .padding(10)
//                                .padding(.top, -10)
//                        }
//                        
//                        GroupBox {
//                            VStack(alignment: .trailing, spacing: 10) {
                                
                                Text("Trigger")
                                    .frame(maxWidth: .infinity)
                                
                                Picker("Source", selection: triggerSourceBinding()) {
                                    ForEach(TriggerSource.allCases, id: \.self) { source in
                                        Text(source.rawValue).tag(source)
                                    }
                                }
                                
                                Picker("Mode", selection: triggerModeBinding()) {
                                    ForEach(TriggerMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                
//                            }
                        }
                        .bold()
                    }
                    
                    GroupBox {
                        VStack {
                            VStack {
                                PercentageArrowView(rawValue: program.panningModulationAmount.doubleBinding)
                                    .offset(y: 5)
                                
                                Text("Modulation Amount")
                            }
//                            .padding(.bottom)
                            
                            VStack(spacing: 0) {
                                ArrowPickerGlowView(selection: program.panningModulationSource.modulationBinding,
                                                    direction: .left,
                                                    arrowColor: .green)
//                                .padding(.horizontal, 10)
//                                .padding(.top)
                                
                                Text("Modulation Source")
                                    .padding(.top)
                            }
                        }
                        
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: geo.size.width / 2)
                    .padding([.bottom, .trailing])
                    
                }
            } // HStack
        }
        
    }
    
    
        // MARK: - Trigger Source

    private var selectedTriggerSource: TriggerSource {
        if case .trigger(let source) = program.triggerSource.containedParameter {
            return source
        }
        return .all
    }
    
    
    private func setTriggerSource(_ source: TriggerSource) {
        program.triggerSource.containedParameter = .trigger(source)
    }

    
    private func triggerSourceBinding() -> Binding<TriggerSource> {
        Binding(
            get: { selectedTriggerSource },
            set: { setTriggerSource($0) }
        )
    }

    
    // MARK: - Trigger Mode
    
    private var selectedTriggerMode: TriggerMode {
        if case .mode(let source) = program.triggerSource.containedParameter {
            return source
        }
        return .multi
    }
    
    
    private func setTriggerMode(_ source: TriggerMode) {
        program.triggerMode.containedParameter = .mode(source)
    }
    
    
    private func triggerModeBinding() -> Binding<TriggerMode> {
        Binding(
            get: { selectedTriggerMode },
            set: { setTriggerMode($0) }
        )
    }

}


#Preview {
    @Previewable @State var program: MiniWorksProgram = .init()
    Pan_Editor(program: program)
        .frame(maxWidth: 400, maxHeight: 260)
}
