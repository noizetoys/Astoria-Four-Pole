
import SwiftUI

// MARK: - Style

/// Visual style for the anchored presentation.
public enum AnchoredPopoverStyle {
    /// Compact bubble with arrow, good for short helper text.
    case bubble
    /// Slightly larger "card" popover, good for richer content.
    case popover
    /// Uses a bottom sheet instead of an anchored bubble (no arrow).
    case bottomSheet
}

// MARK: - AnchoredPopover

/// A reusable control that shows a SwiftUI view anchored to the button that spawned it,
/// behaving like a popover/bubble on macOS and iPadOS, or optionally as a bottom sheet.
///
/// Usage:
///
///     struct ExampleView: View {
///         var body: some View {
///             VStack {
///                 AnchoredPopover(
///                     style: .bubble,
///                     arrowEdge: .top,
///                     popoverContent: {
///                         VStack(alignment: .leading, spacing: 8) {
///                             Text("Help")
///                                 .font(.headline)
///                             Text("This is some contextual help related to the button.")
///                                 .font(.caption)
///                         }
///                         .padding()
///                     },
///                     label: {
///                         Label("Show Help", systemImage: "questionmark.circle")
///                     }
///                 )
///
///                 Spacer()
///             }
///             .padding()
///         }
///     }
///
/// - Note:
///   - On macOS and iPadOS with `style == .bubble` or `.popover`, the view is anchored
///     visually near the button using a custom overlay with an arrow.
///   - With `style == .bottomSheet`, the same content is presented in a `.sheet`
///     (not anchored with an arrow, but still conceptually spawned from the control).
public struct AnchoredPopover<Label: View, PopoverContent: View>: View {

    // MARK: - Public API

    public let style: AnchoredPopoverStyle
    public let arrowEdge: Edge
    public let popoverContent: () -> PopoverContent
    public let label: () -> Label

    // MARK: - Internal State

    @State private var isPresented: Bool = false
    @State private var anchorFrame: CGRect = .zero

    // Coordinate space name so we can measure in a stable space.
    private let coordinateSpaceName = "AnchoredPopoverSpace"

    // MARK: - Init

    public init(
        style: AnchoredPopoverStyle = .bubble,
        arrowEdge: Edge = .top,
        @ViewBuilder popoverContent: @escaping () -> PopoverContent,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.style = style
        self.arrowEdge = arrowEdge
        self.popoverContent = popoverContent
        self.label = label
    }

    // MARK: - Body

    @ViewBuilder
    public var body: some View {
        switch style {
        case .bottomSheet:
            bottomSheetBody
        case .bubble, .popover:
            anchoredBubbleBody
        }
    }

    // MARK: - Anchored Bubble / Popover Body

    private var anchoredBubbleBody: some View {
        ZStack(alignment: .topLeading) {
            buttonBody

            if isPresented {
                popoverBubble
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
    }

    // MARK: - Bottom Sheet Body

    private var bottomSheetBody: some View {
        buttonBody
            .sheet(isPresented: $isPresented) {
                VStack(spacing: 16) {
                    Capsule()
                        .frame(width: 40, height: 4)
                        .foregroundColor(.secondary)

                    popoverContent()
                        .padding(.horizontal)

                    Button("Close") {
                        isPresented = false
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 12)
                #if os(iOS)
                .presentationDetents([.medium, .large])
                #endif
            }
    }

    // MARK: - Button

    private var buttonBody: some View {
        Button(action: togglePresented) {
            label()
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: AnchorFramePreferenceKey.self,
                                value: proxy.frame(in: .named(coordinateSpaceName)))
            }
        )
        .onPreferenceChange(AnchorFramePreferenceKey.self) { newValue in
            anchorFrame = newValue ?? .zero
        }
    }

    private func togglePresented() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            isPresented.toggle()
        }
    }

    // MARK: - Popover Bubble

    @ViewBuilder
    private var popoverBubble: some View {
        let bubbleChrome: some View = VStack(spacing: 0) {
            if arrowEdge == .bottom {
                ArrowShape()
                    .fill(materialForCurrentStyle)
                    .frame(width: 16, height: 8)
                    .rotationEffect(.degrees(180))
            }

            popoverContent()
                .background(materialForCurrentStyle)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadiusForCurrentStyle,
                                            style: .continuous))
                .shadow(radius: shadowRadiusForCurrentStyle)

            if arrowEdge == .top {
                ArrowShape()
                    .fill(materialForCurrentStyle)
                    .frame(width: 16, height: 8)
            }
        }

        bubbleChrome
            .fixedSize(horizontal: false, vertical: true)
            .position(bubblePosition())
            .transition(.opacity.combined(with: .scale))
            .zIndex(1)
            .onTapGesture {
                // tap on bubble to dismiss
                withAnimation {
                    isPresented = false
                }
            }
    }

    // MARK: - Style-Specific Chrome

    private var materialForCurrentStyle: some ShapeStyle {
        switch style {
        case .bubble:
            return .thinMaterial
        case .popover:
            return .regularMaterial
        case .bottomSheet:
            return .thinMaterial
        }
    }

    private var cornerRadiusForCurrentStyle: CGFloat {
        switch style {
        case .bubble:
            return 12
        case .popover:
            return 16
        case .bottomSheet:
            return 16
        }
    }

    private var shadowRadiusForCurrentStyle: CGFloat {
        switch style {
        case .bubble:
            return 4
        case .popover:
            return 8
        case .bottomSheet:
            return 6
        }
    }

    // MARK: - Positioning

    private func bubblePosition() -> CGPoint {
        // Simple heuristic: align horizontally to the button's midX.
        // Vertically offset above or below the button depending on arrowEdge.
        let x = anchorFrame.midX

        let verticalOffset: CGFloat = 60 // approximate bubble height / distance
        let y: CGFloat
        switch arrowEdge {
        case .top:
            // bubble above button
            y = anchorFrame.minY - verticalOffset
        case .bottom:
            // bubble below button
            y = anchorFrame.maxY + verticalOffset / 2
        case .leading:
            y = anchorFrame.midY
        case .trailing:
            y = anchorFrame.midY
        }

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preference Key

/// Stores the frame of the anchor view (button) in the named coordinate space.
private struct AnchorFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        if let next = nextValue() {
            value = next
        }
    }
}

// MARK: - Arrow Shape

/// Small triangular arrow used to visually connect the bubble to the anchor control.
private struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Demo Preview (Optional)

struct AnchoredPopover_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Bubble
            AnchoredPopover(
                style: .bubble,
                arrowEdge: .top,
                popoverContent: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bubble Style")
                            .font(.headline)
                        Text("Compact helper text anchored to the button.")
                            .font(.caption)
                    }
                    .padding()
                },
                label: {
                    Label("Bubble", systemImage: "info.circle")
                }
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Bubble")

            // Popover
            AnchoredPopover(
                style: .popover,
                arrowEdge: .bottom,
                popoverContent: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Popover Style")
                            .font(.headline)
                        Text("Richer content with a slightly larger card.")
                            .font(.caption)
                    }
                    .padding()
                },
                label: {
                    Label("Popover", systemImage: "questionmark.circle")
                }
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Popover")

            // Bottom Sheet
            AnchoredPopover(
                style: .bottomSheet,
                arrowEdge: .top, // ignored for bottom sheet
                popoverContent: {
                    VStack(spacing: 8) {
                        Text("Bottom Sheet Style")
                            .font(.headline)
                        Text("Presented with `.sheet`, better for larger or more complex content.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                },
                label: {
                    Label("Bottom Sheet", systemImage: "square.and.arrow.up")
                }
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Bottom Sheet")
        }
    }
}
