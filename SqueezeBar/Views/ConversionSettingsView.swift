//
//  ConversionSettingsView.swift
//  SqueezeBar
//

import SwiftUI
import UniformTypeIdentifiers

struct ConversionSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var viewModel = MainViewModel.shared

    @State private var conversionCategory: ConversionCategory
    @State private var imageOutputFormat: ImageOutputFormat
    @State private var imageConversionQuality: Double
    @State private var videoOutputFormat: VideoOutputFormat

    private let availableCategories: [ConversionCategory] = ConversionCategory.allCases

    init(settings: AppSettings) {
        self.settings = settings
        _conversionCategory = State(initialValue: settings.conversionCategory)
        _imageOutputFormat = State(initialValue: settings.imageOutputFormat)
        _imageConversionQuality = State(initialValue: settings.imageConversionQuality)
        _videoOutputFormat = State(initialValue: settings.videoOutputFormat)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Action
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionHeader(icon: "arrow.triangle.2.circlepath", title: "Action")

                BrutalistChoicePicker(
                    selection: $conversionCategory,
                    options: availableCategories,
                    label: { $0.displayName },
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
            case .imageToPDF:
                imageToPDFControls
            case .pdfProtect:
                pdfProtectControls
            }

            Divider()
                .padding(.vertical, DesignTokens.Spacing.xs)

            // Save Location
            outputFolderSection
        }
        .padding(DesignTokens.Spacing.outer)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(DesignTokens.Colors.ink)
        .background(DesignTokens.Colors.canvas)
        .font(DesignTokens.Typography.body)
    }

    // MARK: - Image Conversion Controls

    private var imageConversionControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "photo", title: "Output format")

            BrutalistChoicePicker(
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
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }

                    BrutalistSlider(
                        value: $imageConversionQuality,
                        range: 0.1...1.0,
                        step: 0.05,
                        isDisabled: viewModel.isConverting
                    )
                    .frame(height: 32)
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
            SectionHeader(icon: "video", title: "Output format")

            BrutalistChoicePicker(
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

            Text("Keeps the original video quality when possible")
                .font(DesignTokens.Typography.tiny)
                .foregroundStyle(DesignTokens.Colors.muted)
        }
    }

    // MARK: - Audio Extraction Info

    private var audioExtractionInfo: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "music.note")
                .resizable().scaledToFit().frame(width: 13, height: 13)
                .foregroundStyle(DesignTokens.Colors.ink)
            VStack(alignment: .leading, spacing: 2) {
                Text("Saves audio as M4A (AAC)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text("High quality, smaller than MP3")
                    .font(DesignTokens.Typography.tiny)
                    .foregroundStyle(DesignTokens.Colors.ink.opacity(0.7))
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.inset)
        .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
    }

    // MARK: - Image to PDF Controls

    private var imageToPDFControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Info banner
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "doc.richtext")
                    .resizable().scaledToFit().frame(width: 13, height: 13)
                    .foregroundStyle(DesignTokens.Colors.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Combines images into a single PDF")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    Text("Pages sized to A4, images centered")
                        .font(DesignTokens.Typography.tiny)
                        .foregroundStyle(DesignTokens.Colors.ink.opacity(0.7))
                }
                Spacer()
            }
            .padding(DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.inset)
            .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))

            // File list
            if !viewModel.droppedFileURLs.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("\(viewModel.droppedFileURLs.count) image\(viewModel.droppedFileURLs.count == 1 ? "" : "s") added")
                        .font(DesignTokens.Typography.tiny)
                        .foregroundStyle(DesignTokens.Colors.muted)

                    ForEach(viewModel.droppedFileURLs, id: \.absoluteString) { url in
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "photo")
                                .resizable().scaledToFit().frame(width: 10, height: 10)
                                .foregroundStyle(DesignTokens.Colors.ink)
                            Text(url.lastPathComponent)
                                .font(DesignTokens.Typography.tiny)
                                .foregroundStyle(DesignTokens.Colors.ink)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button(action: {
                                viewModel.removeFileFromList(url)
                            }) {
                                Image(systemName: "xmark")
                                    .resizable().scaledToFit().frame(width: 8, height: 8)
                                    .foregroundStyle(DesignTokens.Colors.ink)
                            }
                            .buttonStyle(BrutalistQuietButtonStyle())
                            .disabled(viewModel.isConverting)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(DesignTokens.Colors.inset)
                        .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
                    }
                }
            }

            // Add files button
            Button(action: addMoreImages) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "plus.circle")
                        .resizable().scaledToFit().frame(width: 11, height: 11)
                    Text("Add files")
                        .font(DesignTokens.Typography.caption)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .foregroundStyle(DesignTokens.Colors.ink)
                .background(DesignTokens.Colors.inset)
                .overlay(Rectangle().strokeBorder(DesignTokens.Colors.ink, lineWidth: DesignTokens.Geometry.border))
            }
            .buttonStyle(BrutalistQuietButtonStyle())
            .disabled(viewModel.isConverting)
        }
    }

    // MARK: - PDF Protect Controls

    private var pdfProtectControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "lock.fill", title: "Password protection")

            BrutalistSecureField(title: "Password", text: $settings.pdfPassword)
                .disabled(viewModel.isConverting)

            BrutalistSecureField(title: "Confirm password", text: $settings.pdfPasswordConfirm)
                .disabled(viewModel.isConverting)

            if !settings.pdfPassword.isEmpty && settings.pdfPassword != settings.pdfPasswordConfirm {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable().scaledToFit().frame(width: 10, height: 10)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    Text("Passwords do not match")
                        .font(DesignTokens.Typography.tiny)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
            }
        }
    }

    // MARK: - Output Folder Section

    private var outputFolderSection: some View {
        OutputFolderSectionView(
            settings: settings,
            isDisabled: viewModel.isConverting,
            panelMessage: "Choose where to save converted files"
        )
    }

    private func addMoreImages() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.message = "Choose images to add"
        panel.prompt = "Add"
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic, .bmp, .tiff]

        if panel.runModal() == .OK {
            let urls = panel.urls
            DispatchQueue.main.async {
                for url in urls {
                    if !self.viewModel.droppedFileURLs.contains(url) {
                        self.viewModel.droppedFileURLs.append(url)
                    }
                }
                if self.viewModel.droppedFileURL == nil {
                    self.viewModel.droppedFileURL = self.viewModel.droppedFileURLs.first
                }
            }
        }
    }
}

#Preview {
    ConversionSettingsView(settings: AppSettings())
        .frame(width: 360)
}
