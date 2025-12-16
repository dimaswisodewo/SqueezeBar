//
//  ViewExtensions.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 16/12/25.
//

import SwiftUI

extension View {
    // MARK: - Hover Effects

    /// Adds subtle hover scale effect
    /// - Parameter scale: The scale to apply on hover (default: 1.02)
    /// - Returns: View with hover scale effect
    func hoverScale(_ scale: CGFloat = 1.02) -> some View {
        self.modifier(HoverScaleModifier(scale: scale))
    }

    // MARK: - Press Effects

    /// Adds press scale effect
    /// - Parameter scale: The scale to apply on press (default: 0.95)
    /// - Returns: View with press scale effect
    func pressScale(_ scale: CGFloat = 0.95) -> some View {
        self.modifier(PressScaleModifier(scale: scale))
    }

    // MARK: - Fade Effects

    /// Smoothly fades view in/out based on visibility
    /// - Parameter isVisible: Whether the view should be visible
    /// - Returns: View with smooth fade animation
    func smoothFade(isVisible: Bool) -> some View {
        self.opacity(isVisible ? 1.0 : 0.0)
            .animation(AnimationConstants.fadeInOut, value: isVisible)
    }
}

// MARK: - View Modifiers

struct HoverScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .onHover { hovering in
                withAnimation(AnimationConstants.quick) {
                    isHovered = hovering
                }
            }
    }
}

struct PressScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            withAnimation(AnimationConstants.microInteraction) {
                                isPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(AnimationConstants.microInteraction) {
                            isPressed = false
                        }
                    }
            )
    }
}
