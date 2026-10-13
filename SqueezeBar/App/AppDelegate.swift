//
//  AppDelegate.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panelController: StatusPanelController!
    private var dropOverlay: StatusItemDropOverlay?
    private var workObservation: AnyCancellable?
    private var idleImage: NSImage?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show dock icon - app runs in both menu bar and dock
        NSApp.setActivationPolicy(.regular)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Use custom icon from xcassets as menu bar icon
            if let image = NSImage(named: "SqueezeBar-macOS-Default") {
                // Set proper size for menu bar (menu bar icons are typically 18-22pt)
                image.size = NSSize(width: 22, height: 22)
                button.image = image
                idleImage = image
            }
            button.action = #selector(togglePanel)
            button.target = self

            // Set up drag-and-drop overlay so users can drag files onto the menu bar icon
            let overlay = StatusItemDropOverlay(frame: button.bounds)
            overlay.autoresizingMask = [.width, .height]
            overlay.dropDelegate = self
            button.addSubview(overlay)
            dropOverlay = overlay
        }

        panelController = StatusPanelController(statusItem: statusItem)
        workObservation = Publishers.CombineLatest(
            MainViewModel.shared.$isCompressing, MainViewModel.shared.$isConverting
        ).receive(on: RunLoop.main).sink { [weak self] compressing, converting in
            guard let button = self?.statusItem.button else { return }
            if compressing || converting {
                button.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "SqueezeBar working")
                button.image?.size = NSSize(width: 18, height: 18)
                button.toolTip = "SqueezeBar is working"
            } else {
                button.image = self?.idleImage
                button.toolTip = "SqueezeBar"
            }
        }
    }

    @objc func togglePanel() {
        panelController.toggle()
    }

    private func showPanel() {
        panelController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        panelController.tearDown()
    }

    // Called when app icon is clicked in dock
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !panelController.isVisible {
            showPanel()
        }
        return true
    }

    // Called when files are opened via URL (modern API)
    func application(_ sender: NSApplication, open urls: [URL]) {
        guard !urls.isEmpty else { return }

        showPanel()

        MainViewModel.shared.selectFiles(urls)
    }

    // Called for single file (legacy API - kept for compatibility)
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)

        showPanel()
        MainViewModel.shared.handleFileOpen(url: url)
        return true
    }

    // Helper method to check if file type is supported
    func isFileTypeSupported(_ url: URL) -> Bool {
        return AppDelegate.isSupportedFileExtension(url.pathExtension.lowercased())
    }

    static func isSupportedFileExtension(_ ext: String) -> Bool {
        let supportedExtensions: Set<String> = [
            // Images
            "jpg", "jpeg", "png", "heic", "heif", "bmp", "tiff", "tif", "webp", "gif",
            // Videos
            "mp4", "mov", "m4v", "mpg", "mpeg", "avi", "mkv",
            // Audio
            "aac", "m4a",
            // PDF
            "pdf"
        ]
        return supportedExtensions.contains(ext)
    }
}

// MARK: - StatusItemDropDelegate

extension AppDelegate: StatusItemDropDelegate {

    func dropOverlayDraggingEntered() {
        if !panelController.isVisible {
            showPanel()
        }
        MainViewModel.shared.isDragging = true
    }

    func dropOverlayDraggingExited() {
        MainViewModel.shared.isDragging = false
    }

    func dropOverlayPerformDrop(fileURLs: [URL]) {
        MainViewModel.shared.isDragging = false
        if !panelController.isVisible {
            showPanel()
        }
        MainViewModel.shared.selectFiles(fileURLs)
    }
}
