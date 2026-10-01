//
//  StatusItemDropOverlay.swift
//  SqueezeBar
//

import AppKit

protocol StatusItemDropDelegate: AnyObject {
    func dropOverlayDraggingEntered()
    func dropOverlayDraggingExited()
    func dropOverlayPerformDrop(fileURLs: [URL])
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
        guard let urls = extractFileURLs(from: sender), !urls.isEmpty else { return false }
        dropDelegate?.dropOverlayPerformDrop(fileURLs: urls)
        return true
    }

    // MARK: - Helpers

    private func hasValidFile(in info: NSDraggingInfo) -> Bool {
        extractFileURLs(from: info) != nil
    }

    private func extractFileURLs(from info: NSDraggingInfo) -> [URL]? {
        let pasteboard = info.draggingPasteboard
        guard let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL],
        !urls.isEmpty
        else { return nil }
        return urls
    }
}
