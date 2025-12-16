//
//  CompressionStrategy.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation
import UniformTypeIdentifiers

/// Protocol defining the compression strategy interface
protocol CompressionStrategy {
    /// The file types supported by this compressor
    var supportedTypes: [UTType] { get }

    /// Compresses a file from input URL to output URL with the specified quality
    /// - Parameters:
    ///   - inputURL: The URL of the file to compress
    ///   - outputURL: The URL where the compressed file should be saved
    ///   - quality: Quality factor between 0.0 (lowest) and 1.0 (highest)
    /// - Returns: CompressionResult containing details about the compression
    /// - Throws: CompressionError if compression fails
    func compress(inputURL: URL, outputURL: URL, quality: Double) async throws -> CompressionResult
}

/// Errors that can occur during compression
enum CompressionError: LocalizedError {
    case unsupportedFileType
    case fileNotFound
    case compressionFailed(String)
    case outputFolderNotSet
    case invalidQuality

    var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "File type not supported for compression"
        case .fileNotFound:
            return "Input file not found"
        case .compressionFailed(let message):
            return "Compression failed: \(message)"
        case .outputFolderNotSet:
            return "Output folder not configured. Please select an output folder in settings."
        case .invalidQuality:
            return "Invalid quality setting"
        }
    }
}
