import Foundation
import ServiceManagement

final class LoginItemManager {
    static let shared = LoginItemManager()
    private init() {}

    private let hasRegisteredKey = "com.edwardlake.focusthree.loginItemRegistered"

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers the app as a login item exactly once (on first launch).
    func registerOnFirstLaunch() {
        guard !UserDefaults.standard.bool(forKey: hasRegisteredKey) else { return }
        enable()
        UserDefaults.standard.set(true, forKey: hasRegisteredKey)
    }

    func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("[LoginItemManager] Failed to register: \(error)")
        }
    }

    func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("[LoginItemManager] Failed to unregister: \(error)")
        }
    }
}
