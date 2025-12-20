//
//  PDFCompressor.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation
import PDFKit
import UniformTypeIdentifiers
import Quartz
import CoreGraphics

class PDFCompressor: CompressionStrategy {
    var supportedTypes: [UTType] {
        [.pdf]
    }

    func compress(inputURL: URL, outputURL: URL, quality: Double, targetFramerate: Double? = nil) async throws -> CompressionResult {
        // Validate input file exists
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw CompressionError.fileNotFound
        }

        // Get original file size
        let originalSize = try getFileSize(at: inputURL)

        // Try compression using Quartz filters
        let success = try compressUsingQuartzFilter(inputURL: inputURL, outputURL: outputURL, quality: quality)

        guard success else {
            throw CompressionError.compressionFailed("Could not save compressed PDF")
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

    private func compressUsingQuartzFilter(inputURL: URL, outputURL: URL, quality: Double) throws -> Bool {
        // Try using command-line tools for better compression
        let success = compressUsingCommandLine(inputURL: inputURL, outputURL: outputURL, quality: quality)

        if success {
            return true
        }

        // Fallback to PDFKit with write options
        return compressUsingPDFKit(inputURL: inputURL, outputURL: outputURL, quality: quality)
    }

    private func compressUsingCommandLine(inputURL: URL, outputURL: URL, quality: Double) -> Bool {
        // Try Ghostscript (if installed) - most reliable compression
        let gsPath = findGhostscriptPath()
        logGhostscriptPath(gsPath)

        if let gsPath = gsPath {
            if compressUsingGhostscript(gsPath: gsPath, inputURL: inputURL, outputURL: outputURL, quality: quality) {
                return true
            }
        }

        return false
    }

    private func findGhostscriptPath() -> String? {
        // Priority 1: Check bundled Ghostscript first
        if let bundledPath = BundleResourceHelper.findBundledGhostscript() {
            // Ensure it has executable permissions
            _ = BundleResourceHelper.ensureExecutablePermissions(for: bundledPath)
            return bundledPath
        }

        // Priority 2: Fall back to system installations
        let possiblePaths = [
            "/usr/local/bin/gs",
            "/opt/homebrew/bin/gs",
            "/usr/bin/gs"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // No Ghostscript found
        return nil
    }

    private func logGhostscriptPath(_ path: String?) {
        #if DEBUG
        if let path = path {
            print("✓ Ghostscript found at: \(path)")

            // Verify it's executable
            if FileManager.default.isExecutableFile(atPath: path) {
                print("  - Binary is executable")
            } else {
                print("  - WARNING: Binary is NOT executable")
            }

            // Check if bundled or system
            if path.contains(Bundle.main.bundlePath) {
                print("  - Source: Bundled with app")
            } else {
                print("  - Source: System installation")
            }
        } else {
            print("✗ Ghostscript not found - will use PDFKit fallback")
        }
        #endif
    }

    private func compressUsingGhostscript(gsPath: String, inputURL: URL, outputURL: URL, quality: Double) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gsPath)

        // Determine compression settings based on quality
        let pdfSettings: String
        if quality >= 0.8 {
            pdfSettings = "/prepress"  // High quality
        } else if quality >= 0.5 {
            pdfSettings = "/ebook"     // Medium quality
        } else {
            pdfSettings = "/screen"    // Low quality, maximum compression
        }

        process.arguments = [
            "-sDEVICE=pdfwrite",
            "-dCompatibilityLevel=1.4",
            "-dPDFSETTINGS=\(pdfSettings)",
            "-dNOPAUSE",
            "-dQUIET",
            "-dBATCH",
            "-sOutputFile=\(outputURL.path)",
            inputURL.path
        ]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Check if compression actually reduced file size
                // Only get file size once for each file
                if let originalSize = try? getFileSize(at: inputURL),
                   let compressedSize = try? getFileSize(at: outputURL),
                   compressedSize >= originalSize {
                    // Compression didn't help, use a hard link or copy to save I/O
                    try? FileManager.default.removeItem(at: outputURL)
                    // Try hard link first (instant), fallback to copy
                    do {
                        try FileManager.default.linkItem(at: inputURL, to: outputURL)
                    } catch {
                        try? FileManager.default.copyItem(at: inputURL, to: outputURL)
                    }
                }
                return true
            }
        } catch {
            return false
        }

        return false
    }

    private func compressUsingPDFKit(inputURL: URL, outputURL: URL, quality: Double) -> Bool {
        // Load the PDF document
        guard let pdfDoc = PDFDocument(url: inputURL) else {
            return false
        }

        // PDFKit doesn't have built-in compression options
        // Just write the document as-is, which will at least normalize the PDF
        let success = pdfDoc.write(to: outputURL)

        if success {
            // Check if write actually reduced file size
            if let originalSize = try? getFileSize(at: inputURL),
               let compressedSize = try? getFileSize(at: outputURL),
               compressedSize >= originalSize {
                // Output didn't help, use hard link or copy
                try? FileManager.default.removeItem(at: outputURL)
                do {
                    try FileManager.default.linkItem(at: inputURL, to: outputURL)
                } catch {
                    try? FileManager.default.copyItem(at: inputURL, to: outputURL)
                }
            }
        }

        return success
    }

    private func getFileSize(at url: URL) throws -> Int64 {
        // Use resourceValues API which is more efficient than attributesOfItem
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }
}
