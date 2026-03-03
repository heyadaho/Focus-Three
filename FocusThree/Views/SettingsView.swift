import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = LoginItemManager.shared.isEnabled

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    enabled
                        ? LoginItemManager.shared.enable()
                        : LoginItemManager.shared.disable()
                }
        }
        .padding()
        .frame(width: 300)
    }
}
