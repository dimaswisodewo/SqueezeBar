//
//  ToySlider.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 28/03/26.
//

import SwiftUI

/// A custom slider with a chunky rounded track and bouncy thumb.
/// Designed for the toy-like visual language of SqueezeBar.
struct ToySlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var trackColor: Color = DesignTokens.Candy.blue
    var isDisabled: Bool = false

    @State private var isDragging = false

    private let trackHeight: CGFloat = 8
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            let usableWidth = max(geometry.size.width - thumbSize, 1)
            let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbX = usableWidth * fraction

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: trackHeight)

                // Filled track
                Capsule()
                    .fill(isDisabled ? Color.secondary.opacity(0.3) : trackColor)
                    .frame(width: thumbX + thumbSize / 2, height: trackHeight)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(
                        color: Color.black.opacity(isDragging ? 0.2 : 0.12),
                        radius: isDragging ? 5 : 3,
                        y: isDragging ? 3 : 2
                    )
                    .overlay(
                        Circle()
                            .fill(isDisabled ? Color.secondary.opacity(0.4) : trackColor)
                            .frame(width: 14, height: 14)
                    )
                    .scaleEffect(isDragging ? 1.18 : 1.0)
                    .animation(AnimationConstants.microInteraction, value: isDragging)
                    .offset(x: thumbX)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard !isDisabled else { return }
                        if !isDragging {
                            isDragging = true
                            HapticManager.shared.light()
                        }
                        let rawFraction = Double((gesture.location.x - thumbSize / 2) / usableWidth)
                        let clamped = min(max(rawFraction, 0), 1)
                        let rawValue = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                        let stepped = (rawValue / step).rounded() * step
                        value = min(max(stepped, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .frame(height: thumbSize)
    }
}

#Preview {
    struct SliderPreview: View {
        @State private var val = 0.5
        var body: some View {
            VStack(spacing: 20) {
                ToySlider(value: $val, range: 0...1, step: 0.05)
                Text("\(Int(val * 100))%")
                ToySlider(value: .constant(0.6), range: 0...1, step: 0.1, isDisabled: true)
            }
            .padding(30)
            .frame(width: 360)
        }
    }
    return SliderPreview()
}
