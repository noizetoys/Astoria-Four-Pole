
import SwiftUI

struct ProgramTag: Identifiable, Hashable, Codable {
    var id: String { "\(name)-\(color.description)"}
    let name: String
    let color: Color
    let shape: ProgramTagShape
    
    enum CodingKeys: String, CodingKey {
        case id, name, colorComponents, shape
    }
    
    init(name: String, color: Color, shape: ProgramTagShape = .circle) {
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


enum ProgramTagShape: String, CaseIterable, Codable {
    case capsule = "Capsule"
    case roundedRectangle = "Rounded"
    case circle = "Circle"
    case diamond = "Diamond"
    
    var iconName: String {
        switch self {
            case .capsule: return "capsule"
            case .roundedRectangle: return "square"
            case .circle: return "circle"
            case .diamond: return "diamond"
        }
    }
    
    
    var tagShape: AnyShape {
        switch self {
            case .capsule:
                AnyShape(Capsule())
            case .roundedRectangle:
                AnyShape(RoundedRectangle(cornerRadius: 6))
            case .circle:
                AnyShape(Circle())
            case .diamond:
                AnyShape(Diamond())
        }
    }
}


// MARK: - AnyShape

struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}


extension AnyShape {
    func strokeBorder<S: ShapeStyle>(
        _ content: S,
        lineWidth: CGFloat = 1
    ) -> some View {
        ZStack {
            self.fill(Color.clear)
            self.stroke(content, lineWidth: lineWidth)
        }
        .padding(lineWidth / 2)
    }
    
    func strokeBorder(
        lineWidth: CGFloat = 1
    ) -> some View {
        strokeBorder(.foreground, lineWidth: lineWidth)
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        }
    }
}


// MARK: - AnyInsettableShape

struct AnyInsettableShape: InsettableShape {
    private let _path: @Sendable (CGRect) -> Path
    private let _inset: @Sendable (CGFloat) -> AnyInsettableShape
    
    init<S: InsettableShape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
        _inset = { amount in
            AnyInsettableShape(shape.inset(by: amount))
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
    
    func inset(by amount: CGFloat) -> AnyInsettableShape {
        _inset(amount)
    }
}

struct InsettableDiamond: InsettableShape {
    var insetAmount: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        let adjustedRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return Path { path in
            path.move(to: CGPoint(x: adjustedRect.midX, y: adjustedRect.minY))
            path.addLine(to: CGPoint(x: adjustedRect.maxX, y: adjustedRect.midY))
            path.addLine(to: CGPoint(x: adjustedRect.midX, y: adjustedRect.maxY))
            path.addLine(to: CGPoint(x: adjustedRect.minX, y: adjustedRect.midY))
            path.closeSubpath()
        }
    }
    
    func inset(by amount: CGFloat) -> InsettableDiamond {
        var diamond = self
        diamond.insetAmount += amount
        return diamond
    }
}


struct ProgramTagView: View {
    let tagItem: ProgramTag
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    
    var body: some View {
        Text(tagItem.name)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                tagShape
                    .fill(isSelected ? tagItem.color : tagItem.color.opacity(0.2))
            )
            .foregroundStyle(isSelected ? .white : tagItem.color)
            .overlay(
                tagShape
                    .strokeBorder(tagItem.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .onTapGesture {
                onTap?()
            }
    }
    
    
    private var tagShape: AnyShape {
        switch tagItem.shape {
            case .capsule:
                AnyShape(Capsule())
            case .roundedRectangle:
                AnyShape(RoundedRectangle(cornerRadius: 6))
            case .circle:
                AnyShape(Circle())
            case .diamond:
                AnyShape(Diamond())
        }
    }}



#Preview {
    
}
