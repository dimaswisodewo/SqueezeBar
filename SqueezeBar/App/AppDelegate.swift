//
//  AppDelegate.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

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
            }
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 560)
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(rootView: MainPopoverView())
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

        if urls.count == 1 {
            MainViewModel.shared.handleFileOpen(url: urls[0])
        } else {
            MainViewModel.shared.handleFileOpen(url: urls[0])
            MainViewModel.shared.statusMessage = "Processing first file. Please drop one file at a time."
        }
    }

    // Called for single file (legacy API - kept for compatibility)
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)

        guard FileManager.default.isReadableFile(atPath: url.path),
              isFileTypeSupported(url) else {
            return false
        }

        showPopover()
        MainViewModel.shared.handleFileOpen(url: url)
        return true
    }

    // Helper method to check if file type is supported
    private func isFileTypeSupported(_ url: URL) -> Bool {
        // Fast check using path extension (avoids expensive resourceValues call)
        let ext = url.pathExtension.lowercased()

        let supportedExtensions: Set<String> = [
            // Images
            "jpg", "jpeg", "png", "heic", "heif", "bmp", "tiff", "tif",
            // Videos
            "mp4", "mov", "m4v", "mpg", "mpeg",
            // PDF
            "pdf"
        ]

        return supportedExtensions.contains(ext)
    }
}
