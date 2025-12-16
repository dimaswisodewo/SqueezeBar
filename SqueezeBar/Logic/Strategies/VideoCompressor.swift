//
//  VideoCompressor.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers

class VideoCompressor: CompressionStrategy {
    var supportedTypes: [UTType] {
        [.mpeg4Movie, .quickTimeMovie, .movie, .mpeg2Video]
    }

    func compress(inputURL: URL, outputURL: URL, quality: Double) async throws -> CompressionResult {
        // Validate input file exists
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw CompressionError.fileNotFound
        }

        // Get original file size
        let originalSize = try getFileSize(at: inputURL)

        // Delete output file if it exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        // Load asset
        let asset = AVAsset(url: inputURL)

        // Select export preset based on quality
        let presetName = selectPreset(for: quality, asset: asset)

        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            throw CompressionError.compressionFailed("Cannot create export session")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        // Export the video
        await exportSession.export()

        // Check export status
        switch exportSession.status {
        case .completed:
            // Get compressed file size
            let compressedSize = try getFileSize(at: outputURL)

            return CompressionResult(
                originalURL: inputURL,
                compressedURL: outputURL,
                originalSize: originalSize,
                compressedSize: compressedSize
            )

        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            throw CompressionError.compressionFailed(errorMessage)

        case .cancelled:
            throw CompressionError.compressionFailed("Export was cancelled")

        default:
            throw CompressionError.compressionFailed("Export failed with status: \(exportSession.status.rawValue)")
        }
    }

    private func selectPreset(for quality: Double, asset: AVAsset) -> String {
        // Get compatible presets for the asset using the modern async API
        let compatiblePresets: [String]
        if #available(macOS 13.0, *) {
            // Use the new API that returns async sequence
            compatiblePresets = AVAssetExportSession.allExportPresets()
        } else {
            // Fallback for older systems
            compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        }

        // Select preset based on quality level
        if quality < 0.4 {
            // Low quality
            if compatiblePresets.contains(AVAssetExportPresetLowQuality) {
                return AVAssetExportPresetLowQuality
            }
        } else if quality < 0.7 {
            // Medium quality
            if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
                return AVAssetExportPresetMediumQuality
            }
        } else {
            // High quality - prefer HEVC for better compression
            if compatiblePresets.contains(AVAssetExportPresetHEVC1920x1080) {
                return AVAssetExportPresetHEVC1920x1080
            } else if compatiblePresets.contains(AVAssetExportPresetHighestQuality) {
                return AVAssetExportPresetHighestQuality
            }
        }

        // Fallback to medium quality
        return AVAssetExportPresetMediumQuality
    }

    private func getFileSize(at url: URL) throws -> Int64 {
        // Use resourceValues API which is more efficient than attributesOfItem
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }
}
