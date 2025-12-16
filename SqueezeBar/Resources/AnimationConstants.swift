//
//  AnimationConstants.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 16/12/25.
//

import SwiftUI

enum AnimationConstants {
    // MARK: - Spring Animations

    /// Natural state transition with smooth spring effect
    /// Use for: Icon changes, color transitions, view state changes
    static let stateTransition = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Gentle spring for layout changes
    /// Use for: View appearance/disappearance, size changes
    static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Bouncy spring for micro-interactions
    /// Use for: Button presses, slider interactions
    static let microInteraction = Animation.spring(response: 0.2, dampingFraction: 0.6)

    /// Celebration spring with more bounce
    /// Use for: Success states, file drop completion
    static let celebration = Animation.spring(response: 0.5, dampingFraction: 0.6)

    // MARK: - Easing Animations

    /// Smooth fade in/out
    /// Use for: Opacity changes, subtle transitions
    static let fadeInOut = Animation.easeInOut(duration: 0.2)

    /// Quick easing for instant feedback
    /// Use for: Hover states, quick state changes
    static let quick = Animation.easeOut(duration: 0.15)

    /// Medium-paced easing
    /// Use for: Background color changes, border transitions
    static let medium = Animation.easeInOut(duration: 0.25)

    // MARK: - Accessibility Support

    /// Returns animation that respects reduced motion settings
    /// - Parameter animation: The animation to apply (if motion is allowed)
    /// - Returns: Either the original animation or a minimal linear animation
    static func respectingMotion(_ animation: Animation) -> Animation {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .linear(duration: 0.1)
        }
        return animation
    }
}
