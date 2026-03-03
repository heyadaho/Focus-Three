import Foundation
import SwiftData

@Model
final class FocusItem {
    var id: UUID
    var text: String
    var isComplete: Bool
    var order: Int
    var createdAt: Date
    var archivedAt: Date?
    /// Accumulated logged seconds (paused + completed sessions).
    var timeLoggedSeconds: Int
    /// Non-nil while the timer is actively running.
    var timerStartedAt: Date?

    init(text: String, order: Int) {
        self.id = UUID()
        self.text = text
        self.isComplete = false
        self.order = order
        self.createdAt = Date()
        self.archivedAt = nil
        self.timeLoggedSeconds = 0
        self.timerStartedAt = nil
    }
}
