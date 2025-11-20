//
//  ModSource.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/19/25.
//
import Foundation



// MARK: - Models

//struct ModSource: Identifiable, Hashable {
//    let id: Int
//    let name: String
//}


enum FilterFillStyle: String, CaseIterable, Identifiable {
    case none
    case soft
    case strong
    case cutoffGlow
    case strongGlow      // 👈 NEW
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
            case .none:       return "None"
            case .soft:       return "Soft"
            case .strong:     return "Strong"
            case .cutoffGlow: return "Cutoff Glow"
            case .strongGlow: return "Strong + Glow"   // 👈 NEW
        }
    }
}
