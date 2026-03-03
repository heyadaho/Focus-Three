import Foundation
import SwiftData
import Observation

@MainActor @Observable
final class FocusStore {
    static let shared = FocusStore()
    private init() {}

    // MARK: - Private helpers

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

    // MARK: - Task mutations

    func addTask(text: String, context: ModelContext) {
        let current = activeItems(context: context)
        let nextOrder = (current.map(\.order).max() ?? -1) + 1
        let item = FocusItem(text: text.trimmingCharacters(in: .whitespaces), order: nextOrder)
        context.insert(item)
        try? context.save()
    }

    /// Mark a task complete, flushing any running timer first.
    /// Does NOT renormalise order — the freed slot stays freed so the popover
    /// can show it as an empty slot rather than auto-promoting upcoming tasks.
    func completeTask(_ item: FocusItem, context: ModelContext) {
        if let start = item.timerStartedAt {
            item.timeLoggedSeconds += Int(Date().timeIntervalSince(start))
            item.timerStartedAt = nil
        }
        item.isComplete = true
        item.archivedAt = Date()
        try? context.save()
    }

    /// Restore an archived task to the BOTTOM of the upcoming list.
    func reopenTask(_ item: FocusItem, context: ModelContext) {
        item.isComplete = false
        item.archivedAt = nil
        let current = activeItems(context: context)
        item.order = (current.map(\.order).max() ?? -1) + 1
        try? context.save()
    }

    func deleteTask(_ item: FocusItem, context: ModelContext) {
        context.delete(item)
        let remaining = activeItems(context: context)
        normaliseOrder(remaining, context: context)
    }

    func clearArchive(_ items: [FocusItem], context: ModelContext) {
        items.forEach { context.delete($0) }
        try? context.save()
    }

    // MARK: - Drag reorder

    func moveItems(from source: IndexSet, to destination: Int, items: [FocusItem], context: ModelContext) {
        var reordered = items
        let moving = source.map { reordered[$0] }
        for index in source.sorted().reversed() { reordered.remove(at: index) }
        let adjustedDest = destination - source.filter { $0 < destination }.count
        reordered.insert(contentsOf: moving, at: max(0, min(adjustedDest, reordered.count)))
        normaliseOrder(reordered, context: context)
    }

    // MARK: - Slot management (popover top-3)

    /// Insert a brand-new task directly into a specific top-3 slot (order 0, 1, or 2).
    func insertAtSlot(text: String, slotOrder: Int, context: ModelContext) {
        let item = FocusItem(text: text.trimmingCharacters(in: .whitespaces), order: slotOrder)
        context.insert(item)
        try? context.save()
    }

    /// Move an existing upcoming task (order ≥ 3) into an empty top-3 slot.
    func promoteToSlot(_ item: FocusItem, slotOrder: Int, context: ModelContext) {
        item.order = slotOrder
        try? context.save()
    }

    // MARK: - Timer

    func startTimer(_ item: FocusItem, context: ModelContext) {
        item.timerStartedAt = Date()
        try? context.save()
    }

    func pauseTimer(_ item: FocusItem, context: ModelContext) {
        guard let start = item.timerStartedAt else { return }
        item.timeLoggedSeconds += Int(Date().timeIntervalSince(start))
        item.timerStartedAt = nil
        try? context.save()
    }
}
