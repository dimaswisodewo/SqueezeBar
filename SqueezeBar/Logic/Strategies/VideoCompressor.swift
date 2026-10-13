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

    func compress(inputURL: URL, outputURL: URL, quality: Double, targetFramerate: Double? = nil) async throws -> CompressionResult {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw CompressionError.fileNotFound
        }
        guard !FileManager.default.fileExists(atPath: outputURL.path) else {
            throw CompressionError.compressionFailed("Output file already exists")
        }
        if let fps = targetFramerate {
            guard fps.isFinite && fps >= 1 else {
                throw CompressionError.compressionFailed("Invalid framerate: \(fps). Must be finite and at least 1 fps")
            }
        }

        let originalSize = try getFileSize(at: inputURL)
        let asset = AVURLAsset(url: inputURL)
        let presetName = selectPreset(for: quality, asset: asset)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            throw CompressionError.compressionFailed("Cannot create export session")
        }

        if let fps = targetFramerate {
            exportSession.videoComposition = try await makeVideoComposition(asset: asset, targetFramerate: fps)
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        var completed = false
        defer {
            if !completed {
                try? FileManager.default.removeItem(at: outputURL)
            }
        }

        await exportSession.export()
        switch exportSession.status {
        case .completed:
            let compressedSize = try getFileSize(at: outputURL)
            completed = true
            return CompressionResult(
                originalURL: inputURL,
                compressedURL: outputURL,
                originalSize: originalSize,
                compressedSize: compressedSize
            )
        case .failed:
            throw CompressionError.compressionFailed(exportSession.error?.localizedDescription ?? "Unknown error")
        case .cancelled:
            throw CompressionError.compressionFailed("Export was cancelled")
        default:
            throw CompressionError.compressionFailed("Export failed with status: \(exportSession.status.rawValue)")
        }
    }

    private func makeVideoComposition(asset: AVAsset, targetFramerate: Double) async throws -> AVVideoComposition? {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw CompressionError.compressionFailed("No video track found")
        }
        let sourceFramerate = try await videoTrack.load(.nominalFrameRate)
        guard sourceFramerate.isFinite && sourceFramerate > 0 else {
            throw CompressionError.compressionFailed("Cannot determine source frame rate. Disable FPS reduction and try again.")
        }
        guard targetFramerate < Double(sourceFramerate) else { return nil }

        let size = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)
        let bounds = CGRect(origin: .zero, size: size).applying(transform)
        let duration = try await asset.load(.duration)
        guard bounds.width.isFinite && bounds.height.isFinite && bounds.width > 0 && bounds.height > 0,
              duration.isNumeric && duration.seconds > 0 else {
            throw CompressionError.compressionFailed("Invalid video dimensions or duration")
        }

        let composition = AVMutableVideoComposition()
        composition.renderSize = bounds.size
        // Round the frame interval up so fractional targets remain an upper FPS limit.
        composition.frameDuration = CMTime(value: Int64(ceil(60000 / targetFramerate)), timescale: 60000)
        composition.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid

        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        // Normalize the transformed bounds to preserve portrait and translated tracks.
        let renderTransform = transform.concatenating(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
        layer.setTransform(renderTransform, at: .zero)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        instruction.layerInstructions = [layer]
        composition.instructions = [instruction]
        return composition
    }

    private func selectPreset(for quality: Double, asset: AVAsset) -> String {
        // exportPresets(compatibleWith:) is available since macOS 10.7 and returns only compatible presets
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)

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
