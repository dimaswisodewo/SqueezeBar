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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Drop Zone Section
            VStack(spacing: DesignTokens.Spacing.lg) {
                DropZoneView(viewModel: viewModel)
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                // File info
                if let fileType = viewModel.fileTypeHint, let fileSize = viewModel.fileSizeString {
                    fileInfoView(fileType: fileType, fileSize: fileSize)
                }

                // Status messages
                if !viewModel.statusMessage.isEmpty || viewModel.errorMessage != nil {
                    statusMessageView
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.md)

            Divider()

            // Settings Section
            SettingsView(settings: settings)

            Divider()

            // Compress Button
            compressButtonView
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var headerView: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(DesignTokens.primaryAccent)
            Text("SqueezeBar")
                .font(.system(size: 15, weight: .semibold))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.cardBackground)
    }

    private func fileInfoView(fileType: String, fileSize: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "doc.fill")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            Text(fileType)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)

            Text("•")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.5))

            Text(fileSize)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private var statusMessageView: some View {
        Group {
            if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if !viewModel.statusMessage.isEmpty {
                successView(message: viewModel.statusMessage, isCompressing: viewModel.isCompressing)
            }
        }
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(DesignTokens.errorRed)
                .font(.system(size: 12))
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(DesignTokens.errorRed)
            Spacer()
        }
        .padding(10)
        .background(DesignTokens.errorRed.opacity(0.1))
        .cornerRadius(DesignTokens.CornerRadius.medium)
        .shadow(
            color: DesignTokens.Shadow.message.color,
            radius: DesignTokens.Shadow.message.radius,
            x: DesignTokens.Shadow.message.x,
            y: DesignTokens.Shadow.message.y
        )
    }

    private func successView(message: String, isCompressing: Bool) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if isCompressing {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.successGreen)
                    .font(.system(size: 12))
            }
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(isCompressing ? .secondary : DesignTokens.successGreen)
            Spacer()

            // Show "Open Folder" button when compression is complete
            if !isCompressing && viewModel.lastResult != nil {
                Button(action: { viewModel.openResultFolder() }) {
                    Text("Open Folder")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .controlSize(.mini)
            }
        }
        .padding(10)
        .background(isCompressing ? DesignTokens.primaryAccent.opacity(0.1) : DesignTokens.successGreen.opacity(0.1))
        .cornerRadius(DesignTokens.CornerRadius.medium)
        .shadow(
            color: DesignTokens.Shadow.message.color,
            radius: DesignTokens.Shadow.message.radius,
            x: DesignTokens.Shadow.message.x,
            y: DesignTokens.Shadow.message.y
        )
    }

    private var compressButtonView: some View {
        Button(action: {
            Task {
                await viewModel.compressFile(settings: settings)
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if viewModel.isCompressing {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "bolt.fill")
                }
                Text(viewModel.isCompressing ? "Compressing..." : "Compress File")
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.droppedFileURL == nil || settings.outputFolderURL == nil || viewModel.isCompressing)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 10)
        .background(DesignTokens.cardBackground)
    }
}

#Preview {
    MainPopoverView()
}
