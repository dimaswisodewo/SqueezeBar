import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var viewModel: MainViewModel
    var appMode: AppMode = .compress
    var conversionCategory: ConversionCategory? = nil
    @State private var isTargeted = false

    private var isImageToPDF: Bool {
        appMode == .convert && conversionCategory == .imageToPDF
    }

    private var hasFiles: Bool {
        isImageToPDF ? !viewModel.droppedFileURLs.isEmpty : viewModel.droppedFileURL != nil
    }

    private var isHighlighted: Bool { (isTargeted || viewModel.isDragging) && !viewModel.isWorking }

    var body: some View {
        Button {
            guard !viewModel.isWorking && !viewModel.isDragging else { return }
            if isImageToPDF { openMultiImagePicker() }
            else if !hasFiles { viewModel.openFilePicker() }
        } label: {
            BrutalistDropSurface(isHighlighted: isHighlighted) {
                VStack(spacing: 16) {
                    Image(systemName: hasFiles ? "checkmark.square" : "arrow.down.to.line")
                        .resizable().scaledToFit().frame(width: 28, height: 28)
                        .accessibilityHidden(true)
                    Text(mainMessage)
                        .font(DesignTokens.Typography.hero)
                        .multilineTextAlignment(.center)
                        .lineLimit(3).truncationMode(.middle)
                    Text(hasFiles ? "Ready to process" : "Drop files or click to browse")
                        .font(DesignTokens.Typography.body)
                    if !hasFiles {
                        HStack(spacing: 8) {
                            ForEach(supportedFormats, id: \.self) { format in
                                BrutalistBadge(title: format)
                            }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: 180)
            }
        }
        .buttonStyle(BrutalistQuietButtonStyle())
        .disabled(viewModel.isWorking)
        .overlay(alignment: .topTrailing) {
            if hasFiles {
                Button { viewModel.removeAttachedFile() } label: {
                    Image(systemName: "xmark").resizable().scaledToFit().frame(width: 12, height: 12)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(BrutalistButtonStyle())
                .accessibilityLabel("Remove selected files")
                .disabled(viewModel.isWorking)
                .padding(12)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard !viewModel.isWorking else { return false }
            let result = isImageToPDF
                ? viewModel.handleMultiDrop(providers: providers)
                : viewModel.handleDrop(providers: providers)
            if result { HapticManager.shared.medium() }
            return result
        }
        .onChange(of: isTargeted) { newValue in
            DispatchQueue.main.async {
                if !viewModel.isWorking { viewModel.isDragging = newValue }
            }
        }
    }

    private var mainMessage: String {
        if isHighlighted { return "Drop files here" }
        if isImageToPDF && hasFiles { return "\(viewModel.droppedFileURLs.count) images selected" }
        if let url = viewModel.droppedFileURL { return url.lastPathComponent }
        return isImageToPDF ? "Start with a file" : "Start with a file"
    }

    private var supportedFormats: [String] {
        switch conversionCategory {
        case .imageToPDF, .imageToImage: return ["JPG", "PNG", "HEIC"]
        case .pdfProtect: return ["PDF"]
        case .videoToVideo, .videoToAudio, .videoToGIF: return ["MP4", "MOV", "M4V"]
        case nil: return ["IMG", "VIDEO", "PDF"]
        }
    }

    private func openMultiImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.message = "Choose images to combine into a PDF"
        panel.prompt = "Select"
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic, .bmp, .tiff]

        if panel.runModal() == .OK {
            let urls = panel.urls
            DispatchQueue.main.async {
                for url in urls {
                    if !self.viewModel.droppedFileURLs.contains(url) {
                        self.viewModel.droppedFileURLs.append(url)
                    }
                }
                if self.viewModel.droppedFileURL == nil {
                    self.viewModel.droppedFileURL = self.viewModel.droppedFileURLs.first
                }
            }
        }
    }
}

#Preview {
    DropZoneView(viewModel: MainViewModel.shared).frame(width: 380).padding(20)
        .font(DesignTokens.Typography.body)
}
