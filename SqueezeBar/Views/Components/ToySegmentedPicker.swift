//
//  ToySegmentedPicker.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 28/03/26.
//

import SwiftUI

/// A playful segmented picker with a sliding pill indicator.
struct ToySegmentedPicker<T: Hashable & Identifiable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String
    var isDisabled: Bool = false

    @Namespace private var pickerAnimation

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.id) { option in
                let isSelected = selection.id == option.id

                Button {
                    guard !isDisabled else { return }
                    withAnimation(AnimationConstants.stateTransition) {
                        selection = option
                    }
                    HapticManager.shared.light()
                } label: {
                    Text(label(option))
                        .font(DesignTokens.Typography.tiny)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(isSelected ? .white : Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(DesignTokens.Candy.blue)
                                    .matchedGeometryEffect(id: "indicator", in: pickerAnimation)
                                    .shadow(
                                        color: DesignTokens.Candy.blue.opacity(0.3),
                                        radius: 4, y: 1
                                    )
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

#Preview {
    struct PickerPreview: View {
        @State private var mode = CompressionMode.quality
        @State private var quality = CompressionQuality.medium

        var body: some View {
            VStack(spacing: 20) {
                ToySegmentedPicker(
                    selection: $mode,
                    options: CompressionMode.allCases.map { $0 },
                    label: { $0.rawValue }
                )
                ToySegmentedPicker(
                    selection: $quality,
                    options: CompressionQuality.allCases.map { $0 },
                    label: { $0.rawValue }
                )
            }
            .padding(24)
            .frame(width: 370)
        }
    }
    return PickerPreview()
}
