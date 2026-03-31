//
//  ConversionTypes.swift
//  SqueezeBar
//

import UniformTypeIdentifiers
import AVFoundation

enum AppMode: String, CaseIterable, Identifiable, Hashable {
    case compress = "Compress"
    case convert  = "Convert"
    var id: String { rawValue }
}

enum ConversionCategory: String, CaseIterable, Identifiable, Hashable {
    case imageToImage = "Image Format"
    case imageToPDF   = "Image → PDF"
    case videoToVideo = "Video Format"
    case videoToAudio = "Extract Audio"
    case pdfProtect   = "Lock PDF"
    var id: String { rawValue }
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
