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
            if let image = NSImage(named: "AppIcon") {
                // Set proper size for menu bar (menu bar icons are typically 18-22pt)
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
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

        // Activate app first to ensure proper focus
        NSApp.activate(ignoringOtherApps: true)

        // Show popover
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Ensure the popover's window becomes key to fix greyish appearance
        DispatchQueue.main.async { [weak self] in
            self?.popover.contentViewController?.view.window?.makeKey()
        }
    }

    // Called when app icon is clicked in dock
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !popover.isShown {
            showPopover()
        }
        return true
    }
}
