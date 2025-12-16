//
//  CompressionResult.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation

struct CompressionResult: Sendable {
    let originalURL: URL
    let compressedURL: URL
    let originalSize: Int64
    let compressedSize: Int64

    var compressionRatio: Double {
        guard originalSize > 0 else { return 0 }
        return Double(compressedSize) / Double(originalSize)
    }

    var savedBytes: Int64 {
        return originalSize - compressedSize
    }

    var savedPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return (1.0 - compressionRatio) * 100
    }
}
