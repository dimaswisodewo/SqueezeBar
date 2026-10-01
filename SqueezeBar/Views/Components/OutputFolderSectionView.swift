import SwiftUI
import AppKit

struct OutputFolderSectionView: View {
    @ObservedObject var settings: AppSettings
    var isDisabled: Bool
    var panelMessage: String
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !compact { BrutalistSectionLabel(title: "Save location") }
            HStack(spacing: 12) {
                Image(systemName: "folder").font(.system(size: 20, weight: .bold))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    if compact { BrutalistSectionLabel(title: "Save to") }
                    Text(settings.outputFolderURL?.lastPathComponent ?? "Choose an output folder")
                        .font(DesignTokens.Typography.heading)
                        .lineLimit(1).truncationMode(.middle)
                }
                Spacer(minLength: 0)
                if settings.outputFolderURL != nil && !compact {
                    Button("Open") { settings.openDestinationFolder() }
                        .font(DesignTokens.Typography.heading)
                        .buttonStyle(BrutalistQuietButtonStyle())
                        .disabled(isDisabled)
                }
                Button(action: selectOutputFolder) {
                    Text(settings.outputFolderURL == nil ? "CHOOSE" : "CHANGE")
                        .font(DesignTokens.Typography.label)
                        .padding(.horizontal, 12).frame(height: 36)
                }
                .buttonStyle(BrutalistButtonStyle())
                .disabled(isDisabled)
                .accessibilityLabel(settings.outputFolderURL == nil ? "Choose save folder" : "Change save folder")
            }
            if !compact {
                if let url = settings.outputFolderURL {
                    Text(url.path).font(DesignTokens.Typography.metadata)
                        .foregroundStyle(DesignTokens.Colors.muted)
                        .lineLimit(1).truncationMode(.middle)
                } else {
                    Label("No output folder selected", systemImage: "exclamationmark.triangle")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.black)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignTokens.Colors.yellow)
                }
            }
        }
        .foregroundStyle(DesignTokens.Colors.ink)
        .help(settings.outputFolderURL?.path ?? "Choose where to save processed files")
    }

    private func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = panelMessage
        panel.prompt = "Choose"
        if panel.runModal() == .OK {
            let selectedURL = panel.url
            DispatchQueue.main.async { settings.outputFolderURL = selectedURL }
        }
    }
}
