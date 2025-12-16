//
//  MainViewModel.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

class MainViewModel: ObservableObject {
    // Singleton instance
    static let shared = MainViewModel()

    @Published var isDragging = false
    @Published var droppedFileURL: URL?
    @Published var statusMessage = ""
    @Published var isCompressing = false
    @Published var lastResult: CompressionResult?
    @Published var errorMessage: String?
    @Published var fileTypeHint: String?
    @Published var fileSizeString: String?

    private let compressionManager = CompressionManager()
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()

    // Private init to enforce singleton
    private init() {}

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Load file URL asynchronously
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, error in
            // Ensure all UI updates happen on the next run loop to avoid publishing during view updates
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    return
                }

                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    self.droppedFileURL = url
                    self.statusMessage = ""
                    self.errorMessage = nil

                    // Update file info
                    let ext = url.pathExtension.uppercased()
                    self.fileTypeHint = ext.isEmpty ? nil : ext

                    // Use resourceValues API which is more efficient than attributesOfItem
                    if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
                       let size = resourceValues.fileSize {
                        self.fileSizeString = self.byteFormatter.string(fromByteCount: Int64(size))
                    } else {
                        self.fileSizeString = nil
                    }
                } else {
                    self.statusMessage = ""
                    self.errorMessage = "Could not read file"
                }
            }
        }

        return true
    }

    func handleFileOpen(url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.droppedFileURL = url
            self.statusMessage = ""
            self.errorMessage = nil

            // Update file info (same logic as handleDrop)
            let ext = url.pathExtension.uppercased()
            self.fileTypeHint = ext.isEmpty ? nil : ext

            if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                self.fileSizeString = self.byteFormatter.string(fromByteCount: Int64(size))
            } else {
                self.fileSizeString = nil
            }
        }
    }

    func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a file to compress"
        panel.prompt = "Select"

        // Allow common file types
        panel.allowedContentTypes = [
            .pdf,
            .image,
            .movie,
            .video,
            .png,
            .jpeg,
            .heic,
            .mpeg4Movie,
            .quickTimeMovie
        ]
        panel.allowsOtherFileTypes = true

        if panel.runModal() == .OK {
            if let url = panel.url {
                handleFileOpen(url: url)
            }
        }
    }

    func removeAttachedFile() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.droppedFileURL = nil
            self.statusMessage = ""
            self.errorMessage = nil
            self.fileTypeHint = nil
            self.fileSizeString = nil
        }
    }

    func openResultFolder() {
        guard let result = lastResult else { return }

        // Perform file system operation on background queue to avoid freezing UI
        DispatchQueue.global(qos: .userInitiated).async {
            // Get the folder containing the compressed file
            let folderURL = result.compressedURL.deletingLastPathComponent()
            NSWorkspace.shared.open(folderURL)
        }
    }

    func compressFile(settings: AppSettings) async {
        guard let inputURL = droppedFileURL else { return }
        guard let outputFolder = settings.outputFolderURL else {
            await MainActor.run {
                errorMessage = "Please choose a save location first"
            }
            return
        }

        // Ensure we have access to the output folder
        guard settings.ensureAccess() else {
            await MainActor.run {
                errorMessage = "Cannot access save location. Please choose again."
            }
            return
        }

        await MainActor.run {
            isCompressing = true
            errorMessage = nil
            statusMessage = getCompressionMessage(for: settings.compressionMode)
        }

        // Start accessing the input file
        let inputAccessing = inputURL.startAccessingSecurityScopedResource()

        do {
            // Calculate quality based on mode
            let quality = try calculateQuality(settings: settings, inputURL: inputURL)

            let result = try await compressionManager.compress(
                inputURL: inputURL,
                outputFolder: outputFolder,
                quality: quality
            )

            await MainActor.run {
                lastResult = result
                statusMessage = formatSuccessMessage(result: result, mode: settings.compressionMode)
            }

            // Reset dropped file after successful compression with optimized sleep
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                self.droppedFileURL = nil
                self.statusMessage = ""
                self.lastResult = nil
                self.fileTypeHint = nil
                self.fileSizeString = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = formatErrorMessage(error)
                statusMessage = ""
            }
        }

        // Stop accessing the input file if we started
        if inputAccessing {
            inputURL.stopAccessingSecurityScopedResource()
        }

        await MainActor.run {
            isCompressing = false
        }
    }

    private func getCompressionMessage(for mode: CompressionMode) -> String {
        switch mode {
        case .quality:
            return "Compressing with quality settings..."
        case .targetSize:
            return "Compressing to target size..."
        case .percentage:
            return "Reducing file size..."
        }
    }

    private func calculateQuality(settings: AppSettings, inputURL: URL) throws -> Double {
        switch settings.compressionMode {
        case .quality:
            return settings.effectiveQuality

        case .targetSize:
            // Estimate quality needed to reach target size
            guard let resourceValues = try? inputURL.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey]),
                  let fileSize = resourceValues.fileSize,
                  let contentType = resourceValues.contentType else {
                return 0.5
            }

            let targetBytes = Double(settings.targetSizeMB * 1024 * 1024)
            let originalBytes = Double(fileSize)

            // If target is larger than or close to original, use high quality
            if targetBytes >= originalBytes * 0.95 {
                return 0.95
            }

            let targetRatio = targetBytes / originalBytes

            // Calculate quality based on file type
            // Different file types have different quality-to-compression characteristics
            let quality: Double

            if contentType.conforms(to: .pdf) {
                // PDF compression with Ghostscript uses discrete settings:
                // /prepress (q>=0.8), /ebook (0.5<=q<0.8), /screen (q<0.5)
                // Map target ratios to these settings more intelligently
                if targetRatio > 0.7 {
                    quality = 0.85  // /prepress
                } else if targetRatio > 0.4 {
                    quality = 0.65  // /ebook
                } else {
                    // For /screen, interpolate within the lower range
                    quality = max(0.1, 0.4 + (targetRatio - 0.1) * 0.3)
                }
            } else if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
                // Video compression uses AVFoundation presets with discrete quality levels
                // Map to preset boundaries: Low (<0.4), Medium (0.4-0.7), High (>=0.7)
                if targetRatio > 0.75 {
                    quality = 0.85  // High quality preset
                } else if targetRatio > 0.5 {
                    quality = 0.55  // Medium quality preset
                } else {
                    quality = 0.25  // Low quality preset
                }
            } else {
                // Image compression (JPEG, PNG, HEIC, etc.)
                // Quality-to-size relationship is roughly logarithmic
                // Empirical formula: size ≈ 0.15 + 0.85 * quality^1.8
                // Solving for quality: quality ≈ ((size - 0.15) / 0.85)^(1/1.8)

                let adjustedRatio = max(0.15, targetRatio)  // Account for baseline size
                let normalizedRatio = (adjustedRatio - 0.15) / 0.85
                quality = pow(normalizedRatio, 1.0 / 1.8)
            }

            // Clamp between practical bounds
            return min(max(quality, 0.1), 0.95)

        case .percentage:
            // Estimate quality needed to achieve percentage reduction
            guard let resourceValues = try? inputURL.resourceValues(forKeys: [.contentTypeKey]),
                  let contentType = resourceValues.contentType else {
                return 0.5
            }

            let reductionFactor = settings.compressionPercentage / 100.0
            let targetRatio = 1.0 - reductionFactor  // Target size as ratio of original

            // Use inverse of compression models
            let quality: Double

            if contentType.conforms(to: .pdf) {
                // Map target ratio to Ghostscript settings
                if targetRatio > 0.7 {
                    quality = 0.85
                } else if targetRatio > 0.4 {
                    quality = 0.65
                } else {
                    quality = max(0.1, 0.4 + (targetRatio - 0.1) * 0.3)
                }
            } else if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
                // Map to video preset boundaries
                if targetRatio > 0.75 {
                    quality = 0.85
                } else if targetRatio > 0.5 {
                    quality = 0.55
                } else {
                    quality = 0.25
                }
            } else {
                // Image: Use inverse logarithmic formula
                // Given target ratio, solve: ratio = 0.15 + 0.85 * quality^1.8
                let adjustedRatio = max(0.15, targetRatio)
                let normalizedRatio = (adjustedRatio - 0.15) / 0.85
                quality = pow(normalizedRatio, 1.0 / 1.8)
            }

            // Clamp between practical bounds
            return min(max(quality, 0.1), 0.95)
        }
    }

    private func formatSuccessMessage(result: CompressionResult, mode: CompressionMode) -> String {
        let saved = formatBytes(result.savedBytes)
        let percent = String(format: "%.0f", result.savedPercentage)

        switch mode {
        case .quality:
            return "✓ Saved \(saved) (\(percent)% smaller)"
        case .targetSize:
            let finalSize = formatBytes(result.compressedSize)
            return "✓ Compressed to \(finalSize) • Saved \(percent)%"
        case .percentage:
            return "✓ Reduced by \(percent)% • Saved \(saved)"
        }
    }

    private func formatErrorMessage(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.contains("could not create output file") {
            return "Cannot save file. Check folder permissions."
        } else if message.contains("permission") {
            return "Permission denied. Try selecting a different folder."
        } else if message.contains("unsupported") {
            return "This file type is not supported."
        } else {
            return "Compression failed: \(message)"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        return byteFormatter.string(fromByteCount: bytes)
    }
}
