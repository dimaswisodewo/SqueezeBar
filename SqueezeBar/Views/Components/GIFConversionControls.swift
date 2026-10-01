import SwiftUI

struct GIFConversionControls: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var viewModel = MainViewModel.shared

    private var effectiveFPS: Double {
        min(settings.gifFramerate, viewModel.videoSourceFramerate ?? settings.gifFramerate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            BrutalistSectionLabel(title: "Resolution")
            BrutalistChoicePicker(
                selection: $settings.gifResolution,
                options: GIFResolution.allCases,
                label: { $0.displayName },
                isDisabled: viewModel.isWorking
            )
            .onChange(of: settings.gifResolution) { _ in settings.saveConversionSettings() }

            BrutalistSectionLabel(title: "Frames per second")
            HStack {
                Text("GIF frame rate")
                Spacer()
                Text("\(Int(settings.gifFramerate)) FPS")
                    .font(DesignTokens.Typography.metadata)
            }
            BrutalistSlider(value: $settings.gifFramerate, range: 1...30, step: 1,
                            isDisabled: viewModel.isWorking, title: "GIF frame rate",
                            accessibilityValueDescription: "\(Int(settings.gifFramerate)) frames per second")
                .frame(height: 32)
                .onChange(of: settings.gifFramerate) { _ in settings.saveConversionSettings() }
            if effectiveFPS < settings.gifFramerate {
                Text("Effective frame rate: \(effectiveFPS, specifier: "%.2f") FPS (source limit)")
            }
            if viewModel.isLoadingVideoMetadata {
                Text("Checking video duration…")
            } else if let error = viewModel.gifDurationError {
                Text(error)
            } else if let duration = viewModel.videoDuration {
                Text("Duration: \(duration, specifier: "%.2f") seconds · Maximum: 30 seconds")
            }
            if settings.gifResolution == .original {
                Text("Loops forever · Original resolution · No audio")
                Text("Original resolution uses more memory and may produce larger GIFs.")
            } else {
                Text("Loops forever · Up to \(settings.gifResolution.rawValue) pixels on the longest edge · No audio")
            }
        }
        .font(DesignTokens.Typography.caption)
    }
}
