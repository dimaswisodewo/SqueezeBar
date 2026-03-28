//
//  StatusItemDropOverlay.swift
//  SqueezeBar
//

import AppKit

protocol StatusItemDropDelegate: AnyObject {
    func dropOverlayDraggingEntered()
    func dropOverlayDraggingExited()
    func dropOverlayPerformDrop(fileURL: URL)
}

class StatusItemDropOverlay: NSView {
    weak var dropDelegate: StatusItemDropDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    // Pass all mouse events through to the NSStatusBarButton underneath
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasValidFile(in: sender) else { return [] }
        dropDelegate?.dropOverlayDraggingEntered()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dropDelegate?.dropOverlayDraggingExited()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return hasValidFile(in: sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = extractFileURL(from: sender) else { return false }
        dropDelegate?.dropOverlayPerformDrop(fileURL: url)
        return true
    }

    // MARK: - Helpers

    private func hasValidFile(in info: NSDraggingInfo) -> Bool {
        extractFileURL(from: info) != nil
    }

    private func extractFileURL(from info: NSDraggingInfo) -> URL? {
        let pasteboard = info.draggingPasteboard
        guard let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL],
        let url = urls.first,
        AppDelegate.isSupportedFileExtension(url.pathExtension.lowercased())
        else { return nil }
        return url
    }
}
