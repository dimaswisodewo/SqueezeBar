//
//  ImageToPDFConverter.swift
//  SqueezeBar
//

import Foundation
import CoreGraphics
import ImageIO

class ImageToPDFConverter {
    // A4 page dimensions in PDF points (72 dpi)
    private let a4Width: CGFloat = 595
    private let a4Height: CGFloat = 842

    func convert(inputURLs: [URL], outputURL: URL) throws -> ConversionResult {
        guard !inputURLs.isEmpty else {
            throw ConversionError.invalidOptions
        }

        var mediaBox = CGRect(x: 0, y: 0, width: a4Width, height: a4Height)

        guard let context = CGContext(outputURL as CFURL, mediaBox: &mediaBox, nil) else {
            throw ConversionError.conversionFailed("Could not create PDF context")
        }

        for inputURL in inputURLs {
            guard let imageSource = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                continue
            }

            let imageWidth = CGFloat(cgImage.width)
            let imageHeight = CGFloat(cgImage.height)

            // Fit image into A4, maintaining aspect ratio
            let drawRect = rectForImage(width: imageWidth, height: imageHeight)

            context.beginPDFPage(nil)
            // CoreGraphics PDF origin is bottom-left; draw the image into the calculated rect
            context.draw(cgImage, in: drawRect)
            context.endPDFPage()
        }

        context.closePDF()

        let outputSize = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0

        return ConversionResult(
            inputURL: inputURLs[0],
            outputURL: outputURL,
            inputFormat: "Images",
            outputFormat: "PDF",
            outputSize: outputSize
        )
    }

    // Returns the draw rect centered on an A4 page, fitting within A4 if larger
    private func rectForImage(width: CGFloat, height: CGFloat) -> CGRect {
        let drawWidth: CGFloat
        let drawHeight: CGFloat

        if width <= a4Width && height <= a4Height {
            // Native size — fits within A4
            drawWidth = width
            drawHeight = height
        } else {
            // Scale down to fit, maintaining aspect ratio
            let widthRatio = a4Width / width
            let heightRatio = a4Height / height
            let scale = min(widthRatio, heightRatio)
            drawWidth = width * scale
            drawHeight = height * scale
        }

        let x = (a4Width - drawWidth) / 2
        let y = (a4Height - drawHeight) / 2
        return CGRect(x: x, y: y, width: drawWidth, height: drawHeight)
    }
}
