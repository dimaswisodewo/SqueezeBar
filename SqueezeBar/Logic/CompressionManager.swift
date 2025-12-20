//
//  CompressionManager.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation
import UniformTypeIdentifiers

class CompressionManager {
    private let strategies: [CompressionStrategy] = [
        ImageCompressor(),
        VideoCompressor(),
        PDFCompressor()
    ]

    // Cache strategy mappings for faster lookup
    private lazy var strategyMap: [UTType: CompressionStrategy] = {
        var map: [UTType: CompressionStrategy] = [:]
        for strategy in strategies {
            for type in strategy.supportedTypes {
                map[type] = strategy
            }
        }
        return map
    }()

    /// Compresses a file and saves it to the specified output folder
    /// - Parameters:
    ///   - inputURL: The URL of the file to compress
    ///   - outputFolder: The folder where the compressed file should be saved
    ///   - quality: Quality factor between 0.0 and 1.0
    ///   - targetFramerate: Optional target framerate for video files (nil maintains original)
    /// - Returns: CompressionResult containing details about the compression
    /// - Throws: CompressionError if compression fails
    func compress(inputURL: URL, outputFolder: URL, quality: Double, targetFramerate: Double? = nil) async throws -> CompressionResult {
        // Validate quality
        guard quality >= 0.0 && quality <= 1.0 else {
            throw CompressionError.invalidQuality
        }

        // Determine file type
        let fileType = try getFileType(for: inputURL)

        // Select appropriate strategy using cached map for O(1) lookup
        var strategy: CompressionStrategy?

        // Try direct lookup first
        if let directStrategy = strategyMap[fileType] {
            strategy = directStrategy
        } else {
            // Fallback: check if file type conforms to any supported type
            for (supportedType, candidateStrategy) in strategyMap {
                if fileType.conforms(to: supportedType) {
                    strategy = candidateStrategy
                    break
                }
            }
        }

        guard let selectedStrategy = strategy else {
            throw CompressionError.unsupportedFileType
        }

        // Generate output URL
        let outputURL = generateOutputURL(for: inputURL, in: outputFolder)

        // Execute compression
        return try await selectedStrategy.compress(
            inputURL: inputURL,
            outputURL: outputURL,
            quality: quality,
            targetFramerate: targetFramerate
        )
    }

    /// Get the file type of a URL
    private func getFileType(for url: URL) throws -> UTType {
        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
        guard let type = resourceValues.contentType else {
            throw CompressionError.unsupportedFileType
        }
        return type
    }

    /// Generate output URL for compressed file
    private func generateOutputURL(for inputURL: URL, in outputFolder: URL) -> URL {
        let filename = inputURL.deletingPathExtension().lastPathComponent
        let fileExtension = inputURL.pathExtension

        // Try base name first
        var outputURL = outputFolder
            .appendingPathComponent("\(filename).compressed")
            .appendingPathExtension(fileExtension)

        // If file exists, use more efficient algorithm
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            // Use timestamp-based suffix for uniqueness instead of sequential counter
            let timestamp = Int(Date().timeIntervalSince1970)
            outputURL = outputFolder
                .appendingPathComponent("\(filename).compressed.\(timestamp)")
                .appendingPathExtension(fileExtension)

            // Only in the rare case of collision, fall back to counter
            if fileManager.fileExists(atPath: outputURL.path) {
                var counter = 1
                repeat {
                    outputURL = outputFolder
                        .appendingPathComponent("\(filename).compressed.\(timestamp).\(counter)")
                        .appendingPathExtension(fileExtension)
                    counter += 1
                } while fileManager.fileExists(atPath: outputURL.path) && counter < 1000
            }
        }

        return outputURL
    }
}
