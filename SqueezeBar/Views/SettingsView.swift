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
    @State private var compressionMode: CompressionMode
    @State private var compressionQuality: CompressionQuality
    @State private var customQuality: Double
    @State private var targetSizeMB: Double
    @State private var compressionPercentage: Double
    @State private var enableFramerateReduction: Bool
    @State private var selectedFramerate: Double

    init(settings: AppSettings) {
        self.settings = settings
        _compressionMode = State(initialValue: settings.compressionMode)
        _compressionQuality = State(initialValue: settings.compressionQuality)
        _customQuality = State(initialValue: settings.customQuality)
        _targetSizeMB = State(initialValue: settings.targetSizeMB)
        _compressionPercentage = State(initialValue: settings.compressionPercentage)
        _enableFramerateReduction = State(initialValue: settings.enableFramerateReduction)
        _selectedFramerate = State(initialValue: settings.targetFramerate ?? 30.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Compression Mode Selector
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionHeader(icon: "slider.horizontal.3", title: "Compression Method")

                ToySegmentedPicker(
                    selection: $compressionMode,
                    options: CompressionMode.allCases.map { $0 },
                    label: { $0.rawValue },
                    isDisabled: viewModel.isCompressing
                )
                .onChange(of: compressionMode) { newValue in
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Quality Controls

    private var qualityControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            ToySegmentedPicker(
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
                .foregroundStyle(Color.secondary)

            if compressionQuality == .custom {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("Custom Quality")
                            .font(DesignTokens.Typography.caption)
                        Spacer()
                        Text("\(Int(customQuality * 100))%")
                            .font(Font.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(DesignTokens.Candy.blue)
                    }

                    ToySlider(
                        value: $customQuality,
                        range: 0.1...1.0,
                        step: 0.05,
                        isDisabled: viewModel.isCompressing
                    )
                    .onChange(of: customQuality) { newValue in
                        DispatchQueue.main.async {
                            settings.customQuality = newValue
                        }
                    }
                }
            }
        }
    }

    // MARK: - Target Size Controls

    private var targetSizeControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Maximum File Size")
                    .font(DesignTokens.Typography.caption)
                Spacer()
                Text("\(String(format: "%.1f", targetSizeMB)) MB")
                    .font(Font.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignTokens.Candy.blue)
            }

            ToySlider(
                value: $targetSizeMB,
                range: 0.5...50.0,
                step: 0.5,
                isDisabled: viewModel.isCompressing
            )
            .onChange(of: targetSizeMB) { newValue in
                DispatchQueue.main.async {
                    settings.targetSizeMB = newValue
                }
            }

            Text("App will attempt to compress to this size or smaller")
                .font(DesignTokens.Typography.tiny)
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - Percentage Controls

    private var percentageControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Reduce File Size By")
                    .font(DesignTokens.Typography.caption)
                Spacer()
                Text("\(Int(compressionPercentage))%")
                    .font(Font.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignTokens.Candy.blue)
            }

            ToySlider(
                value: $compressionPercentage,
                range: 10...90,
                step: 5,
                isDisabled: viewModel.isCompressing
            )
            .onChange(of: compressionPercentage) { newValue in
                DispatchQueue.main.async {
                    settings.compressionPercentage = newValue
                }
            }

            Text("Original size will be reduced by this percentage")
                .font(DesignTokens.Typography.tiny)
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - Framerate Section

    private var framerateSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "film", title: "Frame Rate")

            Toggle("Reduce frame rate", isOn: $enableFramerateReduction)
                .tint(DesignTokens.Candy.blue)
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
                        .foregroundStyle(Color.secondary)

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
                    .tint(DesignTokens.Candy.blue)
                    .disabled(viewModel.isCompressing)
                    .onChange(of: selectedFramerate) { newValue in
                        DispatchQueue.main.async {
                            settings.targetFramerate = newValue
                            settings.saveFramerateSettings()
                        }
                    }
                }

                Text("Lower framerates reduce file size")
                    .font(DesignTokens.Typography.tiny)
                    .foregroundStyle(Color.secondary)
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
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DesignTokens.Candy.lavender)
            Text(title)
                .font(DesignTokens.Typography.heading)
                .foregroundStyle(DesignTokens.Candy.lavender)
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
        .frame(width: 360)
}
