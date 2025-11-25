//
//  ProgramTag.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/25/25.
//

import SwiftUI


struct ProgramTag {
    var title: String
    var backgroundColor: Color
    var textColor: Color
}



    // MARK: - Program Tag Codable

/**
 Serializable representation of a program tag.
 
 Colors are stored as hex strings for readability and ease of editing.
 */
struct ProgramTagCodable: Codable {
    let title: String
    let backgroundColorHex: String
    let textColorHex: String
    
    init(tag: ProgramTag) {
        self.title = tag.title
        self.backgroundColorHex = tag.backgroundColor.toHex()
        self.textColorHex = tag.textColor.toHex()
    }
    
    func toTag() -> ProgramTag {
        ProgramTag(
            title: title,
            backgroundColor: Color(hex: backgroundColorHex),
            textColor: Color(hex: textColorHex)
        )
    }
}

