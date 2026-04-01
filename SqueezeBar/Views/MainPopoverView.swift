//
//  MainPopoverView.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import SwiftUI

struct MainPopoverView: View {
    @ObservedObject private var viewModel = MainViewModel.shared
    @StateObject private var settings = AppSettings()

    @State private var shakeError = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Mode tab picker
            ToySegmentedPicker(
                selection: $viewModel.appMode,
                options: AppMode.allCases,
                label: { $0.rawValue },
                isDisabled: viewModel.isCompressing || viewModel.isConverting
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)

            if viewModel.appMode == .compress {
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Drop Zone Section
                        VStack(spacing: DesignTokens.Spacing.md) {
                            DropZoneView(viewModel: viewModel, appMode: viewModel.appMode)
                                .padding(.horizontal, DesignTokens.Spacing.lg)

                            // File info
                            if let fileType = viewModel.fileTypeHint, let fileSize = viewModel.fileSizeString {
                                fileInfoView(fileType: fileType, fileSize: fileSize)
                                    .transition(.opacity)
                            }

                            // Status messages
                            if !viewModel.statusMessage.isEmpty || viewModel.errorMessage != nil {
                                statusMessageView
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .animation(AnimationConstants.popIn, value: viewModel.droppedFileURL != nil)
                        .animation(AnimationConstants.popIn, value: viewModel.errorMessage)
                        .animation(AnimationConstants.popIn, value: viewModel.statusMessage)

                        Divider()

                        // Settings Section
                        SettingsView(settings: settings)
                    }
                }

                Divider()

                // Compress Button
                compressButtonView
            } else {
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Drop Zone Section
                        VStack(spacing: DesignTokens.Spacing.md) {
                            DropZoneView(viewModel: viewModel, appMode: viewModel.appMode, conversionCategory: settings.conversionCategory)
                                .padding(.horizontal, DesignTokens.Spacing.lg)

                            // File info — show count for imageToPDF, single file info otherwise
                            if settings.conversionCategory == .imageToPDF {
                                if !viewModel.droppedFileURLs.isEmpty {
                                    fileInfoView(fileType: "Images", fileSize: "\(viewModel.droppedFileURLs.count) file\(viewModel.droppedFileURLs.count == 1 ? "" : "s")")
                                        .transition(.opacity)
                                }
                            } else if let fileType = viewModel.fileTypeHint, let fileSize = viewModel.fileSizeString {
                                fileInfoView(fileType: fileType, fileSize: fileSize)
                                    .transition(.opacity)
                            }

                            // Status messages
                            if !viewModel.statusMessage.isEmpty || viewModel.errorMessage != nil {
                                conversionStatusMessageView
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .animation(AnimationConstants.popIn, value: viewModel.droppedFileURL != nil)
                        .animation(AnimationConstants.popIn, value: viewModel.errorMessage)
                        .animation(AnimationConstants.popIn, value: viewModel.statusMessage)

                        Divider()

                        // Conversion Settings
                        ConversionSettingsView(settings: settings)
                    }
                }

                Divider()

                // Convert Button
                convertButtonView
            }
        }
        .frame(width: 400, height: 640)
        .onChange(of: viewModel.errorMessage) { newValue in
            if newValue != nil {
                shakeError = true
                HapticManager.shared.light()
            }
        }
        .onChange(of: viewModel.statusMessage) { newValue in
            if !newValue.isEmpty && !viewModel.isCompressing && !viewModel.isConverting {
                HapticManager.shared.success()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image("SqueezeBar-macOS-Default")
                .resizable()
                .frame(width: 22, height: 22)
            Text("SqueezeBar")
                .font(DesignTokens.Typography.title)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.cardBackground)
        .shadow(
            color: DesignTokens.Shadow.toy.color,
            radius: DesignTokens.Shadow.toy.radius,
            x: DesignTokens.Shadow.toy.x,
            y: DesignTokens.Shadow.toy.y
        )
    }

    // MARK: - File Info

    private func fileInfoView(fileType: String, fileSize: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "doc.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color.secondary)

            Text(fileType)
                .font(DesignTokens.Typography.tiny)
                .foregroundStyle(Color.secondary)

            Text("•")
                .font(.system(size: 8))
                .foregroundStyle(Color.secondary.opacity(0.5))

            Text(fileSize)
                .font(DesignTokens.Typography.tiny)
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - Status Messages

    private var statusMessageView: some View {
        Group {
            if let error = viewModel.errorMessage {
                errorView(message: error)
                    .shake(trigger: $shakeError)
            } else if !viewModel.statusMessage.isEmpty {
                successView(message: viewModel.statusMessage, isInProgress: viewModel.isCompressing, hasResult: viewModel.lastResult != nil) {
                    viewModel.openResultFolder()
                }
            }
        }
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(DesignTokens.Candy.coral)
                .font(.system(size: 13))
            Text(message)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Candy.coral)
            Spacer()
        }
        .padding(10)
        .background(DesignTokens.Candy.coral.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .shadow(
            color: DesignTokens.Shadow.toy.color,
            radius: DesignTokens.Shadow.toy.radius,
            x: DesignTokens.Shadow.toy.x,
            y: DesignTokens.Shadow.toy.y
        )
    }

    private func successView(message: String, isInProgress: Bool, hasResult: Bool, onOpenFolder: (() -> Void)? = nil) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if isInProgress {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                    .tint(DesignTokens.Candy.blue)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignTokens.Candy.mint)
                    .font(.system(size: 13))
            }
            Text(message)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(isInProgress ? Color.secondary : DesignTokens.Candy.mint)
            Spacer()

            if !isInProgress && hasResult {
                if let openFolder = onOpenFolder {
                    Button(action: openFolder) {
                        Text("Open Folder")
                            .font(DesignTokens.Typography.tiny)
                            .foregroundStyle(DesignTokens.Candy.blue)
                    }
                    .buttonStyle(.plain)
                    .hoverScale(1.05)
                }

                Button(action: { viewModel.removeAttachedFile() }) {
                    Text("Close")
                        .font(DesignTokens.Typography.tiny)
                        .foregroundStyle(DesignTokens.Candy.coral)
                }
                .buttonStyle(.plain)
                .hoverScale(1.05)
            }
        }
        .padding(10)
        .background(isInProgress ? DesignTokens.Candy.blue.opacity(0.08) : DesignTokens.Candy.mint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .shadow(
            color: DesignTokens.Shadow.toy.color,
            radius: DesignTokens.Shadow.toy.radius,
            x: DesignTokens.Shadow.toy.x,
            y: DesignTokens.Shadow.toy.y
        )
    }

    // MARK: - Conversion Status Message

    private var conversionStatusMessageView: some View {
        Group {
            if let error = viewModel.errorMessage {
                errorView(message: error)
                    .shake(trigger: $shakeError)
            } else if !viewModel.statusMessage.isEmpty {
                successView(message: viewModel.statusMessage, isInProgress: viewModel.isConverting, hasResult: viewModel.lastConversionResult != nil) {
                    viewModel.openConversionResultFolder()
                }
            }
        }
    }

    // MARK: - Convert Button

    private var convertButtonView: some View {
        Button(action: {
            HapticManager.shared.medium()
            Task {
                await viewModel.convertFile(settings: settings)
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if viewModel.isConverting {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: convertButtonIcon)
                }
                Text(convertButtonLabel)
            }
        }
        .buttonStyle(ToyButtonStyle())
        .disabled(convertButtonDisabled)
        .hoverScale(1.02)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 10)
        .background(DesignTokens.cardBackground)
    }

    private var convertButtonIcon: String {
        switch settings.conversionCategory {
        case .imageToPDF: return "doc.richtext"
        case .pdfProtect: return "lock.fill"
        default: return "arrow.triangle.2.circlepath"
        }
    }

    private var convertButtonLabel: String {
        if viewModel.isConverting {
            switch settings.conversionCategory {
            case .imageToPDF: return "Creating PDF..."
            case .pdfProtect: return "Protecting..."
            default: return "Converting..."
            }
        } else {
            switch settings.conversionCategory {
            case .imageToPDF: return "Create PDF"
            case .pdfProtect: return "Protect PDF"
            default: return "Convert File"
            }
        }
    }

    private var convertButtonDisabled: Bool {
        guard !viewModel.isConverting, settings.outputFolderURL != nil else { return true }
        switch settings.conversionCategory {
        case .imageToPDF:
            return viewModel.droppedFileURLs.isEmpty
        case .pdfProtect:
            return viewModel.droppedFileURL == nil || !settings.isPdfPasswordValid
        default:
            return viewModel.droppedFileURL == nil
        }
    }

    // MARK: - Compress Button

    private var compressButtonView: some View {
        Button(action: {
            HapticManager.shared.medium()
            Task {
                await viewModel.compressFile(settings: settings)
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if viewModel.isCompressing {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "bolt.fill")
                }
                Text(viewModel.isCompressing ? "Squeezing..." : "Squeeze File")
            }
        }
        .buttonStyle(ToyButtonStyle())
        .disabled(viewModel.droppedFileURL == nil || settings.outputFolderURL == nil || viewModel.isCompressing)
        .hoverScale(1.02)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 10)
        .background(DesignTokens.cardBackground)
    }
}

#Preview {
    MainPopoverView()
}
