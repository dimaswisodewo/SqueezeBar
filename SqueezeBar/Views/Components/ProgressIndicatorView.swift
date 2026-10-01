import SwiftUI

struct ProgressIndicatorView: View {
    let isCompressing: Bool
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            if isCompressing { ProgressView().controlSize(.small) }
            Text(message).font(DesignTokens.Typography.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(DesignTokens.Colors.ink)
        .tint(DesignTokens.Colors.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(DesignTokens.Colors.inset)
        .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
    }
}

#Preview {
    VStack(spacing: 16) {
        ProgressIndicatorView(isCompressing: false, message: "Drop a file here")
        ProgressIndicatorView(isCompressing: true, message: "Working locally…")
    }
    .padding(20)
}
