import AppKit
import SwiftData
import SwiftUI

// MARK: - Notification names

extension Notification.Name {
    static let showEditModal      = Notification.Name("com.edwardlake.focusthree.showEditModal")
    static let showSettingsPanel  = Notification.Name("com.edwardlake.focusthree.showSettings")
    static let togglePinnedWindow = Notification.Name("com.edwardlake.focusthree.togglePinnedWindow")
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var editWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var pinnedWindow: NSWindow?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        // Register login item on a background thread — SMAppService can block on first launch.
        Task.detached(priority: .background) {
            LoginItemManager.shared.registerOnFirstLaunch()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(openEditModal),
                                               name: .showEditModal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openSettingsPanel),
                                               name: .showSettingsPanel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(togglePinnedWindow),
                                               name: .togglePinnedWindow, object: nil)

        // Open Edit modal on first launch if there are no active tasks.
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            let context = sharedModelContainer.mainContext
            let all = (try? context.fetch(FetchDescriptor<FocusItem>())) ?? []
            if all.filter({ !$0.isComplete }).isEmpty {
                openEditModal()
            }
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

        // Build the popover.
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView()
                .modelContainer(sharedModelContainer)
                .environment(FocusStore.shared)
        )
        self.popover = popover
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showRightClickMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
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
        // Remove the menu after display so left-click still fires our action.
        DispatchQueue.main.async { self.statusItem?.menu = nil }
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

    // MARK: - Pinned floating window

    @objc func togglePinnedWindow() {
        // If already pinned and visible, close it
        if let existing = pinnedWindow, existing.isVisible {
            existing.close()
            pinnedWindow = nil
            return
        }

        // Close the popover and create a floating always-on-top window
        popover?.performClose(nil)

        let view = MenuBarPopoverView(isPinned: true)
            .modelContainer(sharedModelContainer)
            .environment(FocusStore.shared)
        let controller = NSHostingController(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Focus Three"
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.contentViewController = controller
        window.isReleasedWhenClosed = false

        // Position below the status bar button
        if let button = statusItem?.button,
           let buttonWindow = button.window {
            let screenRect = buttonWindow.convertToScreen(button.frame)
            window.setFrameTopLeftPoint(NSPoint(x: screenRect.minX,
                                                y: screenRect.minY))
        } else {
            window.center()
        }

        pinnedWindow = window
        window.orderFrontRegardless()
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
