//
//  VideoFormatConverter.swift
//  SqueezeBar
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers

class VideoFormatConverter: ConversionStrategy {
    var supportedInputTypes: [UTType] {
        [.mpeg4Movie, .quickTimeMovie, .movie, .mpeg2Video]
    }

    func convert(inputURL: URL, outputURL: URL, options: ConversionOptions) async throws -> ConversionResult {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw ConversionError.fileNotFound
        }

        guard let targetFormat = options.videoOutputFormat else {
            throw ConversionError.invalidOptions
        }

        let asset = AVURLAsset(url: inputURL)

        // Try passthrough first (fast, lossless remux)
        do {
            try await exportVideo(asset: asset, outputURL: outputURL, preset: AVAssetExportPresetPassthrough, fileType: targetFormat.avFileType)
        } catch {
            // Clean up partial output before retrying
            try? FileManager.default.removeItem(at: outputURL)
            // Fall back to re-encoding at highest quality
            try await exportVideo(asset: asset, outputURL: outputURL, preset: AVAssetExportPresetHighestQuality, fileType: targetFormat.avFileType)
        }

        let outputSize = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0

        return ConversionResult(
            inputURL: inputURL,
            outputURL: outputURL,
            inputFormat: inputURL.pathExtension.uppercased(),
            outputFormat: targetFormat.displayName,
            outputSize: outputSize
        )
    }

    private func exportVideo(asset: AVURLAsset, outputURL: URL, preset: String, fileType: AVFileType) async throws {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw ConversionError.conversionFailed("Cannot create export session")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = fileType

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            break
        case .failed:
            throw ConversionError.conversionFailed(exportSession.error?.localizedDescription ?? "Export failed")
        case .cancelled:
            throw ConversionError.conversionFailed("Export was cancelled")
        default:
            throw ConversionError.conversionFailed("Unexpected export status")
        }
    }
}
