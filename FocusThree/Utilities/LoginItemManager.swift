import Foundation
import ServiceManagement

final class LoginItemManager: @unchecked Sendable {
    static let shared = LoginItemManager()
    private init() {}

    private let hasRegisteredKey = "com.edwardlake.focusthree.loginItemRegistered"

    nonisolated var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers the app as a login item exactly once (on first launch).
    /// Safe to call from any thread.
    nonisolated func registerOnFirstLaunch() {
        guard !UserDefaults.standard.bool(forKey: hasRegisteredKey) else { return }
        enable()
        UserDefaults.standard.set(true, forKey: hasRegisteredKey)
    }

    nonisolated func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("[LoginItemManager] Failed to register: \(error)")
        }
    }

    nonisolated func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("[LoginItemManager] Failed to unregister: \(error)")
        }
    }
}
