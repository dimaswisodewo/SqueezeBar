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
    @Environment(\.colorScheme) private var colorScheme
    @State private var dropTargeted = false
    @State private var draggedImage: URL?
    @State private var displayedHeight: CGFloat = 400

    init(onPreferredHeightChange: @escaping (CGFloat) -> CGFloat = { $0 }) {
        self.onPreferredHeightChange = onPreferredHeightChange
    }

    private var palette: DesignTokens.Palette { DesignTokens.Palette(colorScheme) }
    private var isDropHighlighted: Bool { (dropTargeted || viewModel.isDragging) && !viewModel.isWorking }
    private var isActionDisabled: Bool {
        (viewModel.selectedAction == .protectPDF && !settings.isPdfPasswordValid)
            || (viewModel.selectedAction == .createGIF
                && (viewModel.isLoadingVideoMetadata || viewModel.gifDurationError != nil))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .background(heightReader(.header))
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
                    if let error = viewModel.errorMessage {
                        BrutalistStatusPanel(title: "Couldn't finish", message: error,
                                             symbol: "exclamationmark.circle", tone: .error)
                    }
                    if viewModel.isWorking { workingState }
                    if viewModel.resultURL != nil { resultState }
                }
                .padding(DesignTokens.Spacing.outer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(heightReader(.workspace))
            }
            Rectangle().fill(palette.outline).frame(height: DesignTokens.Geometry.border)
            VStack(spacing: 16) {
                saveFolder
                if viewModel.selectedInput != nil && !viewModel.isWorking {
                    BrutalistPrimaryButton(title: viewModel.selectedAction.displayName,
                                           isDisabled: isActionDisabled) {
                        Task { await viewModel.process(settings: settings) }
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .padding(DesignTokens.Spacing.outer)
            .background(palette.surface)
            .background(heightReader(.footer))
        }
        .frame(width: DesignTokens.Geometry.popoverWidth, height: displayedHeight)
        .foregroundStyle(palette.ink)
        .background(palette.canvas)
        .font(DesignTokens.Typography.body)
        .tint(palette.accent)
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            guard !viewModel.isWorking else { return false }
            return viewModel.handleMultiDrop(providers: providers)
        }
        .onPreferenceChange(PopoverHeightsKey.self) { heights in
            guard let header = heights[.header], let workspace = heights[.workspace],
                  let footer = heights[.footer] else { return }
            let height = onPreferredHeightChange(header + workspace + footer + DesignTokens.Geometry.border)
            if abs(displayedHeight - height) > 1 { displayedHeight = height }
        }
    }

    private func heightReader(_ section: PopoverSection) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(key: PopoverHeightsKey.self, value: [section: geometry.size.height])
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            BrutalistMark()
            VStack(alignment: .leading, spacing: 2) {
                Text("SqueezeBar").font(DesignTokens.Typography.title).tracking(-0.6)
            }
            Spacer()
            if viewModel.selectedInput != nil {
                Button { viewModel.openFilePicker() } label: {
                    Image(systemName: "plus").resizable().scaledToFit().frame(width: 13, height: 13)
                        .frame(width: 32, height: 32)
                        .background(palette.inset, in: Rectangle())
                }
                .buttonStyle(BrutalistButtonStyle())
                .accessibilityLabel("Add a file")
                .help("Choose a file or images to replace the selection")
                .disabled(viewModel.isWorking)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.outer)
        .padding(.vertical, 16)
        .background(palette.surface)
        .overlay(alignment: .bottom) { Rectangle().fill(palette.outline).frame(height: DesignTokens.Geometry.border) }
    }

    private var emptyState: some View {
        BrutalistDropSurface(isHighlighted: isDropHighlighted) {
            VStack(spacing: 0) {
                Image(systemName: "arrow.down.document")
                    .resizable().scaledToFit().frame(width: 30, height: 30)
                    .foregroundStyle(palette.ink)
                    .frame(width: 64, height: 64)
                    .background(palette.inset)
                    .overlay(Rectangle().strokeBorder(palette.outline, lineWidth: DesignTokens.Geometry.border))
                    .accessibilityHidden(true)
                    .padding(.bottom, 20)
                Text(isDropHighlighted ? "Drop files here" : "Start with a file")
                    .font(DesignTokens.Typography.hero).tracking(-0.8).multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                HStack(spacing: 8) {
                    BrutalistBadge(title: "IMG")
                    BrutalistBadge(title: "VIDEO")
                    BrutalistBadge(title: "PDF")
                }
                .padding(.bottom, 16)
                Text("Drop an image, video, or PDF.\nSelect several images to create one PDF.")
                    .font(DesignTokens.Typography.body).foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center).lineSpacing(4)
                    .padding(.bottom, 24)
                BrutalistPrimaryButton(title: "Choose a file", isDisabled: false) {
                    viewModel.openFilePicker()
                }
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                    Text("Your files stay on your Mac")
                }
                .font(DesignTokens.Typography.caption).foregroundStyle(palette.muted)
                .padding(.top, 16)
            }
            .padding(.horizontal, 24).padding(.vertical, 28)
        }
    }

    private var selectedDropArea: some View {
        BrutalistDropSurface(isHighlighted: isDropHighlighted) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.to.line")
                Text(viewModel.isWorking ? "File selection is paused while working" : "Drop a file or images to replace")
                    .font(DesignTokens.Typography.heading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(palette.muted)
            .padding(.horizontal, 12).padding(.vertical, 12)
        }
        .accessibilityLabel(viewModel.isWorking
            ? "File drop unavailable while processing"
            : "Drop a file or images to replace selection")
    }

    private func inputCard(_ input: SelectedInput) -> some View {
        BrutalistPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    BrutalistSectionLabel(title: "Source")
                    Spacer()
                    Button("Remove") { viewModel.removeAttachedFile() }
                        .font(DesignTokens.Typography.heading)
                        .foregroundStyle(palette.muted)
                        .buttonStyle(BrutalistQuietButtonStyle())
                        .disabled(viewModel.isWorking)
                }
                switch input {
                case .single(let url):
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: sourceSymbol(for: url))
                            .resizable().scaledToFit().frame(width: 21, height: 21)
                            .foregroundStyle(palette.ink)
                            .frame(width: 44, height: 48)
                            .background(palette.inset, in: Rectangle())
                        VStack(alignment: .leading, spacing: 6) {
                            Text(url.lastPathComponent)
                                .font(DesignTokens.Typography.heading)
                                .lineLimit(2).truncationMode(.middle)
                            if let type = viewModel.fileTypeHint, let size = viewModel.fileSizeString {
                                Text("\(type)  ·  \(size)")
                                    .font(DesignTokens.Typography.metadata).foregroundStyle(palette.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                case .images(let urls):
                    Text("\(urls.count) images · drag to reorder pages")
                        .font(DesignTokens.Typography.caption).foregroundStyle(palette.muted)
                    VStack(spacing: 5) {
                        ForEach(Array(urls.enumerated()), id: \.element) { index, url in
                            imageRow(url, index: index, count: urls.count)
                                .onDrag {
                                    guard !viewModel.isWorking else { return NSItemProvider() }
                                    draggedImage = url
                                    return NSItemProvider(object: url.absoluteString as NSString)
                                }
                                .onDrop(of: [UTType.utf8PlainText], isTargeted: nil) { _ in
                                    guard !viewModel.isWorking else { return false }
                                    if let source = draggedImage, let from = urls.firstIndex(of: source) {
                                        viewModel.moveImage(from: from, to: index)
                                    }
                                    draggedImage = nil
                                    return true
                                }
                        }
                    }
                }
            }
        }
    }

    private func imageRow(_ url: URL, index: Int, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(String(format: "%02d", index + 1))
                .font(DesignTokens.Typography.metadata)
                .foregroundStyle(palette.ink).frame(width: 22)
            Text(url.lastPathComponent).lineLimit(1).truncationMode(.middle)
            Spacer(minLength: 0)
            Button { viewModel.moveImage(from: index, to: index - 1) } label: {
                Image(systemName: "chevron.up").frame(width: 22, height: 26)
            }
            .disabled(index == 0 || viewModel.isWorking)
            .accessibilityLabel("Move \(url.lastPathComponent) up")
            Button { viewModel.moveImage(from: index, to: index + 1) } label: {
                Image(systemName: "chevron.down").frame(width: 22, height: 26)
            }
            .disabled(index == count - 1 || viewModel.isWorking)
            .accessibilityLabel("Move \(url.lastPathComponent) down")
        }
        .font(DesignTokens.Typography.caption).buttonStyle(BrutalistQuietButtonStyle())
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(palette.inset, in: Rectangle())
    }

    private var actionPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrutalistSectionLabel(title: "What would you like to do?")
            ForEach(viewModel.availableActions) { action in
                BrutalistActionRow(title: action.displayName, symbol: actionSymbol(action),
                                   isSelected: action == viewModel.selectedAction,
                                   isDisabled: viewModel.isWorking) {
                    viewModel.selectedAction = action
                }
            }
        }
    }

    private var controls: some View {
        BrutalistPanel {
            VStack(alignment: .leading, spacing: 16) {
                switch viewModel.selectedAction {
                case .compress:
                    BrutalistSectionLabel(title: "Quality")
                    choiceGrid(CompressionQuality.allCases, columns: 3,
                               selected: settings.compressionQuality, label: { $0.rawValue }) {
                        settings.compressionQuality = $0
                    }
                    Text(settings.compressionQuality.hint)
                        .font(DesignTokens.Typography.caption).foregroundStyle(palette.muted)
                    if settings.compressionQuality == .custom {
                        qualitySlider("Custom quality", value: $settings.customQuality)
                    }
                    if viewModel.isCurrentFileVideo {
                        Rectangle().fill(palette.outline).frame(height: DesignTokens.Geometry.border)
                        Toggle("Reduce frames per second", isOn: $settings.enableFramerateReduction)
                            .toggleStyle(BrutalistToggleStyle())
                            .font(DesignTokens.Typography.heading)
                            .onChange(of: settings.enableFramerateReduction) { enabled in
                                if enabled && settings.targetFramerate == nil { settings.targetFramerate = 30 }
                                settings.saveFramerateSettings()
                            }
                        if settings.enableFramerateReduction {
                            choiceGrid([15.0, 24.0, 30.0, 60.0], columns: 4,
                                       selected: settings.targetFramerate ?? 30,
                                       label: { "\(Int($0)) fps" }) {
                                settings.targetFramerate = $0
                                settings.saveFramerateSettings()
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Target frame rate")
                        }
                    }
                case .imageFormat:
                    BrutalistSectionLabel(title: "Output format")
                    choiceGrid(ImageOutputFormat.allCases, columns: 3,
                               selected: settings.imageOutputFormat, label: { $0.displayName }) {
                        settings.imageOutputFormat = $0
                        settings.saveConversionSettings()
                    }
                    if settings.imageOutputFormat == .jpeg || settings.imageOutputFormat == .heic {
                        qualitySlider("Quality", value: $settings.imageConversionQuality)
                            .onChange(of: settings.imageConversionQuality) { _ in settings.saveConversionSettings() }
                    }
                case .videoFormat:
                    BrutalistSectionLabel(title: "Output format")
                    choiceGrid(VideoOutputFormat.allCases, columns: 3,
                               selected: settings.videoOutputFormat, label: { $0.displayName }) {
                        settings.videoOutputFormat = $0
                        settings.saveConversionSettings()
                    }
                case .createGIF:
                    GIFConversionControls(settings: settings)
                case .extractAudio:
                    BrutalistSectionLabel(title: "Audio output")
                    Label("Saves the audio track as M4A.", systemImage: "waveform")
                        .font(DesignTokens.Typography.body).foregroundStyle(palette.muted)
                case .createPDF:
                    BrutalistSectionLabel(title: "Page order")
                    Text("Images become PDF pages in the order shown above.")
                        .font(DesignTokens.Typography.body).foregroundStyle(palette.muted)
                case .protectPDF:
                    BrutalistSectionLabel(title: "Password protection")
                    passwordField("Password", text: $settings.pdfPassword)
                    passwordField("Confirm password", text: $settings.pdfPasswordConfirm)
                    if !settings.pdfPassword.isEmpty && !settings.isPdfPasswordValid {
                        Label("Passwords do not match.", systemImage: "exclamationmark.circle")
                            .font(DesignTokens.Typography.caption).foregroundStyle(palette.ink)
                    }
                }
            }
        }
    }

    private func choiceGrid<T: Hashable>(_ options: [T], columns: Int, selected: T,
                                         label: @escaping (T) -> String, select: @escaping (T) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(options, id: \.self) { option in
                BrutalistChoiceChip(title: label(option), isSelected: selected == option) { select(option) }
            }
        }
    }

    private func qualitySlider(_ title: String, value: Binding<Double>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(DesignTokens.Typography.heading)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(palette.ink)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .background(palette.accent)
                    .foregroundStyle(DesignTokens.Colors.black)
            }
            BrutalistSlider(value: value, range: 0.1...1, step: 0.05, title: title)
                .frame(height: 32)
                .accessibilityLabel(title)
                .accessibilityValue("\(Int(value.wrappedValue * 100)) percent")
        }
    }

    private func passwordField(_ title: String, text: Binding<String>) -> some View {
        BrutalistSecureField(title: title, text: text)
    }

    private var saveFolder: some View {
        OutputFolderSectionView(settings: settings, isDisabled: viewModel.isWorking,
                                panelMessage: "Choose where to save processed files", compact: true)
    }

    private var workingState: some View {
        BrutalistPanel {
            HStack(spacing: 12) {
                ProgressView().controlSize(.small).tint(palette.ink)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Working").font(DesignTokens.Typography.status)
                    Text(viewModel.statusMessage.isEmpty ? "Working locally on your Mac…" : viewModel.statusMessage)
                        .font(DesignTokens.Typography.caption).foregroundStyle(palette.muted)
                }
                if viewModel.selectedAction == .createGIF {
                    Spacer()
                    Button("Cancel") { viewModel.cancelGIFConversion() }
                        .buttonStyle(BrutalistQuietButtonStyle())
                        .disabled(viewModel.isCancellingGIF)
                }
            }
        }
    }

    private var resultState: some View {
        BrutalistPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark").resizable().scaledToFit().frame(width: 18, height: 18)
                        .foregroundStyle(DesignTokens.Colors.black).frame(width: 32, height: 32)
                        .background(palette.accent)
                    Text("Done").font(DesignTokens.Typography.status)
                }
                if let url = viewModel.resultURL {
                    Text(url.lastPathComponent).font(DesignTokens.Typography.heading)
                        .lineLimit(2).truncationMode(.middle)
                }
                Text(viewModel.statusMessage).font(DesignTokens.Typography.caption).foregroundStyle(palette.muted)
                HStack(spacing: 16) {
                    Button { viewModel.showResultInFinder() } label: {
                        Label("Show in Finder", systemImage: "arrow.up.right")
                    }
                    .foregroundStyle(palette.ink)
                    Spacer()
                    Button("Dismiss") { viewModel.dismissResult() }.foregroundStyle(palette.muted)
                }
                .font(DesignTokens.Typography.heading)
                .buttonStyle(BrutalistQuietButtonStyle())
            }
        }
    }

    private func sourceSymbol(for url: URL) -> String {
        if viewModel.isCurrentFileVideo { return "film" }
        if url.pathExtension.lowercased() == "pdf" { return "doc.richtext" }
        return "photo"
    }

    private func actionSymbol(_ action: FileAction) -> String {
        switch action {
        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .imageFormat: return "photo"
        case .videoFormat: return "film"
        case .createGIF: return "photo.on.rectangle"
        case .extractAudio: return "waveform"
        case .createPDF: return "doc.on.doc"
        case .protectPDF: return "lock"
        }
    }
}
