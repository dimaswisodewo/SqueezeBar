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

        // Choose compression path based on framerate setting
        if let fps = targetFramerate {
            // Validate minimum framerate
            guard fps >= 1.0 else {
                throw CompressionError.compressionFailed("Invalid framerate: \(fps). Must be at least 1 fps")
            }

            // Use AVAssetReader/Writer for framerate control
            return try await compressWithFramerateControl(
                asset: asset,
                inputURL: inputURL,
                outputURL: outputURL,
                quality: quality,
                targetFramerate: fps,
                originalSize: originalSize
            )
        } else {
            // Use existing AVAssetExportSession path
            return try await compressWithExportSession(
                asset: asset,
                inputURL: inputURL,
                outputURL: outputURL,
                quality: quality,
                originalSize: originalSize
            )
        }
    }

    /// Compress using AVAssetExportSession (original implementation)
    private func compressWithExportSession(
        asset: AVAsset,
        inputURL: URL,
        outputURL: URL,
        quality: Double,
        originalSize: Int64
    ) async throws -> CompressionResult {
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

    /// Compress using AVAssetReader/Writer with framerate control
    private func compressWithFramerateControl(
        asset: AVAsset,
        inputURL: URL,
        outputURL: URL,
        quality: Double,
        targetFramerate: Double,
        originalSize: Int64
    ) async throws -> CompressionResult {
        // Get video track
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw CompressionError.compressionFailed("No video track found")
        }

        // Get original framerate
        let originalFramerate = try await videoTrack.load(.nominalFrameRate)

        // Check for variable framerate
        guard originalFramerate > 0 else {
            throw CompressionError.compressionFailed("Variable framerate video detected. Please use 'Original' framerate mode.")
        }

        // Validate target framerate doesn't exceed original
        guard targetFramerate <= Double(originalFramerate) else {
            throw CompressionError.compressionFailed(
                "Cannot increase framerate from \(String(format: "%.0f", originalFramerate)) fps to \(String(format: "%.0f", targetFramerate)) fps. Framerate can only be reduced."
            )
        }

        // Setup reader
        let reader = try AVAssetReader(asset: asset)
        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(videoReaderOutput)

        // Setup writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        // Get video properties
        let videoSize = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)

        // Calculate bitrate
        let bitrate = calculateBitrate(for: quality, size: videoSize, framerate: targetFramerate)

        // Select codec based on quality
        let codec: AVVideoCodecType = quality >= 0.7 ? .hevc : .h264

        // Configure video output settings
        var compressionProperties: [String: Any] = [
            AVVideoAverageBitRateKey: bitrate,
            AVVideoMaxKeyFrameIntervalKey: 60
        ]

        // Only set profile level for H.264 (HEVC handles this automatically)
        if codec == .h264 {
            compressionProperties[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel
        }

        let videoWriterSettings: [String: Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
            AVVideoCompressionPropertiesKey: compressionProperties
        ]

        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterSettings)
        videoWriterInput.expectsMediaDataInRealTime = false
        videoWriterInput.transform = transform
        writer.add(videoWriterInput)

        // Handle audio track
        var audioWriterInput: AVAssetWriterInput?
        var audioReaderOutput: AVAssetReaderTrackOutput?
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            // Get format description for the audio track
            let formatDescriptions = try await audioTrack.load(.formatDescriptions)
            guard let audioFormatDescription = formatDescriptions.first else {
                throw CompressionError.compressionFailed("Failed to get audio format description")
            }

            // Create audio input with format hint for passthrough
            let audioInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: nil,
                sourceFormatHint: audioFormatDescription 
            )
            audioInput.expectsMediaDataInRealTime = false
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            reader.add(audioOutput)
            writer.add(audioInput)
            audioWriterInput = audioInput
            audioReaderOutput = audioOutput
        }

        // Start reading and writing
        guard reader.startReading() else {
            throw CompressionError.compressionFailed("Failed to start reading: \(reader.error?.localizedDescription ?? "Unknown error")")
        }

        guard writer.startWriting() else {
            throw CompressionError.compressionFailed("Failed to start writing: \(writer.error?.localizedDescription ?? "Unknown error")")
        }

        writer.startSession(atSourceTime: .zero)

        // Process video and audio concurrently to avoid deadlock
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Process video frames
            group.addTask {
                try await self.processFrames(
                    readerOutput: videoReaderOutput,
                    writerInput: videoWriterInput,
                    originalFPS: originalFramerate,
                    targetFPS: targetFramerate
                )
            }

            // Process audio (if available)
            if let audioInput = audioWriterInput, let audioOutput = audioReaderOutput {
                group.addTask {
                    try await self.processAudio(readerOutput: audioOutput, writerInput: audioInput)
                }
            }

            // Wait for both tasks to complete
            try await group.waitForAll()
        }

        // Finalize writing
        videoWriterInput.markAsFinished()
        audioWriterInput?.markAsFinished()

        await writer.finishWriting()

        // Check for errors
        if writer.status == .failed {
            print("ERROR >> \(writer.error.debugDescription)")
            throw CompressionError.compressionFailed("Writing failed: \(writer.error?.localizedDescription ?? "Unknown error")")
        }

        // Get compressed file size
        let compressedSize = try getFileSize(at: outputURL)

        return CompressionResult(
            originalURL: inputURL,
            compressedURL: outputURL,
            originalSize: originalSize,
            compressedSize: compressedSize
        )
    }

    /// Calculate bitrate based on quality, resolution, and framerate
    private func calculateBitrate(for quality: Double, size: CGSize, framerate: Double) -> Int {
        let pixels = size.width * size.height
        let bitsPerPixel = 0.05 + (quality * 0.10)
        let baseBitrate = pixels * framerate * bitsPerPixel
        let codecFactor = quality >= 0.7 ? 0.8 : 1.0
        return Int(baseBitrate * codecFactor)
    }

    /// Process video frames with framerate conversion
    private func processFrames(
        readerOutput: AVAssetReaderTrackOutput,
        writerInput: AVAssetWriterInput,
        originalFPS: Float,
        targetFPS: Double
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "com.squeezebar.videoprocessing")

            var frameIndex: Double = 0
            var sampledFrameCount: Int = 0
            let samplingInterval = Double(originalFPS) / targetFPS
            var hasResumed = false

            func processNextFrame() {
                guard writerInput.isReadyForMoreMediaData else {
                    // Not ready yet, callback will be invoked again when ready
                    return
                }

                guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                    // No more samples - finished
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                    return
                }

                // Frame sampling logic (reduction only)
                if targetFPS >= Double(originalFPS) {
                    // Same framerate or higher (prevented by validation): direct pass-through
                    writerInput.append(sampleBuffer)
                } else {
                    // Reduce framerate: intelligently skip frames
                    if frameIndex >= Double(sampledFrameCount) * samplingInterval {
                        writerInput.append(sampleBuffer)
                        sampledFrameCount += 1
                    }
                }

                frameIndex += 1

                // Process next frame recursively
                processNextFrame()
            }

            writerInput.requestMediaDataWhenReady(on: queue) {
                processNextFrame()
            }
        }
    }

    /// Process audio track (passthrough)
    private func processAudio(
        readerOutput: AVAssetReaderTrackOutput,
        writerInput: AVAssetWriterInput
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "com.squeezebar.audioprocessing")

            var hasResumed = false

            func processNextAudioSample() {
                guard writerInput.isReadyForMoreMediaData else {
                    // Not ready yet, callback will be invoked again when ready
                    return
                }

                guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                    // No more samples - finished
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                    return
                }

                writerInput.append(sampleBuffer)

                // Process next sample recursively
                processNextAudioSample()
            }

            writerInput.requestMediaDataWhenReady(on: queue) {
                processNextAudioSample()
            }
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
