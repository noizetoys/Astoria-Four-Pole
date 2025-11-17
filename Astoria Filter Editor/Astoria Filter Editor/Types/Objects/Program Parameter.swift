//
//  Program Parameter.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/15/25.
//

import Foundation
import SwiftUI


@Observable
final class ProgramParameter: Identifiable {
    let id: UUID = UUID()
    
    let type: MiniWorksParameter
    
    var _value: UInt8
    var doubleBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(self._value) },
            set: { self._value = UInt8($0) }
        )
    }
    
    var modulationSource: ModulationSource?
    var containedParameter: ContainedParameter?
    
    var name: String { type.rawValue }
    var ccValue: UInt8 { type.ccValue }
    var bitPosition: Int { type.bitPosition }
    var valueRange: ClosedRange<UInt8> { type.valueRange }
    var doubleRange: ClosedRange<Double> {
        let min: Double = Double(valueRange.lowerBound)
        let max: Double = Double(valueRange.upperBound)
        
        return min...max
    }
    
    var isModSource: Bool { type.isModulationSourceSelector }
    var isModAmount: Bool { type.isModulationAmount }
    var containedOptions: [ContainedParameter]? { type.containedOptions }
    
    
        /// A single place to read the currently selected option's raw value or the standard value.
    var value: UInt8 {
        if let contained = containedParameter {
            return contained.value
        }
        
        if let modSource = modulationSource {
            return modSource.rawValue
        }
        
        return _value
    }
    
    
        /// The available selectable options, if any.
    var availableOptions: [Any] {
        if type.isModulationSourceSelector {
            return ModulationSource.allCases
        }
        
        if let contained = type.containedOptions {
            return contained
        }
        
        return []
    }

    
    // MARK: - Lifecycle
    
    init(type: MiniWorksParameter, initialValue: UInt8 = 0) {
        self.type = type
        self._value = initialValue
        
        if type.isModulationSourceSelector {
            self.modulationSource = ModulationSource(rawValue: initialValue)
        }
        
        if type.containedOptions != nil {
            self.containedParameter = type.containedOptions?.first(where: { $0.value == initialValue })
        }
    }
    
    
    convenience
    init(type: MiniWorksParameter, bytes: [UInt8]) {
        let initialValue = bytes[0]
        self.init(type: type, initialValue: initialValue)
    }
    
    
    // MARK: - Public
    
        // A robust method to update the parameter's state based on a raw UInt8 value.
    func setValue(_ rawValue: UInt8) {
        guard valueRange.contains(rawValue) else { return }
        
        if let options = containedOptions, let selectedCase = options.first(where: { $0.value == rawValue }) {
                self.containedParameter = selectedCase
        }
        
        else if type.isModulationSourceSelector, let selectedSource = ModulationSource(rawValue: rawValue) {
                self.modulationSource = selectedSource
        }
        
        self._value = rawValue
    }
    
    
    func use(bytes: [UInt8]) {
        _value = bytes[bitPosition]
    }
    
}


extension ClosedRange<UInt8> { // where Bound == UInt8 {
    // Convert to an integer range
    func convert<T: BinaryInteger>(to type: T.Type) -> ClosedRange<T> {
        T(self.lowerBound)...T(self.upperBound)
    }

    // Convert to a floating-point range
    func convert<T: BinaryFloatingPoint>(to type: T.Type) -> ClosedRange<T> {
        T(self.lowerBound)...T(self.upperBound)
    }
}


extension ProgramParameter: CustomStringConvertible {
    var description: String {
        var options: String = ""
        
        // For Testing
//        if modulationSource != nil || containedParameter != nil {
//            options = availableOptions.map({
//                switch $0 {
//                    case is ModulationSource:
//                        let item = $0 as! ModulationSource
//                        return "\t\t\(item.name)"
//                        
//                    case is ContainedParameter:
//                        let item = $0 as! ContainedParameter
//                        return "\t\t\(item.name)"
//
//                    default: return ""
//                }
//            }).joined(separator: ",\n ")
//        }
        
        let mod = modulationSource != nil ? "(mod): \(modulationSource!.name),\n\tOptions: \n\(options)"  : ""
    
        let cont = containedParameter != nil ? "(contained): \(containedParameter!.name),\n\tOptions: \n\(options)" : ""
        
        return "[\(bitPosition)] \(name): value: \(value), cc: \(ccValue), \(mod)\(cont)"
    }
}

