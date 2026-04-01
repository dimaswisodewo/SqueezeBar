//
//  OutputFolderSectionView.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 01/04/26.
//

import SwiftUI
import AppKit

struct OutputFolderSectionView: View {
    @ObservedObject var settings: AppSettings
    var isDisabled: Bool
    var panelMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "folder.fill", title: "Save Location")

            if let url = settings.outputFolderURL {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(DesignTokens.Candy.blue)
                            .font(.system(size: 11))

                        Text(url.lastPathComponent)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)

                        Spacer()

                        Button(action: { settings.openDestinationFolder() }) {
                            Text("Open")
                                .font(DesignTokens.Typography.tiny)
                                .foregroundStyle(DesignTokens.Candy.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDisabled)
                        .hoverScale(1.05)

                        Button(action: selectOutputFolder) {
                            Text("Change")
                                .font(DesignTokens.Typography.tiny)
                                .foregroundStyle(DesignTokens.Candy.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDisabled)
                        .hoverScale(1.05)
                    }
                    .padding(DesignTokens.Spacing.sm)
                    .background(DesignTokens.Candy.blue.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))

                    Text(url.path)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(DesignTokens.Candy.peach)
                            .font(.system(size: 11))

                        Text("No folder selected")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Candy.peach)
                    }
                    .padding(DesignTokens.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Candy.peach.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))

                    Button(action: selectOutputFolder) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 11))
                            Text("Choose Location")
                                .font(DesignTokens.Typography.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .foregroundStyle(.white)
                        .background(DesignTokens.Candy.blue)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .hoverScale(1.02)
                }
            }
        }
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
            DispatchQueue.main.async {
                settings.outputFolderURL = selectedURL
            }
        }
    }
}
