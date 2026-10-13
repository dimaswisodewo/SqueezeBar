import AppKit
import SwiftUI

private final class StatusPanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        // Text controls and sheets get the first opportunity to handle Escape.
        guard attachedSheet == nil else { return }
        onCancel?()
    }
}

@MainActor
final class StatusPanelController: NSObject, NSWindowDelegate {
    private let statusItem: NSStatusItem
    private let panel: StatusPanel
    private var preferredHeight: CGFloat = 400
    private var hostingDisplayID: CGDirectDisplayID?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var spaceObserver: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?
    private var hideAfterSheet = false

    var isVisible: Bool { panel.isVisible }

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        panel = StatusPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.hasShadow = true
        panel.animationBehavior = .none
        if #available(macOS 13.0, *) {
            panel.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications]
        } else {
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
        panel.onCancel = { [weak self] in self?.hide() }
        panel.contentViewController = NSHostingController(rootView: MainPopoverView { [weak self] height in
            self?.updatePreferredHeight(height) ?? height
        })
    }

    func toggle() {
        guard panel.attachedSheet == nil else { return }
        if isVisible { hide() } else { show() }
    }

    func show() {
        guard panel.attachedSheet == nil, positionPanel() else { return }
        hideAfterSheet = false
        // A nonactivating panel can receive keyboard input without switching apps or Spaces.
        panel.makeKeyAndOrderFront(nil)
        startMonitoring()
    }

    func hide() {
        guard panel.attachedSheet == nil else { return }
        panel.orderOut(nil)
        stopMonitoring()
        hostingDisplayID = nil
        hideAfterSheet = false
    }

    private func updatePreferredHeight(_ height: CGFloat) -> CGFloat {
        preferredHeight = height
        let fittedHeight = fittedHeight(on: statusItem.button?.window?.screen)
        if panel.attachedSheet == nil {
            if isVisible {
                _ = positionPanel()
            } else {
                panel.setContentSize(NSSize(width: 420, height: fittedHeight))
            }
        }
        return fittedHeight
    }

    private func fittedHeight(on screen: NSScreen?) -> CGFloat {
        let availableHeight = max(1, (screen?.visibleFrame.height ?? 850) - 40)
        return min(max(300, preferredHeight), availableHeight)
    }

    @discardableResult
    private func positionPanel() -> Bool {
        guard let button = statusItem.button, let window = button.window, let screen = window.screen else {
            return false
        }
        let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        let visibleFrame = screen.visibleFrame
        let size = NSSize(width: 420, height: fittedHeight(on: screen))
        let x = min(max(anchor.midX - size.width / 2, visibleFrame.minX), visibleFrame.maxX - size.width)
        let top = min(anchor.minY - 6, visibleFrame.maxY)
        let y = max(visibleFrame.minY, top - size.height)
        let frame = NSRect(origin: NSPoint(x: x, y: y), size: size)
        if panel.frame != frame { panel.setFrame(frame, display: true) }
        hostingDisplayID = displayID(of: screen)
        return true
    }

    private func startMonitoring() {
        guard localMouseMonitor == nil else { return }
        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self] event in
            self?.dismissForOutsideClick()
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self] _ in
            self?.dismissForOutsideClick()
        }
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismissForContextChange() }
        }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isVisible else { return }
                if NSScreen.screens.contains(where: { self.displayID(of: $0) == self.hostingDisplayID }) {
                    if self.panel.attachedSheet == nil { self.positionPanel() }
                } else {
                    self.dismissForContextChange()
                }
            }
        }
    }

    private func dismissForOutsideClick() {
        guard isVisible, panel.attachedSheet == nil else { return }
        let location = NSEvent.mouseLocation
        if panel.frame.contains(location) { return }
        if let button = statusItem.button, let window = button.window {
            let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
            if anchor.contains(location) { return }
        }
        hide()
    }

    private func dismissForContextChange() {
        if panel.attachedSheet != nil {
            hideAfterSheet = true
        } else {
            hide()
        }
    }

    func windowDidEndSheet(_ notification: Notification) {
        // AppKit may still have the sheet attached during the delegate callback.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.hideAfterSheet {
                self.hide()
            } else if self.isVisible {
                self.positionPanel()
                self.panel.makeKey()
            }
        }
    }

    private func displayID(of screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    private func stopMonitoring() {
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let spaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(spaceObserver) }
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        localMouseMonitor = nil
        globalMouseMonitor = nil
        spaceObserver = nil
        screenObserver = nil
    }

    func tearDown() {
        if let sheet = panel.attachedSheet { panel.endSheet(sheet, returnCode: .cancel) }
        panel.orderOut(nil)
        stopMonitoring()
    }
}
