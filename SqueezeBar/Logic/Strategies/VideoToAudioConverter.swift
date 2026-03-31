//
//  VideoToAudioConverter.swift
//  SqueezeBar
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers

class VideoToAudioConverter: ConversionStrategy {
    var supportedInputTypes: [UTType] {
        [.mpeg4Movie, .quickTimeMovie, .movie, .mpeg2Video]
    }

    func convert(inputURL: URL, outputURL: URL, options: ConversionOptions) async throws -> ConversionResult {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw ConversionError.fileNotFound
        }

        let asset = AVURLAsset(url: inputURL)

        // Verify audio track exists
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw ConversionError.conversionFailed("No audio track found in video")
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ConversionError.conversionFailed("Cannot create audio export session")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            break
        case .failed:
            throw ConversionError.conversionFailed(exportSession.error?.localizedDescription ?? "Audio export failed")
        case .cancelled:
            throw ConversionError.conversionFailed("Export was cancelled")
        default:
            throw ConversionError.conversionFailed("Unexpected export status")
        }

        let outputSize = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0

        return ConversionResult(
            inputURL: inputURL,
            outputURL: outputURL,
            inputFormat: inputURL.pathExtension.uppercased(),
            outputFormat: "M4A",
            outputSize: outputSize
        )
    }
}
