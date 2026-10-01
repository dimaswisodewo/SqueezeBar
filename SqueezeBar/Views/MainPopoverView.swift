import SwiftUI
import UniformTypeIdentifiers

private enum PopoverSection: Hashable {
    case header, workspace, footer
}

private struct PopoverHeightsKey: PreferenceKey {
    static var defaultValue: [PopoverSection: CGFloat] = [:]
    static func reduce(value: inout [PopoverSection: CGFloat], nextValue: () -> [PopoverSection: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct MainPopoverView: View {
    let onPreferredHeightChange: (CGFloat) -> CGFloat
    @ObservedObject private var viewModel = MainViewModel.shared
    @StateObject private var settings = AppSettings()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var dropTargeted = false
    @State private var draggedImage: URL?
    @State private var displayedHeight: CGFloat = 400

    init(onPreferredHeightChange: @escaping (CGFloat) -> CGFloat = { $0 }) {
        self.onPreferredHeightChange = onPreferredHeightChange
    }

    private let blue = Color(red: 0.24, green: 0.39, blue: 0.82)
    private let violet = Color(red: 0.47, green: 0.33, blue: 0.76)
    private var accent: LinearGradient {
        LinearGradient(colors: [blue, violet], startPoint: .leading, endPoint: .trailing)
    }
    private var surface: Color { Color(nsColor: .controlBackgroundColor) }
    var body: some View {
        VStack(spacing: 0) {
            header
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: PopoverHeightsKey.self, value: [.header: geometry.size.height])
                })
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let input = viewModel.selectedInput {
                        inputCard(input)
                        selectedDropArea
                        actionPicker
                        if !viewModel.isWorking { controls }
                    } else {
                        emptyState
                    }
                    if let error = viewModel.errorMessage { message(error, icon: "exclamationmark.circle.fill", color: .red) }
                    if viewModel.isWorking { workingState }
                    if viewModel.resultURL != nil { resultState }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: PopoverHeightsKey.self, value: [.workspace: geometry.size.height])
                })
            }
            Divider()
            VStack(spacing: 12) {
                saveFolder
                if viewModel.selectedInput != nil && !viewModel.isWorking {
                    Button { Task { await viewModel.process(settings: settings) } } label: {
                        Label(viewModel.selectedAction.rawValue, systemImage: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .foregroundStyle(.white)
                            .background(accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.selectedAction == .protectPDF && !settings.isPdfPasswordValid)
                    .opacity(viewModel.selectedAction == .protectPDF && !settings.isPdfPasswordValid ? 0.5 : 1)
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .padding(18)
            .background(surface)
            .background(GeometryReader { geometry in
                Color.clear.preference(key: PopoverHeightsKey.self, value: [.footer: geometry.size.height])
            })
        }
        .frame(width: 420, height: displayedHeight)
        .background {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.12, green: 0.15, blue: 0.25), Color(red: 0.18, green: 0.15, blue: 0.26)]
                    : [Color(red: 0.93, green: 0.96, blue: 1), Color(red: 0.95, green: 0.93, blue: 0.99)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            guard !viewModel.isWorking else { return false }
            return viewModel.handleMultiDrop(providers: providers)
        }
        .onPreferenceChange(PopoverHeightsKey.self) { heights in
            guard let header = heights[.header], let workspace = heights[.workspace],
                  let footer = heights[.footer] else { return }
            let height = onPreferredHeightChange(header + workspace + footer + 1)
            if abs(displayedHeight - height) > 1 { displayedHeight = height }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: viewModel.selectedInput)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: viewModel.isWorking)
    }

    private var header: some View {
        HStack {
            Image("SqueezeBar-macOS-Default").resizable().frame(width: 25, height: 25)
            Text("SqueezeBar").font(.system(size: 16, weight: .semibold))
            Spacer()
            if viewModel.selectedInput != nil {
                Button("Add a file") { viewModel.openFilePicker() }
                    .buttonStyle(.plain)
                    .foregroundStyle(blue)
                    .disabled(viewModel.isWorking)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(surface)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(accent)
            Text("Start with a file").font(.system(size: 20, weight: .semibold))
            Text("Drop an image, video, or PDF here. Select several images to create one PDF.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add a file") { viewModel.openFilePicker() }
                .buttonStyle(.borderedProminent)
                .tint(blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32).padding(.vertical, 34)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(dropTargeted ? blue : blue.opacity(0.16), lineWidth: dropTargeted ? 2 : 1))
    }

    private var selectedDropArea: some View {
        HStack(spacing: 9) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 15))
            Text(viewModel.isWorking
                 ? "Wait for the current job to finish"
                 : "Drop a file or images to replace selection")
                .font(.system(size: 12, weight: .medium))
            Spacer()
        }
        .foregroundStyle(viewModel.isWorking ? Color.secondary : blue)
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(dropTargeted && !viewModel.isWorking ? blue.opacity(0.12) : surface,
                    in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(dropTargeted && !viewModel.isWorking ? blue : blue.opacity(0.4),
                          style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        .accessibilityLabel(viewModel.isWorking
            ? "File drop unavailable while processing"
            : "Drop a file or images to replace selection")
    }

    private func inputCard(_ input: SelectedInput) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INPUT").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                Spacer()
                Button("Remove") { viewModel.removeAttachedFile() }
                    .buttonStyle(.plain).foregroundStyle(.secondary).disabled(viewModel.isWorking)
            }
            switch input {
            case .single(let url):
                Label(url.lastPathComponent, systemImage: "doc")
                    .font(.system(size: 13, weight: .medium)).lineLimit(2)
                if let type = viewModel.fileTypeHint, let size = viewModel.fileSizeString {
                    Text("\(type) · \(size)").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            case .images(let urls):
                Text("\(urls.count) images · drag to reorder pages")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                ForEach(Array(urls.enumerated()), id: \.element) { index, url in
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal").foregroundStyle(.secondary)
                        Text("\(index + 1).").monospacedDigit().foregroundStyle(.secondary)
                        Text(url.lastPathComponent).lineLimit(1)
                        Spacer()
                        Button { viewModel.moveImage(from: index, to: index - 1) } label: {
                            Image(systemName: "chevron.up")
                        }.disabled(index == 0 || viewModel.isWorking).accessibilityLabel("Move \(url.lastPathComponent) up")
                        Button { viewModel.moveImage(from: index, to: index + 1) } label: {
                            Image(systemName: "chevron.down")
                        }.disabled(index == urls.count - 1 || viewModel.isWorking).accessibilityLabel("Move \(url.lastPathComponent) down")
                    }
                    .font(.system(size: 12))
                    .padding(7)
                    .background(blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
                    .onDrag { draggedImage = url; return NSItemProvider(object: url.absoluteString as NSString) }
                    .onDrop(of: [UTType.utf8PlainText], isTargeted: nil) { _ in
                        if let source = draggedImage, let from = urls.firstIndex(of: source) {
                            viewModel.moveImage(from: from, to: index)
                        }
                        draggedImage = nil
                        return true
                    }
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var actionPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACTION").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
            ForEach(viewModel.availableActions) { action in
                Button { viewModel.selectedAction = action } label: {
                    HStack {
                        Text(action.rawValue)
                        Spacer()
                        if action == viewModel.selectedAction { Image(systemName: "checkmark.circle.fill") }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .foregroundStyle(action == viewModel.selectedAction ? blue : Color.primary)
                    .background(action == viewModel.selectedAction ? blue.opacity(0.12) : surface,
                                in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain).disabled(viewModel.isWorking)
            }
        }
    }

    @ViewBuilder private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.selectedAction {
            case .compress:
                Picker("Quality", selection: $settings.compressionQuality) {
                    ForEach(CompressionQuality.allCases) { Text($0.rawValue).tag($0) }
                }
                if settings.compressionQuality == .custom {
                    valueRow("Custom quality", "\(Int(settings.customQuality * 100))%")
                    Slider(value: $settings.customQuality, in: 0.1...1, step: 0.05)
                }
                if viewModel.isCurrentFileVideo {
                    Toggle("Reduce frame rate", isOn: $settings.enableFramerateReduction)
                        .onChange(of: settings.enableFramerateReduction) { enabled in
                            if enabled && settings.targetFramerate == nil { settings.targetFramerate = 30 }
                            settings.saveFramerateSettings()
                        }
                    if settings.enableFramerateReduction {
                        Picker("Target frame rate", selection: Binding(
                            get: { settings.targetFramerate ?? 30 },
                            set: { settings.targetFramerate = $0; settings.saveFramerateSettings() }
                        )) {
                            ForEach([15.0, 24.0, 30.0, 60.0], id: \.self) { Text("\(Int($0)) fps").tag($0) }
                        }
                    }
                }
            case .imageFormat:
                Picker("Output format", selection: $settings.imageOutputFormat) {
                    ForEach(ImageOutputFormat.allCases) { Text($0.displayName).tag($0) }
                }.onChange(of: settings.imageOutputFormat) { _ in settings.saveConversionSettings() }
                if settings.imageOutputFormat == .jpeg || settings.imageOutputFormat == .heic {
                    valueRow("Quality", "\(Int(settings.imageConversionQuality * 100))%")
                    Slider(value: $settings.imageConversionQuality, in: 0.1...1, step: 0.05)
                        .onChange(of: settings.imageConversionQuality) { _ in settings.saveConversionSettings() }
                }
            case .videoFormat:
                Picker("Output format", selection: $settings.videoOutputFormat) {
                    ForEach(VideoOutputFormat.allCases) { Text($0.displayName).tag($0) }
                }.onChange(of: settings.videoOutputFormat) { _ in settings.saveConversionSettings() }
            case .extractAudio:
                Text("Saves the audio track as M4A.").foregroundStyle(.secondary)
            case .createPDF:
                Text("Images become PDF pages in the order shown above.").foregroundStyle(.secondary)
            case .protectPDF:
                SecureField("Password", text: $settings.pdfPassword)
                SecureField("Confirm password", text: $settings.pdfPasswordConfirm)
                if !settings.pdfPassword.isEmpty && !settings.isPdfPasswordValid {
                    Text("Passwords do not match.").foregroundStyle(.red)
                }
            }
        }
        .font(.system(size: 12))
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var saveFolder: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder").foregroundStyle(blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("SAVE FOLDER").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                Text(settings.outputFolderURL?.lastPathComponent ?? "No folder selected")
                    .font(.system(size: 12)).lineLimit(1)
            }
            Spacer()
            Button(settings.outputFolderURL == nil ? "Choose save folder" : "Change") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.canCreateDirectories = true
                panel.prompt = "Choose"
                if panel.runModal() == .OK { settings.outputFolderURL = panel.url }
            }
            .buttonStyle(.plain).foregroundStyle(blue).disabled(viewModel.isWorking)
        }
    }

    private var workingState: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text(viewModel.statusMessage.isEmpty ? "Working…" : viewModel.statusMessage)
                .font(.system(size: 12))
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var resultState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(.green)
            if let url = viewModel.resultURL {
                Text(url.lastPathComponent).font(.system(size: 12, weight: .medium)).lineLimit(2)
            }
            Text(viewModel.statusMessage).font(.system(size: 11)).foregroundStyle(.secondary)
            HStack {
                Button("Show in Finder") { viewModel.showResultInFinder() }
                Button("Dismiss") { viewModel.dismissResult() }
            }
            .buttonStyle(.borderless).foregroundStyle(blue)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private func message(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12)).foregroundStyle(color)
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(surface, in: RoundedRectangle(cornerRadius: 10))
    }

    private func valueRow(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value).foregroundStyle(.secondary) }
    }
}
