//
//  DesignTokens.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 16/12/25.
//

import SwiftUI

enum DesignTokens {
    // MARK: - Colors

    /// Primary accent color from system
    static let primaryAccent = Color.accentColor

    /// Modern success green
    static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.35)

    /// Modern error red
    static let errorRed = Color(red: 0.96, green: 0.26, blue: 0.21)

    /// Warning orange
    static let warningOrange = Color(red: 1.0, green: 0.58, blue: 0.0)

    // MARK: - Background Colors

    /// Drop zone idle background
    static let dropZoneIdle = Color.secondary.opacity(0.05)

    /// Drop zone when dragging
    static let dropZoneDragging = Color.accentColor.opacity(0.08)

    /// Drop zone on success
    static let dropZoneSuccess = Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.08)

    /// Card/panel background
    static let cardBackground = Color(NSColor.controlBackgroundColor)

    // MARK: - Shadows

    enum Shadow {
        /// Subtle shadow for depth
        static let subtle = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))

        /// Elevated shadow for dragging state
        static let elevated = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))

        /// Accent glow for active state
        static let accentGlow = (color: Color.accentColor.opacity(0.3), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))

        /// Green glow for success
        static let successGlow = (color: Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.3), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))

        /// Button hover shadow
        static let buttonHover = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))

        /// Message shadow
        static let message = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
    }
}
