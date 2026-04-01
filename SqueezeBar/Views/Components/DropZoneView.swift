//
//  DropZoneView.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var viewModel: MainViewModel
    var appMode: AppMode = .compress
    var conversionCategory: ConversionCategory? = nil
    @State private var isTargeted = false

    private var isImageToPDF: Bool {
        appMode == .convert && conversionCategory == .imageToPDF
    }

    private var isPDFProtect: Bool {
        appMode == .convert && conversionCategory == .pdfProtect
    }

    private var hasFiles: Bool {
        isImageToPDF ? !viewModel.droppedFileURLs.isEmpty : viewModel.droppedFileURL != nil
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(iconBackgroundColor)
                    .frame(width: 70, height: 70)

                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .scaleEffect(viewModel.isDragging ? 1.12 : 1.0)
            .animation(AnimationConstants.microInteraction, value: viewModel.isDragging)

            // Main message
            Text(mainMessage)
                .font(DesignTokens.Typography.heading)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)

            // Subtitle
            if let subtitle = subtitleMessage {
                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }

            // Supported formats as pill badges
            if !hasFiles && !viewModel.isDragging {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if isImageToPDF {
                        FormatPill("JPG",  color: DesignTokens.Candy.blue)
                        FormatPill("PNG",  color: DesignTokens.Candy.blue)
                        FormatPill("HEIC", color: DesignTokens.Candy.blue)
                    } else if isPDFProtect {
                        FormatPill("PDF", color: DesignTokens.Candy.coral)
                    } else if appMode == .convert && conversionCategory == .imageToImage {
                        FormatPill("JPG",  color: DesignTokens.Candy.blue)
                        FormatPill("PNG",  color: DesignTokens.Candy.blue)
                        FormatPill("HEIC", color: DesignTokens.Candy.blue)
                        FormatPill("TIFF", color: DesignTokens.Candy.blue)
                        FormatPill("BMP",  color: DesignTokens.Candy.blue)
                    } else if appMode == .convert && conversionCategory == .videoToVideo {
                        FormatPill("MP4", color: DesignTokens.Candy.lavender)
                        FormatPill("MOV", color: DesignTokens.Candy.lavender)
                        FormatPill("M4V", color: DesignTokens.Candy.lavender)
                    } else if appMode == .convert && conversionCategory == .videoToAudio {
                        FormatPill("MP4", color: DesignTokens.Candy.lavender)
                        FormatPill("MOV", color: DesignTokens.Candy.lavender)
                    } else {
                        FormatPill("PDF",    color: DesignTokens.Candy.coral)
                        FormatPill("Images", color: DesignTokens.Candy.blue)
                        FormatPill("Videos", color: DesignTokens.Candy.lavender)
                    }
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .strokeBorder(borderColor, lineWidth: 2)
        )
        .overlay(alignment: .topTrailing) {
            // Remove button — only show when a file is attached
            if hasFiles {
                Button(action: {
                    HapticManager.shared.light()
                    viewModel.removeAttachedFile()
                }) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Candy.coral)
                            .frame(width: 24, height: 24)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isCompressing || viewModel.isConverting)
                .padding(10)
                .hoverScale(1.1)
                .pressScale(0.9)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            if viewModel.isCompressing || viewModel.isConverting { return false }
            let result: Bool
            if isImageToPDF {
                result = viewModel.handleMultiDrop(providers: providers)
            } else {
                result = viewModel.handleDrop(providers: providers)
            }
            if result { HapticManager.shared.medium() }
            return result
        }
        .onChange(of: isTargeted) { newValue in
            DispatchQueue.main.async {
                if !viewModel.isCompressing && !viewModel.isConverting {
                    viewModel.isDragging = newValue
                    if newValue { HapticManager.shared.light() }
                }
            }
        }
        .onTapGesture {
            guard !viewModel.isCompressing && !viewModel.isConverting && !viewModel.isDragging else { return }
            if isImageToPDF {
                openMultiImagePicker()
            } else if !hasFiles {
                viewModel.openFilePicker()
            }
        }
        .animation(AnimationConstants.stateTransition, value: hasFiles)
        .animation(AnimationConstants.stateTransition, value: viewModel.isDragging)
    }

    // MARK: - State-driven computed properties

    private var iconName: String {
        if viewModel.isDragging {
            return "arrow.down.circle.fill"
        } else if hasFiles {
            return isImageToPDF ? "doc.richtext.fill" : "checkmark.seal.fill"
        } else {
            return "arrow.down.doc.fill"
        }
    }

    private var iconColor: Color {
        if viewModel.isDragging {
            return DesignTokens.Candy.pink
        } else if hasFiles {
            return DesignTokens.Candy.mint
        } else {
            return DesignTokens.Candy.blue
        }
    }

    private var iconBackgroundColor: Color {
        if viewModel.isDragging {
            return DesignTokens.Candy.pink.opacity(0.15)
        } else if hasFiles {
            return DesignTokens.Candy.mint.opacity(0.15)
        } else {
            return DesignTokens.Candy.blue.opacity(0.1)
        }
    }

    private var backgroundColor: Color {
        if viewModel.isDragging {
            return DesignTokens.Candy.pink.opacity(0.07)
        } else if hasFiles {
            return DesignTokens.Candy.mint.opacity(0.06)
        } else {
            return DesignTokens.Candy.blue.opacity(0.04)
        }
    }

    private var borderColor: Color {
        if viewModel.isDragging {
            return DesignTokens.Candy.pink
        } else if hasFiles {
            return DesignTokens.Candy.mint.opacity(0.6)
        } else {
            return DesignTokens.Candy.blue.opacity(0.25)
        }
    }

    private var mainMessage: String {
        if viewModel.isDragging {
            return "Let it go!"
        } else if isImageToPDF && !viewModel.droppedFileURLs.isEmpty {
            let count = viewModel.droppedFileURLs.count
            return "\(count) image\(count == 1 ? "" : "s") selected"
        } else if viewModel.droppedFileURL != nil {
            return viewModel.droppedFileURL?.lastPathComponent ?? "File ready"
        } else if isImageToPDF {
            return "Drop images to combine"
        } else {
            return "Drop a file to squeeze!"
        }
    }

    private var subtitleMessage: String? {
        if viewModel.isDragging {
            return "Release to add file"
        } else if isImageToPDF && !viewModel.droppedFileURLs.isEmpty {
            return "Drop more or click Convert"
        } else if isImageToPDF {
            return "Drop multiple or click to browse"
        } else if viewModel.droppedFileURL != nil {
            return appMode == .compress ? "Ready to squeeze" : "Ready to convert"
        } else {
            return "or click to browse"
        }
    }

    private func openMultiImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.message = "Choose images to combine into a PDF"
        panel.prompt = "Select"
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

// MARK: - Format Pill Badge

private struct FormatPill: View {
    let label: String
    let color: Color

    init(_ label: String, color: Color) {
        self.label = label
        self.color = color
    }

    var body: some View {
        Text(label)
            .font(DesignTokens.Typography.tiny)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    DropZoneView(viewModel: MainViewModel.shared)
        .frame(width: 340, height: 200)
        .padding()
}
