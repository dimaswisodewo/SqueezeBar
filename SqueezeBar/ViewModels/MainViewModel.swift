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
import AVFoundation

@MainActor
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
    @Published var isCurrentFileVideo = false
    @Published var videoFramerate: Float?
    @Published var appMode: AppMode = .compress
    @Published var isConverting: Bool = false
    @Published var lastConversionResult: ConversionResult?
    @Published var droppedFileURLs: [URL] = []
    @Published var suggestedConversionCategory: ConversionCategory?
    @Published private(set) var selectedInput: SelectedInput?
    @Published var selectedAction: FileAction = .compress
    @Published private(set) var availableActions: [FileAction] = []

    var isWorking: Bool { isCompressing || isConverting }
    var resultURL: URL? { lastResult?.compressedURL ?? lastConversionResult?.outputURL }

    private let compressionManager = CompressionManager()
    private let conversionManager = ConversionManager()
    private var resetTask: Task<Void, Never>?
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()

    // Private init to enforce singleton
    private init() {}

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        handleMultiDrop(providers: providers)
    }

    func handleMultiDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        Task {
            let urls = await withTaskGroup(of: (Int, URL?).self, returning: [URL?].self) { group in
                for (index, provider) in providers.enumerated() {
                    group.addTask {
                        let url = await withCheckedContinuation { continuation in
                            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                                if let data = item as? Data {
                                    continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
                                } else {
                                    continuation.resume(returning: item as? URL)
                                }
                            }
                        }
                        return (index, url)
                    }
                }
                var ordered = Array<URL?>(repeating: nil, count: providers.count)
                for await (index, url) in group { ordered[index] = url }
                return ordered
            }
            guard urls.allSatisfy({ $0 != nil }) else {
                errorMessage = "Could not read every dropped file."
                return
            }
            selectFiles(urls.compactMap { $0 })
        }
        return true
    }

    func removeFileFromList(_ url: URL) {
        guard case .images(let urls) = selectedInput else { return }
        let remaining = urls.filter { $0 != url }
        if remaining.isEmpty { removeAttachedFile() }
        else { selectFiles(remaining) }
    }

    func moveImage(from source: Int, to destination: Int) {
        guard case .images(var urls) = selectedInput,
              urls.indices.contains(source), urls.indices.contains(destination),
              source != destination else { return }
        let url = urls.remove(at: source)
        urls.insert(url, at: destination)
        selectedInput = .images(urls)
        droppedFileURLs = urls
        droppedFileURL = urls.first
    }

    func handleFileOpen(url: URL) { selectFiles([url]) }

    func selectFiles(_ urls: [URL]) {
        guard !isWorking else {
            errorMessage = "Wait for the current job to finish."
            return
        }
        let unique = Array(NSOrderedSet(array: urls)) as? [URL] ?? urls
        guard !unique.isEmpty else { return }
        let types = unique.map { (try? $0.resourceValues(forKeys: [.contentTypeKey]).contentType)
            ?? UTType(filenameExtension: $0.pathExtension) }
        let actions = types.map { type -> [FileAction] in
            guard let type else { return [] }
            if type.conforms(to: .pdf) { return [.compress, .protectPDF] }
            if type.conforms(to: .movie) || type.conforms(to: .video) {
                return [.compress, .videoFormat, .extractAudio]
            }
            if [.jpeg, .png, .heic, .heif, .bmp, .tiff, .gif].contains(where: { type.conforms(to: $0) }) {
                return type.conforms(to: .gif)
                    ? [.imageFormat, .createPDF] : [.compress, .imageFormat, .createPDF]
            }
            return []
        }
        guard actions.allSatisfy({ !$0.isEmpty }) else {
            errorMessage = "This file type is not supported."
            return
        }
        if unique.count > 1 && !actions.allSatisfy({ $0.contains(.createPDF) }) {
            errorMessage = "Select only images to create one PDF. Mixed files cannot be processed together."
            return
        }
        for (url, type) in zip(unique, types) {
            guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else { continue }
            let limit: Int64 = type?.conforms(to: .video) == true ? 10_737_418_240 :
                (type?.conforms(to: .pdf) == true ? 1_073_741_824 : 524_288_000)
            guard Int64(size) <= limit else {
                errorMessage = "\(url.lastPathComponent) is too large to process."
                return
            }
        }
        resetTask?.cancel()
        lastResult = nil
        lastConversionResult = nil
        statusMessage = ""
        errorMessage = nil
        selectedInput = unique.count == 1 ? .single(unique[0]) : .images(unique)
        availableActions = unique.count == 1 ? actions[0] : [.createPDF]
        selectedAction = availableActions[0]
        droppedFileURLs = unique
        droppedFileURL = unique[0]
        fileTypeHint = unique.count == 1 ? unique[0].pathExtension.uppercased() : "IMAGES"
        fileSizeString = unique.count == 1
            ? (try? unique[0].resourceValues(forKeys: [.fileSizeKey]).fileSize)
                .map { byteFormatter.string(fromByteCount: Int64($0)) }
            : "\(unique.count) files"
        isCurrentFileVideo = types[0]?.conforms(to: .video) == true || types[0]?.conforms(to: .movie) == true
        videoFramerate = nil
        if isCurrentFileVideo { Task { await extractVideoMetadata(from: unique[0]) } }
    }

    func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.message = "Add a file or select images to create a PDF"
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
            selectFiles(panel.urls)
        }
    }

    func removeAttachedFile() {
        resetTask?.cancel()
        resetTask = nil
        droppedFileURL = nil
        droppedFileURLs = []
        selectedInput = nil
        availableActions = []
        lastResult = nil
        lastConversionResult = nil
        statusMessage = ""
        errorMessage = nil
        fileTypeHint = nil
        fileSizeString = nil
        isCurrentFileVideo = false
        videoFramerate = nil
        suggestedConversionCategory = nil
    }
  
    func removeAttachedFileWithoutResetingStatusMessage() {
        // Retain input and controls after processing.
    }

    private func extractVideoMetadata(from url: URL) async {
        let asset = AVAsset(url: url)

        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            videoFramerate = nil
            return
        }

        let fps = try? await videoTrack.load(.nominalFrameRate)
        let rounded = floor(fps ?? 0)
        videoFramerate = rounded > 0 ? rounded : nil
    }

    func openResultFolder() {
        let url = lastResult?.compressedURL ?? lastConversionResult?.outputURL
        guard let folder = url?.deletingLastPathComponent() else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            NSWorkspace.shared.open(folder)
        }
    }

    func showResultInFinder() {
        guard let url = resultURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func dismissResult() {
        lastResult = nil
        lastConversionResult = nil
        statusMessage = ""
    }

    func process(settings: AppSettings) async {
        guard availableActions.contains(selectedAction) else { return }
        if let category = selectedAction.conversionCategory {
            settings.conversionCategory = category
            settings.saveConversionSettings()
            await convertFile(settings: settings)
        } else {
            await compressFile(settings: settings)
        }
    }

    func convertFile(settings: AppSettings) async {
        guard let outputFolder = settings.outputFolderURL else {
            errorMessage = "Please choose a save location first"
            return
        }

        guard settings.ensureAccess() else {
            errorMessage = "Cannot access save location. Please choose again."
            return
        }

        // imageToPDF uses multi-file input
        if settings.conversionCategory == .imageToPDF {
            guard !droppedFileURLs.isEmpty else { return }

            isConverting = true
            errorMessage = nil
            lastConversionResult = nil
            statusMessage = "Creating PDF..."

            let accessedURLs = droppedFileURLs.filter { $0.startAccessingSecurityScopedResource() }

            defer {
                for url in accessedURLs {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let result = try await conversionManager.convertImagesToPDF(
                    inputURLs: droppedFileURLs,
                    outputFolder: outputFolder
                )

                lastConversionResult = result
                statusMessage = "✓ Created PDF (\(byteFormatter.string(fromByteCount: result.outputSize)))"
                isConverting = false

            } catch {
                errorMessage = formatConversionError(error)
                statusMessage = ""
                isConverting = false
            }
            return
        }

        guard let inputURL = droppedFileURL else { return }

        isConverting = true
        errorMessage = nil
        lastConversionResult = nil
        statusMessage = "Converting..."

        let inputAccessing = inputURL.startAccessingSecurityScopedResource()

        defer {
            if inputAccessing {
                inputURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let options = ConversionOptions(
                imageOutputFormat: settings.imageOutputFormat,
                imageQuality: settings.imageConversionQuality,
                videoOutputFormat: settings.videoOutputFormat,
                pdfPassword: settings.conversionCategory == .pdfProtect ? settings.pdfPassword : nil
            )

            let result = try await conversionManager.convert(
                inputURL: inputURL,
                outputFolder: outputFolder,
                category: settings.conversionCategory,
                options: options
            )

            lastConversionResult = result
            statusMessage = "✓ Converted to \(result.outputFormat) (\(byteFormatter.string(fromByteCount: result.outputSize)))"
            isConverting = false

        } catch {
            errorMessage = formatConversionError(error)
            statusMessage = ""
            isConverting = false
        }
    }

    private func formatConversionError(_ error: Error) -> String {
        if let convError = error as? ConversionError {
            switch convError {
            case .unsupportedFileType: return "File type not supported for this conversion."
            case .fileNotFound: return "Input file not found."
            case .conversionFailed(let msg): return msg
            case .outputFolderNotSet: return "Please select an output folder."
            case .invalidOptions: return "Invalid conversion options."
            case .passwordMismatch: return "Passwords do not match."
            }
        }
        return error.localizedDescription
    }

    func compressFile(settings: AppSettings) async {
        guard let inputURL = droppedFileURL else { return }
        guard let outputFolder = settings.outputFolderURL else {
            errorMessage = "Please choose a save location first"
            return
        }

        guard settings.ensureAccess() else {
            errorMessage = "Cannot access save location. Please choose again."
            return
        }

        isCompressing = true
        errorMessage = nil
        lastResult = nil
        statusMessage = getCompressionMessage(for: settings.compressionMode)

        let inputAccessing = inputURL.startAccessingSecurityScopedResource()

        defer {
            if inputAccessing {
                inputURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let quality = try calculateQuality(settings: settings, inputURL: inputURL)
            let targetFramerate = settings.effectiveFramerate

            let result = try await compressionManager.compress(
                inputURL: inputURL,
                outputFolder: outputFolder,
                quality: quality,
                targetFramerate: targetFramerate
            )

            lastResult = result
            statusMessage = formatSuccessMessage(result: result, mode: settings.compressionMode)
            // Unblock immediately so the user can start another compression
            isCompressing = false

        } catch {
            errorMessage = formatErrorMessage(error)
            statusMessage = ""
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
