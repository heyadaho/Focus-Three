import SwiftUI
import SwiftData

// Shared container — accessible from both App and AppDelegate.
let sharedModelContainer: ModelContainer = {
    do {
        return try ModelContainer(for: FocusItem.self)
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
