//
//  ConversionSettingsView.swift
//  SqueezeBar
//

import SwiftUI

struct ConversionSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var viewModel = MainViewModel.shared

    @State private var conversionCategory: ConversionCategory
    @State private var imageOutputFormat: ImageOutputFormat
    @State private var imageConversionQuality: Double
    @State private var videoOutputFormat: VideoOutputFormat

    private let phase2Categories: [ConversionCategory] = [.imageToImage, .videoToVideo, .videoToAudio]

    init(settings: AppSettings) {
        self.settings = settings
        _conversionCategory = State(initialValue: settings.conversionCategory)
        _imageOutputFormat = State(initialValue: settings.imageOutputFormat)
        _imageConversionQuality = State(initialValue: settings.imageConversionQuality)
        _videoOutputFormat = State(initialValue: settings.videoOutputFormat)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Conversion Type
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionHeader(icon: "arrow.triangle.2.circlepath", title: "Conversion Type")

                ToySegmentedPicker(
                    selection: $conversionCategory,
                    options: phase2Categories,
                    label: { $0.rawValue },
                    isDisabled: viewModel.isConverting
                )
                .onChange(of: conversionCategory) { newValue in
                    DispatchQueue.main.async {
                        settings.conversionCategory = newValue
                        settings.saveConversionSettings()
                    }
                }
            }

            // Category-specific controls
            switch conversionCategory {
            case .imageToImage:
                imageConversionControls
            case .videoToVideo:
                videoConversionControls
            case .videoToAudio:
                audioExtractionInfo
            case .imageToPDF, .pdfProtect:
                comingSoonPlaceholder
            }

            Divider()
                .padding(.vertical, DesignTokens.Spacing.xs)

            // Save Location
            outputFolderSection
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Image Conversion Controls

    private var imageConversionControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "photo", title: "Output Format")

            ToySegmentedPicker(
                selection: $imageOutputFormat,
                options: ImageOutputFormat.allCases,
                label: { $0.displayName },
                isDisabled: viewModel.isConverting
            )
            .onChange(of: imageOutputFormat) { newValue in
                DispatchQueue.main.async {
                    settings.imageOutputFormat = newValue
                    settings.saveConversionSettings()
                }
            }

            if imageOutputFormat == .jpeg || imageOutputFormat == .heic {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("Quality")
                            .font(DesignTokens.Typography.caption)
                        Spacer()
                        Text("\(Int(imageConversionQuality * 100))%")
                            .font(Font.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(DesignTokens.Candy.blue)
                    }

                    ToySlider(
                        value: $imageConversionQuality,
                        range: 0.1...1.0,
                        step: 0.05,
                        isDisabled: viewModel.isConverting
                    )
                    .onChange(of: imageConversionQuality) { newValue in
                        DispatchQueue.main.async {
                            settings.imageConversionQuality = newValue
                            settings.saveConversionSettings()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Video Conversion Controls

    private var videoConversionControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "video", title: "Output Format")

            ToySegmentedPicker(
                selection: $videoOutputFormat,
                options: VideoOutputFormat.allCases,
                label: { $0.displayName },
                isDisabled: viewModel.isConverting
            )
            .onChange(of: videoOutputFormat) { newValue in
                DispatchQueue.main.async {
                    settings.videoOutputFormat = newValue
                    settings.saveConversionSettings()
                }
            }

            Text("Remuxes the video without re-encoding when possible")
                .font(DesignTokens.Typography.tiny)
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - Audio Extraction Info

    private var audioExtractionInfo: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "music.note")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Candy.lavender)
            VStack(alignment: .leading, spacing: 2) {
                Text("Extracts audio as M4A (AAC)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Candy.lavender)
                Text("High quality, smaller than MP3")
                    .font(DesignTokens.Typography.tiny)
                    .foregroundStyle(DesignTokens.Candy.lavender.opacity(0.7))
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Candy.lavender.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }

    // MARK: - Coming Soon Placeholder

    private var comingSoonPlaceholder: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)
            Text("Coming in a future update")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(Color.secondary)
            Spacer()
        }
        .padding(DesignTokens.Spacing.sm)
        .background(Color.secondary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }

    // MARK: - Output Folder Section

    private var outputFolderSection: some View {
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
                        .disabled(viewModel.isConverting)
                        .hoverScale(1.05)

                        Button(action: selectOutputFolder) {
                            Text("Change")
                                .font(DesignTokens.Typography.tiny)
                                .foregroundStyle(DesignTokens.Candy.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isConverting)
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
                    .disabled(viewModel.isConverting)
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
        panel.message = "Choose where to save converted files"
        panel.prompt = "Choose"

        if panel.runModal() == .OK {
            let selectedURL = panel.url
            DispatchQueue.main.async {
                settings.outputFolderURL = selectedURL
            }
        }
    }
}

#Preview {
    ConversionSettingsView(settings: AppSettings())
        .frame(width: 360)
}
