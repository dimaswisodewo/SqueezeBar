import SwiftUI

struct BrutalistPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let palette = DesignTokens.Palette(colorScheme)
        content
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(palette.ink)
            .background(palette.surface)
            .overlay(Rectangle().strokeBorder(palette.outline, lineWidth: DesignTokens.Geometry.border))
            .background {
                Rectangle().fill(palette.outline)
                    .offset(x: DesignTokens.Geometry.shadowOffset, y: DesignTokens.Geometry.shadowOffset)
            }
            .padding(.trailing, DesignTokens.Geometry.shadowOffset)
            .padding(.bottom, DesignTokens.Geometry.shadowOffset)
    }
}

struct BrutalistSectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.label)
            .foregroundStyle(DesignTokens.Colors.ink)
    }
}

/// Native buttons retain keyboard activation, focus, and disabled semantics.
struct BrutalistButtonStyle: ButtonStyle {
    var isPrimary = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let palette = DesignTokens.Palette(colorScheme)
        let raised = isPrimary && isEnabled
        let pressed = configuration.isPressed && isEnabled
        let offset = raised && !pressed ? DesignTokens.Geometry.shadowOffset : 0
        configuration.label
            .font(DesignTokens.Typography.heading)
            .foregroundStyle(isPrimary && isEnabled ? DesignTokens.Colors.black : palette.ink)
            .background(isPrimary && isEnabled ? palette.accent : (isHovered && isEnabled ? palette.inset : palette.surface))
            .overlay(Rectangle().strokeBorder(palette.outline, lineWidth: DesignTokens.Geometry.border))
            .background {
                Rectangle().fill(raised ? palette.outline : .clear).offset(x: offset, y: offset)
            }
            .overlay {
                if isFocused {
                    Rectangle().strokeBorder(palette.ink, style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                        .padding(-4)
                }
            }
            .offset(x: raised && pressed && !reduceMotion ? 2 : 0,
                    y: raised && pressed && !reduceMotion ? 2 : 0)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(reduceMotion ? nil : DesignTokens.Motion.press, value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

struct BrutalistQuietButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let palette = DesignTokens.Palette(colorScheme)
        configuration.label
            .font(DesignTokens.Typography.heading)
            .foregroundStyle(palette.ink)
            .background((isHovered || configuration.isPressed) && isEnabled ? palette.inset : .clear)
            .overlay(alignment: .bottom) {
                if isFocused || (isHovered && isEnabled) {
                    Rectangle().fill(palette.ink).frame(height: 2)
                }
            }
            .opacity(isEnabled ? 1 : 0.5)
            .onHover { isHovered = $0 }
    }
}

struct BrutalistPrimaryButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right").resizable().scaledToFit().frame(width: 15, height: 15)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .frame(height: DesignTokens.Geometry.actionHeight)
        }
        .buttonStyle(BrutalistButtonStyle(isPrimary: true))
        .disabled(isDisabled)
        .padding(.trailing, DesignTokens.Geometry.shadowOffset)
        .padding(.bottom, DesignTokens.Geometry.shadowOffset)
    }
}

struct BrutalistChoiceChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        let palette = DesignTokens.Palette(colorScheme)
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark").resizable().scaledToFit().frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                }
                Text(title).font(DesignTokens.Typography.heading)
                    .lineLimit(2).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: title.count > 18 ? DesignTokens.Geometry.actionHeight : DesignTokens.Geometry.controlHeight)
            .foregroundStyle(palette.ink)
            .background(isSelected ? palette.selection : palette.surface)
        }
        .buttonStyle(BrutalistButtonStyle())
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct BrutalistActionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let symbol: String
    let isSelected: Bool
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        let palette = DesignTokens.Palette(colorScheme)
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: symbol).resizable().scaledToFit().frame(width: 16, height: 16).frame(width: 24)
                Text(title).font(DesignTokens.Typography.heading)
                Spacer()
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .resizable().scaledToFit().frame(width: 17, height: 17)
            }
            .foregroundStyle(palette.ink)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(height: DesignTokens.Geometry.actionHeight)
            .background(isSelected ? palette.selection : palette.surface)
        }
        .buttonStyle(BrutalistButtonStyle())
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct BrutalistBadge: View {
    let title: String
    var highlighted = false

    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.metadata)
            .foregroundStyle(highlighted ? DesignTokens.Colors.black : DesignTokens.Colors.ink)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(highlighted ? DesignTokens.Colors.lime : DesignTokens.Colors.canvas)
            .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
    }
}

struct BrutalistMark: View {
    var body: some View {
        Image(systemName: "arrow.down.right.and.arrow.up.left")
            .resizable().scaledToFit().frame(width: 23, height: 23)
            .foregroundStyle(DesignTokens.Colors.black)
            .frame(width: 44, height: 44)
            .background(DesignTokens.Colors.lime)
            .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
            .accessibilityHidden(true)
    }
}

struct BrutalistDropSurface<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let isHighlighted: Bool
    private let content: Content

    init(isHighlighted: Bool, @ViewBuilder content: () -> Content) {
        self.isHighlighted = isHighlighted
        self.content = content()
    }

    var body: some View {
        let palette = DesignTokens.Palette(colorScheme)
        content
            .frame(maxWidth: .infinity)
            .foregroundStyle(palette.ink)
            .background(palette.surface)
            .overlay(alignment: .top) {
                if isHighlighted { Rectangle().fill(palette.notice).frame(height: 5) }
            }
            .overlay {
                Rectangle().strokeBorder(palette.outline,
                    style: StrokeStyle(lineWidth: DesignTokens.Geometry.border, dash: isHighlighted ? [] : [8, 4]))
            }
    }
}

struct BrutalistStatusPanel: View {
    enum Tone { case error, notice, success }
    let title: String
    let message: String
    let symbol: String
    let tone: Tone

    var body: some View {
        BrutalistPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: symbol).resizable().scaledToFit().frame(width: 18, height: 18)
                    Text(title).font(DesignTokens.Typography.status)
                }
                .foregroundStyle(tone == .error ? DesignTokens.Colors.ink : DesignTokens.Colors.black)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tone == .error ? DesignTokens.Colors.inset :
                            DesignTokens.Colors.yellow)
                Text(message).font(DesignTokens.Typography.body).fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct BrutalistSecureField: View {
    let title: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        SecureField(title, text: $text)
            .textFieldStyle(.plain)
            .font(DesignTokens.Typography.body)
            .padding(12)
            .foregroundStyle(DesignTokens.Colors.ink)
            .background(DesignTokens.Colors.inset)
            .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
            .overlay(alignment: .bottom) {
                if isFocused { Rectangle().fill(DesignTokens.Colors.ink).frame(height: 4) }
            }
            .focused($isFocused)
            .accessibilityLabel(title)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

struct BrutalistToggleStyle: ToggleStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let palette = DesignTokens.Palette(colorScheme)
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .resizable().scaledToFit().frame(width: 12, height: 12)
                    .opacity(configuration.isOn ? 1 : 0)
                    .foregroundStyle(DesignTokens.Colors.black)
                    .frame(width: 24, height: 24)
                    .background(configuration.isOn ? palette.accent : palette.surface)
                    .overlay(Rectangle().strokeBorder(palette.ink, lineWidth: DesignTokens.Geometry.border))
                configuration.label.font(DesignTokens.Typography.heading)
                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .buttonStyle(BrutalistButtonStyle())
        // Keep the toggle's accessibility role and value while the native button
        // supplies keyboard activation and focus for the custom presentation.
        .accessibilityRepresentation {
            Toggle(configuration).toggleStyle(.checkbox)
        }
    }
}
