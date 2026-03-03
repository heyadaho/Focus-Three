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

    init(text: String, order: Int) {
        self.id = UUID()
        self.text = text
        self.isComplete = false
        self.order = order
        self.createdAt = Date()
        self.archivedAt = nil
    }
}
