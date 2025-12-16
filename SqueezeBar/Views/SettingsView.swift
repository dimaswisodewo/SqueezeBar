//
//  SettingsView.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    // Local state to prevent publishing changes during view updates
    @State private var compressionMode: CompressionMode
    @State private var compressionQuality: CompressionQuality
    @State private var customQuality: Double
    @State private var targetSizeMB: Double
    @State private var compressionPercentage: Double

    init(settings: AppSettings) {
        self.settings = settings
        // Initialize local state from settings
        _compressionMode = State(initialValue: settings.compressionMode)
        _compressionQuality = State(initialValue: settings.compressionQuality)
        _customQuality = State(initialValue: settings.customQuality)
        _targetSizeMB = State(initialValue: settings.targetSizeMB)
        _compressionPercentage = State(initialValue: settings.compressionPercentage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Compression Mode Selector
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Compression Method")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Picker("Mode", selection: $compressionMode) {
                    ForEach(CompressionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: compressionMode) { newValue in
                    // Update settings asynchronously to avoid publishing during view updates
                    DispatchQueue.main.async {
                        settings.compressionMode = newValue
                    }
                }
            }

            // Mode-specific controls
            switch compressionMode {
            case .quality:
                qualityControls
            case .targetSize:
                targetSizeControls
            case .percentage:
                percentageControls
            }

            Divider()
                .padding(.vertical, DesignTokens.Spacing.xs)

            // Output Folder Selection
            outputFolderSection
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var qualityControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Picker("Quality", selection: $compressionQuality) {
                ForEach(CompressionQuality.allCases) { quality in
                    Text(quality.rawValue).tag(quality)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: compressionQuality) { newValue in
                // Update settings asynchronously to avoid publishing during view updates
                DispatchQueue.main.async {
                    settings.compressionQuality = newValue
                }
            }

            Text(compressionQuality.hint)
                .font(.caption)
                .foregroundColor(.secondary)

            if compressionQuality == .custom {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("Custom Quality")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(customQuality * 100))%")
                            .font(.caption)
                            .foregroundColor(DesignTokens.primaryAccent)
                            .fontWeight(.semibold)
                    }

                    Slider(value: $customQuality, in: 0.1...1.0, step: 0.05)
                        .accentColor(DesignTokens.primaryAccent)
                        .onChange(of: customQuality) { newValue in
                            // Update settings asynchronously
                            DispatchQueue.main.async {
                                settings.customQuality = newValue
                            }
                        }
                }
            }
        }
    }

    private var targetSizeControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Maximum File Size")
                    .font(.caption)
                Spacer()
                Text("\(String(format: "%.1f", targetSizeMB)) MB")
                    .font(.caption)
                    .foregroundColor(DesignTokens.primaryAccent)
                    .fontWeight(.semibold)
            }

            Slider(value: $targetSizeMB, in: 0.5...50.0, step: 0.5)
                .accentColor(DesignTokens.primaryAccent)
                .onChange(of: targetSizeMB) { newValue in
                    // Update settings asynchronously
                    DispatchQueue.main.async {
                        settings.targetSizeMB = newValue
                    }
                }

            Text("App will attempt to compress to this size or smaller")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var percentageControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Reduce File Size By")
                    .font(.caption)
                Spacer()
                Text("\(Int(compressionPercentage))%")
                    .font(.caption)
                    .foregroundColor(DesignTokens.primaryAccent)
                    .fontWeight(.semibold)
            }

            Slider(value: $compressionPercentage, in: 10...90, step: 5)
                .accentColor(DesignTokens.primaryAccent)
                .onChange(of: compressionPercentage) { newValue in
                    // Update settings asynchronously
                    DispatchQueue.main.async {
                        settings.compressionPercentage = newValue
                    }
                }

            Text("Original size will be reduced by this percentage")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var outputFolderSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Save Location")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            if let url = settings.outputFolderURL {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(DesignTokens.primaryAccent)
                            .font(.system(size: 10))

                        Text(url.lastPathComponent)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Button(action: { settings.openDestinationFolder() }) {
                            Text("Open Folder")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.mini)

                        Button(action: selectOutputFolder) {
                            Text("Change")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.mini)
                    }
                    .padding(DesignTokens.Spacing.sm)
                    .background(DesignTokens.primaryAccent.opacity(0.1))
                    .cornerRadius(DesignTokens.CornerRadius.small)

                    Text(url.path)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DesignTokens.warningOrange)
                            .font(.system(size: 10))

                        Text("No folder selected")
                            .font(.system(size: 11))
                            .foregroundColor(DesignTokens.warningOrange)
                    }
                    .padding(DesignTokens.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.warningOrange.opacity(0.1))
                    .cornerRadius(DesignTokens.CornerRadius.small)

                    Button(action: selectOutputFolder) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 10))
                            Text("Choose Location")
                                .font(.system(size: 11))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
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
        panel.message = "Choose where to save compressed files"
        panel.prompt = "Choose"

        if panel.runModal() == .OK {
            // Update settings asynchronously to avoid "Publishing changes from within view updates" error
            let selectedURL = panel.url
            DispatchQueue.main.async {
                settings.outputFolderURL = selectedURL
            }
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
        .frame(width: 360)
}
