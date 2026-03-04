import AppKit
import SwiftData
import SwiftUI

// MARK: - Notification names

extension Notification.Name {
    static let showEditModal      = Notification.Name("com.edwardlake.focusthree.showEditModal")
    static let showSettingsPanel  = Notification.Name("com.edwardlake.focusthree.showSettings")
    static let togglePinnedWindow = Notification.Name("com.edwardlake.focusthree.togglePinnedWindow")
}

// MARK: - FloatingPanel

/// Borderless window subclass that can become key, enabling TextField input.
final class FloatingPanel: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var editWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var pinnedWindow: NSWindow?

    // MARK: Drag-to-detach state

    private enum DragState {
        /// Not tracking anything.
        case idle
        /// MouseDown in header; waiting for drag threshold.
        case watchingHeader(startScreen: NSPoint)
        /// Window created; moving it with the mouse.
        case draggingWindow(window: NSWindow, offset: NSPoint)
    }

    private var dragState: DragState = .idle
    private var dragMonitor: Any?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        Task.detached(priority: .background) {
            LoginItemManager.shared.registerOnFirstLaunch()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(openEditModal),
                                               name: .showEditModal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openSettingsPanel),
                                               name: .showSettingsPanel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(togglePinnedWindow),
                                               name: .togglePinnedWindow, object: nil)

        Task {
            try? await Task.sleep(for: .milliseconds(400))
            let context = sharedModelContainer.mainContext
            let all = (try? context.fetch(FetchDescriptor<FocusItem>())) ?? []
            if all.filter({ !$0.isComplete }).isEmpty { openEditModal() }
        }
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "list.number",
                                   accessibilityDescription: "Focus Three")
            button.imageScaling = .scaleProportionallyDown
            button.action = #selector(handleStatusItemClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView()
                .modelContainer(sharedModelContainer)
                .environment(FocusStore.shared)
        )
        self.popover = popover
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp { showRightClickMenu() } else { togglePopover() }
    }

    private func togglePopover() {
        if let pinned = pinnedWindow, pinned.isVisible {
            pinned.close()
            pinnedWindow = nil
            return
        }
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            DispatchQueue.main.async {
                self.popover?.contentViewController?.view.window?.makeKey()
                self.installDragMonitor()
            }
        }
    }

    private func showRightClickMenu() {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettingsPanel), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Focus Three", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        DispatchQueue.main.async { self.statusItem?.menu = nil }
    }

    // MARK: - Drag-to-detach monitor

    private func installDragMonitor() {
        removeDragMonitor()
        dragState = .idle

        dragMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            self?.handleDragEvent(event)
            return event
        }
    }

    private func removeDragMonitor() {
        if let m = dragMonitor { NSEvent.removeMonitor(m); dragMonitor = nil }
        dragState = .idle
    }

    @MainActor
    private func handleDragEvent(_ event: NSEvent) {
        switch event.type {

        case .leftMouseDown:
            if isEventInPopoverHeader(event) {
                dragState = .watchingHeader(startScreen: NSEvent.mouseLocation)
            } else {
                dragState = .idle
            }

        case .leftMouseDragged:
            switch dragState {

            case .watchingHeader(let start):
                let mouse = NSEvent.mouseLocation
                let dx = mouse.x - start.x
                let dy = mouse.y - start.y
                // Only detach after 8pt of movement
                guard sqrt(dx * dx + dy * dy) > 8 else { break }

                guard let popover, popover.isShown else {
                    dragState = .idle; break
                }
                popover.performClose(nil)

                let window = makePinnedPanel()
                // Top-left of window relative to current mouse position
                let topLeft = NSPoint(x: mouse.x - 160, y: mouse.y + 22)
                window.setFrameTopLeftPoint(topLeft)
                pinnedWindow = window
                window.makeKeyAndOrderFront(nil)

                // Record fixed offset so window follows the cursor exactly
                let offset = NSPoint(x: topLeft.x - mouse.x, y: topLeft.y - mouse.y)
                dragState = .draggingWindow(window: window, offset: offset)

            case .draggingWindow(let window, let offset):
                let mouse = NSEvent.mouseLocation
                window.setFrameTopLeftPoint(NSPoint(x: mouse.x + offset.x,
                                                    y: mouse.y + offset.y))

            default:
                break
            }

        case .leftMouseUp:
            // If we were moving a window, stop. Clean up monitor.
            removeDragMonitor()

        default:
            break
        }
    }

    /// Returns true when the mouse is in the top 44pt header of the popover.
    /// Uses screen coordinates so it works regardless of which view has focus.
    private func isEventInPopoverHeader(_ event: NSEvent) -> Bool {
        guard let popoverWindow = popover?.contentViewController?.view.window,
              popoverWindow.isVisible else { return false }

        let mouse = NSEvent.mouseLocation   // screen coordinates
        let frame = popoverWindow.frame     // screen coordinates
        return frame.contains(mouse) && mouse.y >= (frame.maxY - 44)
    }

    // MARK: - Pinned floating window

    @objc func togglePinnedWindow() {
        if let existing = pinnedWindow, existing.isVisible {
            existing.close()
            pinnedWindow = nil
            return
        }
        popover?.performClose(nil)

        var topLeft: NSPoint = .zero
        if let button = statusItem?.button, let bw = button.window {
            let r = bw.convertToScreen(button.frame)
            topLeft = NSPoint(x: r.minX, y: r.minY)
        }
        showPinnedWindow(topLeft: topLeft)
    }

    private func showPinnedWindow(topLeft: NSPoint) {
        let window = makePinnedPanel()
        window.setFrameTopLeftPoint(topLeft)
        pinnedWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    private func makePinnedPanel() -> FloatingPanel {
        let view = MenuBarPopoverView(isPinned: true)
            .modelContainer(sharedModelContainer)
            .environment(FocusStore.shared)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        let controller = NSHostingController(rootView: view)
        controller.view.wantsLayer = true
        controller.view.layer?.backgroundColor = .clear

        let window = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.contentViewController = controller
        window.isReleasedWhenClosed = false
        return window
    }

    // MARK: - Edit modal

    @objc func openEditModal() {
        popover?.performClose(nil)
        if editWindow == nil {
            let view = EditModalView()
                .modelContainer(sharedModelContainer)
                .environment(FocusStore.shared)
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Focus Three"
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.setContentSize(NSSize(width: 480, height: 520))
            window.center()
            window.isReleasedWhenClosed = false
            editWindow = window
        }
        editWindow?.orderFrontRegardless()
    }

    // MARK: - Settings panel

    @objc func openSettingsPanel() {
        popover?.performClose(nil)
        if settingsWindow == nil {
            let view = SettingsView()
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Settings"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 300, height: 120))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.orderFrontRegardless()
    }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        // Only remove the monitor if we're not already mid-drag
        if case .draggingWindow = dragState { return }
        removeDragMonitor()
    }
}
