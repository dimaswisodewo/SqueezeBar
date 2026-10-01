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
    @ObservedObject private var viewModel = MainViewModel.shared

    // Local state to prevent publishing changes during view updates
    @State private var compressionQuality: CompressionQuality
    @State private var customQuality: Double
    @State private var enableFramerateReduction: Bool
    @State private var selectedFramerate: Double

    init(settings: AppSettings) {
        self.settings = settings
        _compressionQuality = State(initialValue: settings.compressionQuality)
        _customQuality = State(initialValue: settings.customQuality)
        _enableFramerateReduction = State(initialValue: settings.enableFramerateReduction)
        _selectedFramerate = State(initialValue: settings.targetFramerate ?? 30.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            SectionHeader(icon: "slider.horizontal.3", title: "Quality")
            qualityControls

            Divider()
                .padding(.vertical, DesignTokens.Spacing.xs)

            // Video Framerate Controls
            if viewModel.isCurrentFileVideo {
                framerateSection

                Divider()
                    .padding(.vertical, DesignTokens.Spacing.xs)
            }

            // Output Folder Selection
            outputFolderSection
        }
        .onChange(of: viewModel.isCompressing) { newValue in
            if !newValue, viewModel.errorMessage == nil {
                viewModel.removeAttachedFileWithoutResetingStatusMessage()
            }
        }
        .padding(DesignTokens.Spacing.outer)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(DesignTokens.Colors.ink)
        .background(DesignTokens.Colors.canvas)
        .font(DesignTokens.Typography.body)
    }

    // MARK: - Quality Controls

    private var qualityControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            BrutalistChoicePicker(
                selection: $compressionQuality,
                options: CompressionQuality.allCases.map { $0 },
                label: { $0.rawValue },
                isDisabled: viewModel.isCompressing
            )
            .onChange(of: compressionQuality) { newValue in
                DispatchQueue.main.async {
                    settings.compressionQuality = newValue
                }
            }

            Text(compressionQuality.hint)
                .font(DesignTokens.Typography.tiny)
                .foregroundStyle(DesignTokens.Colors.muted)

            if compressionQuality == .custom {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("Custom quality")
                            .font(DesignTokens.Typography.caption)
                        Spacer()
                        Text("\(Int(customQuality * 100))%")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }

                    BrutalistSlider(
                        value: $customQuality,
                        range: 0.1...1.0,
                        step: 0.05,
                        isDisabled: viewModel.isCompressing
                    )
                    .frame(height: 32)
                    .onChange(of: customQuality) { newValue in
                        DispatchQueue.main.async {
                            settings.customQuality = newValue
                        }
                    }
                }
            }
        }
    }

    // MARK: - Framerate Section

    private var framerateSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "film", title: "Frame rate")

            Toggle("Reduce frame rate", isOn: $enableFramerateReduction)
                .toggleStyle(BrutalistToggleStyle())
                .disabled(viewModel.isCompressing || !viewModel.isCurrentFileVideo)
                .onChange(of: enableFramerateReduction) { newValue in
                    DispatchQueue.main.async {
                        settings.enableFramerateReduction = newValue
                        if !newValue {
                            settings.targetFramerate = nil
                        }
                        settings.saveFramerateSettings()
                    }
                }

            if enableFramerateReduction && viewModel.isCurrentFileVideo {
                HStack {
                    Text("Target:")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.muted)

                    Picker("Framerate", selection: $selectedFramerate) {
                        ForEach(availableFramerates, id: \.self) { fps in
                            if let videoFPS = viewModel.videoFramerate, fps == Double(videoFPS) {
                                Text("Original (\(Int(fps)) fps)").tag(fps)
                            } else {
                                Text("\(Int(fps)) fps").tag(fps)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignTokens.Colors.ink)
                    .font(DesignTokens.Typography.metadata)
                    .padding(8)
                    .background(DesignTokens.Colors.inset)
                    .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
                    .disabled(viewModel.isCompressing)
                    .onChange(of: selectedFramerate) { newValue in
                        DispatchQueue.main.async {
                            settings.targetFramerate = newValue
                            settings.saveFramerateSettings()
                        }
                    }
                }

                Text("Fewer frames per second reduce file size")
                    .font(DesignTokens.Typography.tiny)
                    .foregroundStyle(DesignTokens.Colors.muted)
            }
        }
    }

    private var availableFramerates: [Double] {
        guard let videoFPS = viewModel.videoFramerate else {
            return [60, 48, 30, 24]
        }
        let allFramerates: [Double] = [144, 120, 60, 48, 30, 25, 24]
        return allFramerates.filter { $0 <= Double(videoFPS) }.sorted(by: >)
    }

    // MARK: - Output Folder Section

    private var outputFolderSection: some View {
        OutputFolderSectionView(
            settings: settings,
            isDisabled: viewModel.isCompressing,
            panelMessage: "Choose where to save compressed files"
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).resizable().scaledToFit().frame(width: 13, height: 13)
                .accessibilityHidden(true)
            BrutalistSectionLabel(title: title)
        }
        .foregroundStyle(DesignTokens.Colors.ink)
    }
}

#Preview {
    SettingsView(settings: AppSettings())
        .frame(width: 360)
}
