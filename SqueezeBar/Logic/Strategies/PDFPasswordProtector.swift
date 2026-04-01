//
//  PDFPasswordProtector.swift
//  SqueezeBar
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

class PDFPasswordProtector: ConversionStrategy {
    var supportedInputTypes: [UTType] { [.pdf] }

    func convert(inputURL: URL, outputURL: URL, options: ConversionOptions) async throws -> ConversionResult {
        guard let password = options.pdfPassword, !password.isEmpty else {
            throw ConversionError.invalidOptions
        }

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw ConversionError.fileNotFound
        }

        guard let pdfDocument = PDFDocument(url: inputURL) else {
            throw ConversionError.conversionFailed("Could not load PDF document")
        }

        let writeOptions: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ]

        guard pdfDocument.write(to: outputURL, withOptions: writeOptions) else {
            throw ConversionError.conversionFailed("Failed to write password-protected PDF")
        }

        let outputSize = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0

        return ConversionResult(
            inputURL: inputURL,
            outputURL: outputURL,
            inputFormat: "PDF",
            outputFormat: "PDF (Protected)",
            outputSize: outputSize
        )
    }
}
