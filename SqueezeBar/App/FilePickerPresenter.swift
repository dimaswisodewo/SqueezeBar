import AppKit

@MainActor
enum FilePickerPresenter {
    static func present(_ picker: NSOpenPanel, completion: @escaping (NSApplication.ModalResponse) -> Void) {
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            guard window.attachedSheet == nil else { return }
            picker.beginSheetModal(for: window, completionHandler: completion)
        } else {
            picker.begin(completionHandler: completion)
        }
    }
}
