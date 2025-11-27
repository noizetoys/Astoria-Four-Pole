//
//  Tag Item View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/26/25.
//

import SwiftUI


//struct TagItem: Identifiable, Hashable {
//    var id: String { "\(name)-\(color.description)"}
//    let name: String
//    let color: Color
//}
//
//fileprivate let sampleTags: [Tag] = [
//    Tag(name: "Guitar", color: .blue),
////    Tag(name: "Keys", color: .green),
////    Tag(name: "Drum", color: .red),
//    
//    Tag(name: "Short", color: .purple),
//    Tag(name: "Drone", color: .orange),
//    
////    Tag(name: "Finance", color: .yellow),
////    Tag(name: "Health", color: .pink),
////    Tag(name: "Travel", color: .cyan),
////    Tag(name: "Shopping", color: .indigo),
////    Tag(name: "Learning", color: .teal)
//]



struct Tag_Item_View: View {
    let tag: Tag
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Text(tag.name)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? tag.color : tag.color.opacity(0.2))
            )
            .foregroundStyle(isSelected ? .white : tag.color)
            .overlay(
                Capsule()
                    .strokeBorder(tag.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .onTapGesture {
                onTap?()
            }
    }
}




#Preview {
    let tags = sampleTags
    
    HStack {
        Tag_Item_View(tag: sampleTags.randomElement() ?? Tag(name: "None", color: .black))

    }
}


