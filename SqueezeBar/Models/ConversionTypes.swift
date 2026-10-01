//
//  ConversionTypes.swift
//  SqueezeBar
//

import UniformTypeIdentifiers
import AVFoundation

enum FileAction: String, CaseIterable, Identifiable {
    case compress = "Compress"
    case imageFormat = "Convert image"
    case createPDF = "Create PDF"
    case videoFormat = "Convert video"
    case extractAudio = "Extract audio"
    case createGIF = "Create GIF"
    case protectPDF = "Protect PDF"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compress: return "Compress"
        case .imageFormat: return "Change image format"
        case .videoFormat: return "Change video format"
        case .extractAudio: return "Save audio"
        case .createGIF: return "Create GIF"
        case .createPDF: return "Create PDF"
        case .protectPDF: return "Add password"
        }
    }

    var conversionCategory: ConversionCategory? {
        switch self {
        case .compress: return nil
        case .imageFormat: return .imageToImage
        case .createPDF: return .imageToPDF
        case .videoFormat: return .videoToVideo
        case .extractAudio: return .videoToAudio
        case .createGIF: return .videoToGIF
        case .protectPDF: return .pdfProtect
        }
    }
}

enum SelectedInput: Equatable {
    case single(URL)
    case images([URL])

    var urls: [URL] {
        switch self {
        case .single(let url): return [url]
        case .images(let urls): return urls
        }
    }
}

enum AppMode: String, CaseIterable, Identifiable, Hashable {
    case compress = "Compress"
    case convert  = "Convert"
    var id: String { rawValue }
}

enum ConversionCategory: String, CaseIterable, Identifiable, Hashable {
    case imageToImage = "Image Format"
    case imageToPDF   = "Image → PDF"
    case videoToVideo = "Video Format"
    case videoToGIF = "Video → GIF"
    case videoToAudio = "Extract Audio"
    case pdfProtect   = "Lock PDF"
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .imageToImage: return "Change image format"
        case .imageToPDF: return "Create PDF"
        case .videoToVideo: return "Change video format"
        case .videoToAudio: return "Save audio"
        case .videoToGIF: return "Create GIF"
        case .pdfProtect: return "Add password"
        }
    }
}

enum GIFResolution: String, CaseIterable, Identifiable, Hashable {
    case pixels320 = "320"
    case pixels640 = "640"
    case pixels960 = "960"
    case original

    var id: String { rawValue }

    var maximumEdge: Double? {
        switch self {
        case .pixels320: return 320
        case .pixels640: return 640
        case .pixels960: return 960
        case .original: return nil
        }
    }

    var displayName: String {
        self == .original ? "Original" : "\(rawValue) px"
    }
}

enum ImageOutputFormat: String, CaseIterable, Identifiable, Hashable {
    case jpeg, png, heic, tiff, bmp, gif
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jpeg: return "JPEG"
        case .png:  return "PNG"
        case .heic: return "HEIC"
        case .tiff: return "TIFF"
        case .bmp:  return "BMP"
        case .gif:  return "GIF"
        }
    }

    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png:  return .png
        case .heic: return .heic
        case .tiff: return .tiff
        case .bmp:  return .bmp
        case .gif:  return .gif
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png:  return "png"
        case .heic: return "heic"
        case .tiff: return "tiff"
        case .bmp:  return "bmp"
        case .gif:  return "gif"
        }
    }
}

enum VideoOutputFormat: String, CaseIterable, Identifiable, Hashable {
    case mp4, mov, m4v
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mp4: return "MP4"
        case .mov: return "MOV"
        case .m4v: return "M4V"
        }
    }

    var fileExtension: String {
        switch self {
        case .mp4: return "mp4"
        case .mov: return "mov"
        case .m4v: return "m4v"
        }
    }

    var avFileType: AVFileType {
        switch self {
        case .mp4: return .mp4
        case .mov: return .mov
        case .m4v: return .m4v
        }
    }
}
