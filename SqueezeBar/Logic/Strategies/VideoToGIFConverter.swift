import Foundation
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

final class VideoToGIFConverter: ConversionStrategy {
    static let maximumDuration: Double = 30

    var supportedInputTypes: [UTType] { [.mpeg4Movie, .quickTimeMovie, .movie, .mpeg2Video] }

    func convert(inputURL: URL, outputURL: URL, options: ConversionOptions) async throws -> ConversionResult {
        // Detached work keeps GIF encoding and finalization off the UI actor.
        let worker = Task.detached(priority: .userInitiated) {
            do {
                return try await Self.encode(inputURL: inputURL, outputURL: outputURL, options: options)
            } catch {
                if Task.isCancelled { throw CancellationError() }
                throw error
            }
        }
        return try await withTaskCancellationHandler(operation: {
            try await worker.value
        }, onCancel: {
            worker.cancel()
        })
    }

    private static func encode(inputURL: URL, outputURL: URL, options: ConversionOptions) async throws -> ConversionResult {
        try Task.checkCancellation()
        guard FileManager.default.fileExists(atPath: inputURL.path) else { throw ConversionError.fileNotFound }
        guard let selectedFPS = options.gifFramerate, selectedFPS.isFinite,
              (1...30).contains(selectedFPS), selectedFPS == selectedFPS.rounded() else {
            throw ConversionError.invalidOptions
        }
        let asset = AVURLAsset(url: inputURL)
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else {
            throw ConversionError.conversionFailed("Could not determine a valid video duration.")
        }
        guard duration <= maximumDuration else {
            throw ConversionError.conversionFailed("Video is longer than 30 seconds. Trim it before creating a GIF.")
        }
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ConversionError.conversionFailed("The file has no video track.")
        }
        let sourceFPS = Double((try? await track.load(.nominalFrameRate)) ?? 0)
        let fps = sourceFPS.isFinite && sourceFPS > 0 ? min(selectedFPS, sourceFPS) : selectedFPS
        // Nominal FPS is a Float; tolerate its rounding error at exact frame boundaries.
        let frameCount = min(900, max(1, Int(ceil(duration * fps - 0.0001))))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let size = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let orientedSize = CGRect(origin: .zero, size: size).applying(transform).size
        guard orientedSize.width.isFinite, orientedSize.height.isFinite,
              orientedSize.width > 0, orientedSize.height > 0 else {
            throw ConversionError.conversionFailed("The video has invalid dimensions.")
        }
        if let maximumEdge = options.gifResolution.maximumEdge {
            // A square bound preserves aspect ratio after orientation and never upscales.
            let longestEdge = min(maximumEdge, max(orientedSize.width, orientedSize.height))
            generator.maximumSize = CGSize(width: longestEdge, height: longestEdge)
        } else {
            // Zero removes the generator's size cap while retaining the track transform.
            generator.maximumSize = .zero
        }
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        try Task.checkCancellation()

        var finished = false
        defer {
            generator.cancelAllCGImageGeneration()
            if !finished { try? FileManager.default.removeItem(at: outputURL) }
        }
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.gif.identifier as CFString,
                                                               frameCount, nil) else {
            throw ConversionError.conversionFailed("Could not create the GIF output.")
        }
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)

        // GIF stores centiseconds. Round cumulative boundaries rather than every frame
        // independently so fractional FPS does not accumulate timing drift.
        var previousBoundary = 0
        for index in 0..<frameCount {
            try Task.checkCancellation()
            let time = CMTime(seconds: Double(index) / fps, preferredTimescale: 60000)
            let image = try await frame(from: generator, at: time)
            try Task.checkCancellation()
            autoreleasepool {
                let end = min(duration, Double(index + 1) / fps)
                let boundary = max(previousBoundary + 1, Int((end * 100).rounded()))
                let delay = Double(boundary - previousBoundary) / 100
                previousBoundary = boundary
                let properties: [CFString: Any] = [kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: delay,
                    kCGImagePropertyGIFUnclampedDelayTime: delay
                ]]
                CGImageDestinationAddImage(destination, image, properties as CFDictionary)
            }
        }
        try Task.checkCancellation()
        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed("Failed to write the GIF output.")
        }
        try Task.checkCancellation()
        let outputSize = try outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        finished = true
        return ConversionResult(inputURL: inputURL, outputURL: outputURL,
                                inputFormat: inputURL.pathExtension.uppercased(), outputFormat: "GIF",
                                outputSize: Int64(outputSize))
    }

    private static func frame(from generator: AVAssetImageGenerator, at time: CMTime) async throws -> CGImage {
        try Task.checkCancellation()
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, result, error in
                    switch result {
                    case .succeeded:
                        if let image { continuation.resume(returning: image) }
                        else { continuation.resume(throwing: ConversionError.conversionFailed("Could not decode a video frame.")) }
                    case .cancelled:
                        continuation.resume(throwing: CancellationError())
                    case .failed:
                        continuation.resume(throwing: error ?? ConversionError.conversionFailed("Could not decode a video frame."))
                    @unknown default:
                        continuation.resume(throwing: ConversionError.conversionFailed("Unexpected frame extraction status."))
                    }
                }
            }
        }, onCancel: {
            generator.cancelAllCGImageGeneration()
        })
    }
}
