//
//  CompressionLevel.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation

enum CompressionMode: String, CaseIterable, Identifiable {
    case quality = "Quality"
    case targetSize = "Target Size"
    case percentage = "Percentage"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .quality:
            return "Control output quality"
        case .targetSize:
            return "Set maximum file size"
        case .percentage:
            return "Reduce by percentage"
        }
    }
}

enum CompressionQuality: String, CaseIterable, Identifiable {
    case maximum = "Maximum"
    case high = "High"
    case medium = "Balanced"
    case low = "Small File"
    case custom = "Custom"

    var id: String { rawValue }

    /// Quality factor for compression (0.0 to 1.0)
    var qualityFactor: Double {
        switch self {
        case .maximum:
            return 0.95
        case .high:
            return 0.8
        case .medium:
            return 0.6
        case .low:
            return 0.3
        case .custom:
            return 0.5 // Default, will be overridden
        }
    }

    var hint: String {
        switch self {
        case .maximum:
            return "Best quality, larger file"
        case .high:
            return "Great quality, good size"
        case .medium:
            return "Good balance"
        case .low:
            return "Smallest file, lower quality"
        case .custom:
            return "Set your own quality"
        }
    }
}
