//
//  ImageFormatConverter.swift
//  SqueezeBar
//

import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

class ImageFormatConverter: ConversionStrategy {
    var supportedInputTypes: [UTType] {
        [.jpeg, .png, .heic, .heif, .bmp, .tiff, .gif]
    }

    func convert(inputURL: URL, outputURL: URL, options: ConversionOptions) async throws -> ConversionResult {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw ConversionError.fileNotFound
        }

        guard let targetFormat = options.imageOutputFormat else {
            throw ConversionError.invalidOptions
        }

        guard let imageSource = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
            throw ConversionError.conversionFailed("Could not load image source")
        }

        let targetUTType = targetFormat.utType
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, targetUTType.identifier as CFString, 1, nil) else {
            throw ConversionError.conversionFailed("Could not create image destination")
        }

        var destinationOptions: [CFString: Any] = [:]
        if isLossyFormat(targetFormat) {
            destinationOptions[kCGImageDestinationLossyCompressionQuality] = options.imageQuality ?? 0.85
        }

        CGImageDestinationAddImageFromSource(destination, imageSource, 0, destinationOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed("Failed to write output image")
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

    private func isLossyFormat(_ format: ImageOutputFormat) -> Bool {
        format == .jpeg || format == .heic
    }
}
