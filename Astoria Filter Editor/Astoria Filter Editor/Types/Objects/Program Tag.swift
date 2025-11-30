//
//  ProgramTag.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import SwiftUI


struct ProgramTag: Identifiable, Hashable, Codable {
    var id: String { "\(name)-\(color.description)"}
    let name: String
    let color: Color
    let shape: ProgramTagShape
    
    enum CodingKeys: String, CodingKey {
        case id, name, colorComponents, shape
    }
    
    init(name: String, color: Color, shape: ProgramTagShape = .capsule) {
        self.name = name
        self.color = color
        self.shape = shape
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        shape = try container.decode(ProgramTagShape.self, forKey: .shape)
        
        let components = try container.decode([Double].self, forKey: .colorComponents)
        color = Color(red: components[0],
                      green: components[1],
                      blue: components[2],
                      opacity: components[3])
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(shape, forKey: .shape)
        
        let nsColor = NSColor(color)
        let components = [
            Double(nsColor.redComponent),
            Double(nsColor.greenComponent),
            Double(nsColor.blueComponent),
            Double(nsColor.alphaComponent),
        ]
        try container.encode(components, forKey: .colorComponents)
    }
    
    
}





    // MARK: - Program Tag Codable


/**
 Serializable representation of a program tag.
 
 Colors are stored as hex strings for readability and ease of editing.
 */
//struct ProgramTagCodable: Codable {
//    let title: String
//    let backgroundColorHex: String
//    let textColorHex: String
//    
//    init(tag: ProgramTag) {
//        self.title = tag.title
//        self.backgroundColorHex = tag.backgroundColor.toHex()
//        self.textColorHex = tag.textColor.toHex()
//    }
//    
//    func toTag() -> ProgramTag {
//        ProgramTag(
//            title: title,
//            backgroundColor: Color(hex: backgroundColorHex),
//            textColor: Color(hex: textColorHex)
//        )
//    }
//}

