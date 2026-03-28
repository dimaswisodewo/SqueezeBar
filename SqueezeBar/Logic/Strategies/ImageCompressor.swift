//
//  ImageCompressor.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

class ImageCompressor: CompressionStrategy {
    var supportedTypes: [UTType] {
        [.jpeg, .png, .heic, .heif, .bmp, .tiff]
    }

    func compress(inputURL: URL, outputURL: URL, quality: Double, targetFramerate: Double? = nil) async throws -> CompressionResult {
        // Validate input file exists
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw CompressionError.fileNotFound
        }

        // Get original file size
        let originalSize = try getFileSize(at: inputURL)

        // Load image source
        guard let imageSource = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let imageType = CGImageSourceGetType(imageSource) else {
            throw CompressionError.compressionFailed("Could not load image")
        }

        // Determine output type and compression strategy
        let outputType = selectOutputType(for: imageType)
        let isLosslessSource = isLosslessFormat(imageType)

        // For lossless formats or if we need heavy compression, decode the image first
        let shouldDecodeImage = isLosslessSource || quality < 0.7

        if shouldDecodeImage {
            try compressWithDecoding(
                imageSource: imageSource,
                outputURL: outputURL,
                outputType: outputType,
                quality: quality
            )
        } else {
            try compressDirectly(
                imageSource: imageSource,
                outputURL: outputURL,
                outputType: outputType,
                quality: quality
            )
        }

        // Get compressed file size
        let compressedSize = try getFileSize(at: outputURL)

        // If compression didn't help, use the original file
        if compressedSize >= originalSize {
            try? FileManager.default.removeItem(at: outputURL)
            do {
                try FileManager.default.linkItem(at: inputURL, to: outputURL)
            } catch {
                try? FileManager.default.copyItem(at: inputURL, to: outputURL)
            }

            return CompressionResult(
                originalURL: inputURL,
                compressedURL: outputURL,
                originalSize: originalSize,
                compressedSize: originalSize
            )
        }

        return CompressionResult(
            originalURL: inputURL,
            compressedURL: outputURL,
            originalSize: originalSize,
            compressedSize: compressedSize
        )
    }

    /// Compress by directly adding from source (faster, but limited compression)
    private func compressDirectly(
        imageSource: CGImageSource,
        outputURL: URL,
        outputType: CFString,
        quality: Double
    ) throws {
        guard let imageDestination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            outputType,
            1,
            nil
        ) else {
            throw CompressionError.compressionFailed("Could not create output file")
        }

        // Compression options
        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        // Preserve orientation and color space
        if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
            if let orientation = properties[kCGImagePropertyOrientation] {
                options[kCGImagePropertyOrientation] = orientation
            }
        }

        CGImageDestinationAddImageFromSource(
            imageDestination,
            imageSource,
            0,
            options as CFDictionary
        )

        guard CGImageDestinationFinalize(imageDestination) else {
            throw CompressionError.compressionFailed("Could not save compressed image")
        }
    }

    /// Compress by decoding and re-encoding (slower, but better compression)
    private func compressWithDecoding(
        imageSource: CGImageSource,
        outputURL: URL,
        outputType: CFString,
        quality: Double
    ) throws {
        // Get original properties for metadata preservation
        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]

        // For large images (>30 megapixels), subsample during decode to avoid loading
        // hundreds of MB of raw bitmap into memory
        let pixelWidth = (properties?[kCGImagePropertyPixelWidth] as? Int) ?? 0
        let pixelHeight = (properties?[kCGImagePropertyPixelHeight] as? Int) ?? 0
        let totalPixels = pixelWidth * pixelHeight
        let largeMegapixelThreshold = 30_000_000

        let cgImage: CGImage?
        if totalPixels > largeMegapixelThreshold {
            // Use thumbnail decode to subsample at the ImageIO level — never materializes full bitmap
            let maxDimension = quality >= 0.7 ? 8192 : 4096
            let thumbnailOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions as CFDictionary)
        } else {
            cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        }

        guard let cgImage else {
            throw CompressionError.compressionFailed("Could not decode image")
        }

        // Create destination
        guard let imageDestination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            outputType,
            1,
            nil
        ) else {
            throw CompressionError.compressionFailed("Could not create output file")
        }

        // Prepare compression options
        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        // Preserve orientation
        if let props = properties, let orientation = props[kCGImagePropertyOrientation] {
            options[kCGImagePropertyOrientation] = orientation
        }

        // Add the decoded image with options
        CGImageDestinationAddImage(imageDestination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(imageDestination) else {
            throw CompressionError.compressionFailed("Could not save compressed image")
        }
    }

    /// Determine the best output type for compression
    private func selectOutputType(for inputType: CFString) -> CFString {
        let typeString = inputType as String

        // PNG, BMP, TIFF are lossless - convert to JPEG for compression
        if typeString.contains("png") ||
           typeString.contains("bmp") ||
           typeString.contains("tiff") {
            return UTType.jpeg.identifier as CFString
        }

        // HEIC/HEIF - keep as is (already efficient)
        if typeString.contains("heic") || typeString.contains("heif") {
            return inputType
        }

        // JPEG - keep as is
        if typeString.contains("jpeg") || typeString.contains("jpg") {
            return UTType.jpeg.identifier as CFString
        }

        // Default to JPEG for unknown types
        return UTType.jpeg.identifier as CFString
    }

    /// Check if the format is lossless
    private func isLosslessFormat(_ type: CFString) -> Bool {
        let typeString = type as String
        return typeString.contains("png") ||
               typeString.contains("bmp") ||
               typeString.contains("tiff")
    }

    private func getFileSize(at url: URL) throws -> Int64 {
        // Use resourceValues API which is more efficient than attributesOfItem
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }
}
