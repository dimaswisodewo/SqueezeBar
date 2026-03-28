//
//  DesignTokens.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 16/12/25.
//

import SwiftUI

enum DesignTokens {
    // MARK: - Candy Colors

    enum Candy {
        /// Primary blue — buttons, active states
        static let blue = Color(red: 0.29, green: 0.565, blue: 0.969)      // #4A90F7
        /// Pink — drag hover state
        static let pink = Color(red: 1.0, green: 0.42, blue: 0.616)        // #FF6B9D
        /// Mint — success states
        static let mint = Color(red: 0.212, green: 0.827, blue: 0.6)       // #36D399
        /// Peach — warnings
        static let peach = Color(red: 1.0, green: 0.541, blue: 0.396)      // #FF8A65
        /// Coral — errors
        static let coral = Color(red: 1.0, green: 0.322, blue: 0.322)      // #FF5252
        /// Lavender — section headers
        static let lavender = Color(red: 0.702, green: 0.616, blue: 0.859) // #B39DDB
        /// Lemon — celebration accents
        static let lemon = Color(red: 1.0, green: 0.835, blue: 0.31)       // #FFD54F

        static let bgCard = Color(NSColor.controlBackgroundColor)
    }

    // MARK: - Legacy aliases

    static let primaryAccent = Candy.blue
    static let successGreen = Candy.mint
    static let errorRed = Candy.coral
    static let warningOrange = Candy.peach
    static let dropZoneIdle = Candy.blue.opacity(0.05)
    static let dropZoneDragging = Candy.pink.opacity(0.1)
    static let dropZoneSuccess = Candy.mint.opacity(0.08)
    static let cardBackground = Color(NSColor.controlBackgroundColor)

    // MARK: - Typography

    enum Typography {
        static let title   = Font.system(size: 16, weight: .bold,     design: .rounded)
        static let heading = Font.system(size: 13, weight: .semibold,  design: .rounded)
        static let body    = Font.system(size: 12, weight: .medium,    design: .rounded)
        static let caption = Font.system(size: 11, weight: .regular,   design: .rounded)
        static let tiny    = Font.system(size: 10, weight: .medium,    design: .rounded)
    }

    // MARK: - Shadows

    enum Shadow {
        static let toy        = (color: Color.black.opacity(0.08), radius: CGFloat(3), x: CGFloat(0), y: CGFloat(2))
        static let toyLifted  = (color: Color.black.opacity(0.12), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(3))
        static let glow       = (color: Candy.blue.opacity(0.25),  radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let successGlow = (color: Candy.mint.opacity(0.25), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(1))

        // Legacy aliases
        static let subtle      = toy
        static let elevated    = toyLifted
        static let accentGlow  = glow
        static let buttonHover = toyLifted
        static let message     = toy
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
        static let small:  CGFloat = 10
        static let medium: CGFloat = 14
        static let large:  CGFloat = 20
        static let pill:   CGFloat = 50
    }
}
