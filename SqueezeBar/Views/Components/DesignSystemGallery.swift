#if DEBUG
import SwiftUI

/// Interactive specimens live in previews rather than the app's navigation.
struct DesignSystemGallery: View {
    @State private var quality: CompressionQuality = .medium
    @State private var value = 0.6
    @State private var reduceFrameRate = true
    @State private var password = ""
    @State private var selectedAction = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = DesignTokens.Palette(colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 12) {
                    BrutalistMark()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SqueezeBar").font(DesignTokens.Typography.title)
                        BrutalistSectionLabel(title: "Design system / 01")
                    }
                }
                Text("Start with a file")
                    .font(DesignTokens.Typography.hero).tracking(-0.8)
                HStack(spacing: 8) {
                    swatch("Ink", color: palette.ink, text: palette.canvas)
                    swatch("Paper", color: palette.surface, text: palette.ink)
                    swatch("Lime", color: palette.accent, text: DesignTokens.Colors.black)
                    swatch("Yellow", color: palette.notice, text: DesignTokens.Colors.black)
                }
                BrutalistPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        BrutalistSectionLabel(title: "Typography / source")
                        Text("holiday-photo-final-version-with-a-long-filename.jpg")
                            .font(DesignTokens.Typography.heading)
                            .lineLimit(2).truncationMode(.middle)
                        Text("JPEG · 12.4 MB · 4096 × 2160")
                            .font(DesignTokens.Typography.metadata).foregroundStyle(palette.muted)
                        Text("Readable body text. Files stay on your Mac.")
                            .font(DesignTokens.Typography.body)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    BrutalistSectionLabel(title: "Actions / selection")
                    BrutalistPrimaryButton(title: "Compress", isDisabled: false) {}
                    BrutalistPrimaryButton(title: "Disabled action", isDisabled: true) {}
                    BrutalistActionRow(title: "Compress", symbol: "arrow.down.right.and.arrow.up.left",
                                       isSelected: selectedAction) { selectedAction.toggle() }
                    BrutalistActionRow(title: "Change image format", symbol: "photo",
                                       isSelected: !selectedAction) { selectedAction.toggle() }
                    BrutalistActionRow(title: "Unavailable", symbol: "lock",
                                       isSelected: false, isDisabled: true) {}
                }
                BrutalistPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        BrutalistSectionLabel(title: "Quality")
                        BrutalistChoicePicker(selection: $quality, options: CompressionQuality.allCases,
                                              label: { $0.rawValue })
                        HStack {
                            Text("Custom quality").font(DesignTokens.Typography.heading)
                            Spacer()
                            BrutalistBadge(title: "\(Int(value * 100))%", highlighted: true)
                        }
                        BrutalistSlider(value: $value, range: 0.1...1, step: 0.05)
                            .frame(height: 32)
                        BrutalistSlider(value: .constant(0.6), range: 0.1...1, step: 0.05,
                                        isDisabled: true, title: "Disabled quality")
                            .frame(height: 32)
                        Toggle("Reduce frame rate", isOn: $reduceFrameRate)
                            .toggleStyle(BrutalistToggleStyle())
                        BrutalistSecureField(title: "Password", text: $password)
                    }
                }
                HStack(spacing: 8) {
                    BrutalistBadge(title: "JPEG")
                    BrutalistBadge(title: "M4A")
                    BrutalistBadge(title: "Ready", highlighted: true)
                }
                BrutalistDropSurface(isHighlighted: false) {
                    Label("Drop an image, video, or PDF", systemImage: "arrow.down.to.line")
                        .font(DesignTokens.Typography.heading).padding(20)
                }
                BrutalistDropSurface(isHighlighted: true) {
                    Label("Drop files here", systemImage: "arrow.down.to.line")
                        .font(DesignTokens.Typography.heading).padding(20)
                }
                ProgressIndicatorView(isCompressing: true, message: "Working locally on your Mac…")
                BrutalistStatusPanel(title: "Done", message: "Saved 8.2 MB. Ready to open in Finder.",
                                     symbol: "checkmark", tone: .success)
                BrutalistStatusPanel(title: "Choose a folder", message: "Select where to save processed files.",
                                     symbol: "folder", tone: .notice)
                BrutalistStatusPanel(title: "Couldn't finish",
                                     message: "This file could not be processed. Choose another file and try again. Longer error messages wrap without hiding the recovery guidance.",
                                     symbol: "exclamationmark.triangle", tone: .error)
            }
            .padding(20)
        }
        .frame(width: DesignTokens.Geometry.popoverWidth, height: 900)
        .foregroundStyle(palette.ink)
        .background(palette.canvas)
        .font(DesignTokens.Typography.body)
    }

    private func swatch(_ title: String, color: Color, text: Color) -> some View {
        Text(title).font(DesignTokens.Typography.label)
            .foregroundStyle(text)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(color)
            .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
    }
}

#Preview("Design system / Light") {
    DesignSystemGallery().preferredColorScheme(.light)
}

#Preview("Design system / Dark") {
    DesignSystemGallery().preferredColorScheme(.dark)
}

#endif
