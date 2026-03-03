import SwiftUI
import SwiftData

// Shared container — accessible from both App and AppDelegate.
// Store is versioned so schema changes never require migration — just bump the suffix.
let sharedModelContainer: ModelContainer = {
    let appSupport = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let storeURL = appSupport.appendingPathComponent("FocusThree_v3.store")
    do {
        let config = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: FocusItem.self, configurations: config)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

@main
struct FocusThreeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All UI is driven by NSStatusItem in AppDelegate.
        // An empty Settings scene is kept so SwiftUI doesn't complain about a bodyless App.
        Settings { EmptyView() }
    }
}
