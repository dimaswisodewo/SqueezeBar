//
//  ConversionManager.swift
//  SqueezeBar
//

import Foundation
import UniformTypeIdentifiers

@MainActor
class ConversionManager {
    private var strategies: [ConversionCategory: ConversionStrategy]

    init() {
        strategies = [
            .imageToImage: ImageFormatConverter(),
            .videoToVideo: VideoFormatConverter(),
            .videoToAudio: VideoToAudioConverter()
        ]
    }

    func convert(
        inputURL: URL,
        outputFolder: URL,
        category: ConversionCategory,
        options: ConversionOptions
    ) async throws -> ConversionResult {
        guard let strategy = strategies[category] else {
            throw ConversionError.unsupportedFileType
        }

        let output = outputURL(for: inputURL, category: category, options: options, in: outputFolder)
        return try await strategy.convert(inputURL: inputURL, outputURL: output, options: options)
    }

    private func outputURL(
        for inputURL: URL,
        category: ConversionCategory,
        options: ConversionOptions,
        in outputFolder: URL
    ) -> URL {
        let filename = inputURL.deletingPathExtension().lastPathComponent

        // Determine extension from options or fall back to input extension
        let ext: String
        switch category {
        case .imageToImage:
            ext = options.imageOutputFormat?.fileExtension ?? inputURL.pathExtension
        case .videoToVideo:
            ext = options.videoOutputFormat?.fileExtension ?? inputURL.pathExtension
        case .videoToAudio:
            ext = "m4a"
        case .imageToPDF, .pdfProtect:
            ext = "pdf"
        }

        var outputURL = outputFolder
            .appendingPathComponent("\(filename).converted")
            .appendingPathExtension(ext)

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            let timestamp = Int(Date().timeIntervalSince1970)
            outputURL = outputFolder
                .appendingPathComponent("\(filename).converted.\(timestamp)")
                .appendingPathExtension(ext)

            if fileManager.fileExists(atPath: outputURL.path) {
                var counter = 1
                repeat {
                    outputURL = outputFolder
                        .appendingPathComponent("\(filename).converted.\(timestamp).\(counter)")
                        .appendingPathExtension(ext)
                    counter += 1
                } while fileManager.fileExists(atPath: outputURL.path) && counter < 1000
            }
        }

        return outputURL
    }
}
