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
    private var popover: NSPopover!
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
            button.action = #selector(togglePopover)
            button.target = self

            // Set up drag-and-drop overlay so users can drag files onto the menu bar icon
            let overlay = StatusItemDropOverlay(frame: button.bounds)
            overlay.autoresizingMask = [.width, .height]
            overlay.dropDelegate = self
            button.addSubview(overlay)
            dropOverlay = overlay
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 400)
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(rootView: MainPopoverView { [weak self] preferredHeight in
            guard let self else { return preferredHeight }
            let screenHeight = self.statusItem.button?.window?.screen?.visibleFrame.height
                ?? NSScreen.main?.visibleFrame.height ?? 850
            let height = min(max(300, preferredHeight), max(300, screenHeight - 40))
            if abs(self.popover.contentSize.height - height) > 1 {
                self.popover.contentSize = NSSize(width: 420, height: height)
            }
            return height
        })
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

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Ensure the popover's window becomes key (with slight delay for window creation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let popoverWindow = self?.popover.contentViewController?.view.window else { return }

            // Only call makeKey if it's not a status bar window
            let windowClassName = NSStringFromClass(type(of: popoverWindow))
            if !windowClassName.contains("StatusBar") {
                popoverWindow.makeKey()
            }
        }
    }

    // Called when app icon is clicked in dock
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !popover.isShown {
            showPopover()
        }
        return true
    }

    // Called when files are opened via URL (modern API)
    func application(_ sender: NSApplication, open urls: [URL]) {
        guard !urls.isEmpty else { return }

        showPopover()

        MainViewModel.shared.selectFiles(urls)
    }

    // Called for single file (legacy API - kept for compatibility)
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)

        showPopover()
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
        if !popover.isShown {
            showPopover()
        }
        MainViewModel.shared.isDragging = true
    }

    func dropOverlayDraggingExited() {
        MainViewModel.shared.isDragging = false
    }

    func dropOverlayPerformDrop(fileURLs: [URL]) {
        MainViewModel.shared.isDragging = false
        if !popover.isShown {
            showPopover()
        }
        MainViewModel.shared.selectFiles(fileURLs)
    }
}
