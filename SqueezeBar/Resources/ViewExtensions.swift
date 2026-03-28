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
    func hoverScale(_ scale: CGFloat = 1.02) -> some View {
        self.modifier(HoverScaleModifier(scale: scale))
    }

    // MARK: - Press Effects

    /// Adds press scale effect
    /// - Parameter scale: The scale to apply on press (default: 0.95)
    func pressScale(_ scale: CGFloat = 0.95) -> some View {
        self.modifier(PressScaleModifier(scale: scale))
    }

    // MARK: - Fade Effects

    /// Smoothly fades view in/out based on visibility
    /// - Parameter isVisible: Whether the view should be visible
    func smoothFade(isVisible: Bool) -> some View {
        self.opacity(isVisible ? 1.0 : 0.0)
            .animation(AnimationConstants.fadeInOut, value: isVisible)
    }

    // MARK: - Card Style

    /// Applies toy-card styling: background, rounded corners, shadow
    func toyCard() -> some View {
        self.modifier(ToyCardModifier())
    }

    // MARK: - Shake Effect

    /// Applies a horizontal shake animation triggered by a boolean binding
    func shake(trigger: Binding<Bool>) -> some View {
        self.modifier(ShakeEffect(trigger: trigger))
    }
}

// MARK: - View Modifiers

struct HoverScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(AnimationConstants.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct PressScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(AnimationConstants.microInteraction, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

struct ToyCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignTokens.Candy.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .shadow(
                color: DesignTokens.Shadow.toy.color,
                radius: DesignTokens.Shadow.toy.radius,
                x: DesignTokens.Shadow.toy.x,
                y: DesignTokens.Shadow.toy.y
            )
    }
}

struct ShakeEffect: ViewModifier {
    @Binding var trigger: Bool
    @State private var xOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: xOffset)
            .onChange(of: trigger) { newValue in
                guard newValue else { return }
                withAnimation(AnimationConstants.shake) { xOffset = -6 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AnimationConstants.shake) { xOffset = 6 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(AnimationConstants.shake) { xOffset = 0 }
                    trigger = false
                }
            }
    }
}

// MARK: - Custom Button Styles

/// A full-width pill-shaped button for the primary action
struct ToyButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .foregroundStyle(isEnabled ? Color.white : Color.secondary)
            .font(Font.system(size: 14, weight: .bold, design: .rounded))
            .background(isEnabled ? DesignTokens.Candy.blue : Color.secondary.opacity(0.15))
            .clipShape(Capsule())
            .shadow(
                color: isEnabled ? DesignTokens.Shadow.toy.color : .clear,
                radius: DesignTokens.Shadow.toy.radius,
                x: DesignTokens.Shadow.toy.x,
                y: DesignTokens.Shadow.toy.y
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AnimationConstants.microInteraction, value: configuration.isPressed)
    }
}
