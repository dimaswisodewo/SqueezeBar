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
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 60, height: 60)

                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(iconColor)
            }

            // Main message
            Text(mainMessage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Subtitle
            if let subtitle = subtitleMessage {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Supported formats hint
            if viewModel.droppedFileURL == nil && !viewModel.isDragging {
                Text("PDF · Images · Videos")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
        .padding()
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: viewModel.isDragging ? [0] : [8, 4])
                )
                .foregroundColor(borderColor)
        )
        .overlay(alignment: .topTrailing) {
            // Remove button - only show when file is attached
            if viewModel.droppedFileURL != nil {
                Button(action: {
                    viewModel.removeAttachedFile()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary, Color.secondary.opacity(0.2))
                        .symbolRenderingMode(.palette)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isCompressing)
                .padding(12)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            // Prevent dropping files during compression
            if viewModel.isCompressing {
                return false
            }
            return viewModel.handleDrop(providers: providers)
        }
        .onChange(of: isTargeted) { newValue in
            // Update viewModel.isDragging asynchronously to avoid publishing changes during view updates
            DispatchQueue.main.async {
                // Don't update isDragging state if compressing
                if !viewModel.isCompressing {
                    viewModel.isDragging = newValue
                }
            }
        }
        .onTapGesture {
            // Only open file picker when not compressing, not dragging and no file is selected
            if !viewModel.isCompressing && !viewModel.isDragging && viewModel.droppedFileURL == nil {
                viewModel.openFilePicker()
            }
        }
        .contentShape(Rectangle()) // Make entire area tappable
    }

    private var iconName: String {
        if viewModel.isDragging {
            return "arrow.down.circle.fill"
        } else if viewModel.droppedFileURL != nil {
            return "checkmark.circle.fill"
        } else {
            return "doc.badge.plus"
        }
    }

    private var iconColor: Color {
        if viewModel.isDragging {
            return .accentColor
        } else if viewModel.droppedFileURL != nil {
            return .green
        } else {
            return .secondary
        }
    }

    private var iconBackgroundColor: Color {
        if viewModel.isDragging {
            return Color.accentColor.opacity(0.15)
        } else if viewModel.droppedFileURL != nil {
            return Color.green.opacity(0.15)
        } else {
            return Color.secondary.opacity(0.1)
        }
    }

    private var backgroundColor: Color {
        if viewModel.isDragging {
            return Color.accentColor.opacity(0.08)
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        if viewModel.isDragging {
            return .accentColor
        } else if viewModel.droppedFileURL != nil {
            return .green.opacity(0.5)
        } else {
            return .secondary.opacity(0.3)
        }
    }

    private var mainMessage: String {
        if viewModel.isDragging {
            return "Drop your file here"
        } else if viewModel.droppedFileURL != nil {
            return viewModel.droppedFileURL?.lastPathComponent ?? "File ready"
        } else {
            return "Drop your file here"
        }
    }

    private var subtitleMessage: String? {
        if viewModel.isDragging {
            return "Release to add file"
        } else if viewModel.droppedFileURL != nil {
            return "Ready to compress"
        } else {
            return "or click to browse"
        }
    }
}

#Preview {
    DropZoneView(viewModel: MainViewModel.shared)
        .frame(width: 340, height: 160)
        .padding()
}
