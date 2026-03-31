//
//  ConversionStrategy.swift
//  SqueezeBar
//

import Foundation
import UniformTypeIdentifiers

struct ConversionOptions {
    var imageOutputFormat: ImageOutputFormat?
    var imageQuality: Double?         // 0.0–1.0 for lossy formats
    var videoOutputFormat: VideoOutputFormat?
    var pdfPassword: String?
    // imageToPDF: input URL list passed separately to ConversionManager
}

protocol ConversionStrategy {
    var supportedInputTypes: [UTType] { get }
    func convert(inputURL: URL, outputURL: URL, options: ConversionOptions) async throws -> ConversionResult
}

enum ConversionError: LocalizedError {
    case unsupportedFileType
    case fileNotFound
    case conversionFailed(String)
    case outputFolderNotSet
    case invalidOptions
    case passwordMismatch

    var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "File type not supported for conversion"
        case .fileNotFound:
            return "Input file not found"
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        case .outputFolderNotSet:
            return "Output folder not configured. Please select an output folder in settings."
        case .invalidOptions:
            return "Invalid conversion options"
        case .passwordMismatch:
            return "Passwords do not match"
        }
    }
}
