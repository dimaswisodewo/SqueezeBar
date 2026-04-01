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
            // Conversion Type
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionHeader(icon: "arrow.triangle.2.circlepath", title: "Conversion Type")

                ToySegmentedPicker(
                    selection: $conversionCategory,
                    options: availableCategories,
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

    // MARK: - Image to PDF Controls

    private var imageToPDFControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Info banner
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Candy.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Combines images into a single PDF")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Candy.coral)
                    Text("Pages sized to A4, images centered")
                        .font(DesignTokens.Typography.tiny)
                        .foregroundStyle(DesignTokens.Candy.coral.opacity(0.7))
                }
                Spacer()
            }
            .padding(DesignTokens.Spacing.sm)
            .background(DesignTokens.Candy.coral.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))

            // File list
            if !viewModel.droppedFileURLs.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("\(viewModel.droppedFileURLs.count) image\(viewModel.droppedFileURLs.count == 1 ? "" : "s") added")
                        .font(DesignTokens.Typography.tiny)
                        .foregroundStyle(Color.secondary)

                    ForEach(viewModel.droppedFileURLs, id: \.absoluteString) { url in
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "photo")
                                .font(.system(size: 10))
                                .foregroundStyle(DesignTokens.Candy.blue)
                            Text(url.lastPathComponent)
                                .font(DesignTokens.Typography.tiny)
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button(action: {
                                viewModel.removeFileFromList(url)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(DesignTokens.Candy.coral)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isConverting)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(DesignTokens.Candy.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                    }
                }
            }

            // Add More Files button
            Button(action: addMoreImages) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 11))
                    Text("Add More Files")
                        .font(DesignTokens.Typography.caption)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .foregroundStyle(DesignTokens.Candy.blue)
                .background(DesignTokens.Candy.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isConverting)
            .hoverScale(1.02)
        }
    }

    // MARK: - PDF Protect Controls

    private var pdfProtectControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader(icon: "lock.fill", title: "Password Protection")

            SecureField("Password", text: $settings.pdfPassword)
                .textFieldStyle(.roundedBorder)
                .font(DesignTokens.Typography.body)
                .disabled(viewModel.isConverting)

            SecureField("Confirm Password", text: $settings.pdfPasswordConfirm)
                .textFieldStyle(.roundedBorder)
                .font(DesignTokens.Typography.body)
                .disabled(viewModel.isConverting)

            if !settings.pdfPassword.isEmpty && settings.pdfPassword != settings.pdfPasswordConfirm {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Candy.coral)
                    Text("Passwords do not match")
                        .font(DesignTokens.Typography.tiny)
                        .foregroundStyle(DesignTokens.Candy.coral)
                }
            }
        }
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
