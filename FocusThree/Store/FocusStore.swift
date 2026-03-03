import Foundation
import SwiftData
import Observation

@MainActor @Observable
final class FocusStore {
    static let shared = FocusStore()
    private init() {}

    // MARK: - Queries (convenience helpers for non-view code)

    private func activeItems(context: ModelContext) -> [FocusItem] {
        let all = (try? context.fetch(FetchDescriptor<FocusItem>())) ?? []
        return all.filter { !$0.isComplete }.sorted { $0.order < $1.order }
    }

    private func normaliseOrder(_ items: [FocusItem], context: ModelContext) {
        for (i, item) in items.enumerated() {
            item.order = i
        }
        try? context.save()
    }

    // MARK: - Mutations

    /// Add a new task at the bottom of the active list.
    func addTask(text: String, context: ModelContext) {
        let current = activeItems(context: context)
        let nextOrder = (current.map(\.order).max() ?? -1) + 1
        let item = FocusItem(text: text.trimmingCharacters(in: .whitespaces), order: nextOrder)
        context.insert(item)
        try? context.save()
    }

    /// Mark a task complete — moves it to the archive.
    func completeTask(_ item: FocusItem, context: ModelContext) {
        item.isComplete = true
        item.archivedAt = Date()
        // Compact the order of remaining active items.
        let remaining = activeItems(context: context)
        normaliseOrder(remaining, context: context)
    }

    /// Restore an archived task to the top of the active list.
    func reopenTask(_ item: FocusItem, context: ModelContext) {
        item.isComplete = false
        item.archivedAt = nil
        // Shift all existing active items down by 1.
        let current = activeItems(context: context)
        for existing in current { existing.order += 1 }
        item.order = 0
        try? context.save()
    }

    /// Permanently delete a task.
    func deleteTask(_ item: FocusItem, context: ModelContext) {
        context.delete(item)
        let remaining = activeItems(context: context)
        normaliseOrder(remaining, context: context)
    }

    /// Reorder active items after a drag-and-drop in the Edit modal.
    func moveItems(from source: IndexSet, to destination: Int, items: [FocusItem], context: ModelContext) {
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        normaliseOrder(reordered, context: context)
    }
}
