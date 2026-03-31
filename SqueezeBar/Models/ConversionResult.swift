//
//  ConversionResult.swift
//  SqueezeBar
//

import Foundation

struct ConversionResult: Sendable {
    let inputURL: URL
    let outputURL: URL
    let inputFormat: String
    let outputFormat: String
    let outputSize: Int64
}
