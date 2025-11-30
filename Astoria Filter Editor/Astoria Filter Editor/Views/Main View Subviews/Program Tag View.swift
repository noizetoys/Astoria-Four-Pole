//
//  Program Tag View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/26/25.
//

import SwiftUI


struct ProgramTagView: View {
    let tagItem: ProgramTag
    @State var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    
    var body: some View {
        if tagItem.shape == .capsule {
            capsuleTag
        }
        else if tagItem.shape == .roundedRectangle {
            rectangleTag
        }
    }
    
    
    private var capsuleTag: some View {
        Text(tagItem.name)
            .font(.caption)
            .fontWeight(.medium)
            .frame(height: 20)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isSelected ? tagItem.color : tagItem.color.opacity(0.2))
            }
            .foregroundStyle(isSelected ? .white : tagItem.color)
            .overlay(
                Capsule()
                    .strokeBorder(tagItem.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .onTapGesture {
                onTap?()
            }
    }
    
    
    private var rectangleTag: some View {
        Text(tagItem.name)
            .font(.caption)
            .fontWeight(.medium)
            .frame(height: 20)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? tagItem.color : tagItem.color.opacity(0.2))
            }
            .foregroundStyle(isSelected ? .white : tagItem.color)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(tagItem.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .onTapGesture {
                onTap?()
            }
    }
    
}


enum ProgramTagShape: String, CaseIterable, Codable {
    case capsule = "Capsule"
    case roundedRectangle = "Rounded"
    
    var iconName: String {
        switch self {
            case .capsule: return "capsule"
            case .roundedRectangle: return "square"
        }
    }
    
}


#Preview {
    ScrollView{
        VStack {
            ForEach(triggerSourceTags) { tag in
                ProgramTagView(tagItem: tag)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
}
