//
//  HapticManager.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 16/12/25.
//

import AppKit

/// Manages haptic feedback for the application
class HapticManager {
    static let shared = HapticManager()
    private let performer = NSHapticFeedbackManager.defaultPerformer

    private init() {}

    /// Light haptic feedback for subtle interactions
    /// Use for: Button hovers, slider interactions
    func light() {
        performer.perform(.alignment, performanceTime: .now)
    }

    /// Medium haptic feedback for standard interactions
    /// Use for: Button presses, file drops
    func medium() {
        performer.perform(.generic, performanceTime: .now)
    }

    /// Success haptic feedback for positive outcomes
    /// Use for: Compression success, file drop completion
    func success() {
        performer.perform(.levelChange, performanceTime: .now)
    }
}
