import SwiftUI
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(\.modelContext) private var context
    @Environment(FocusStore.self) private var store
    @Query(filter: #Predicate<FocusItem> { !$0.isComplete },
           sort: \FocusItem.order) private var activeItems: [FocusItem]

    var isPinned: Bool = false

    @State private var newTaskText = ""
    @State private var showSuccess = false
    @FocusState private var inputFocused: Bool

    // Drag-to-reorder state for top-3 slots
    @State private var draggingSlot: Int? = nil
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────
            HStack(spacing: 0) {
                Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
                Spacer()
                Button {
                    NotificationCenter.default.post(name: .togglePinnedWindow, object: nil)
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.caption)
                        .foregroundStyle(isPinned ? .primary : .secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(isPinned ? "Return to menu bar" : "Pin to screen")
            }
            .frame(height: 44)

            Divider()

            // ── Top-3 slots (always 3, order-based) ──────────────
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { slotIndex in
                    if slotIndex > 0 {
                        Divider().padding(.leading, 60)
                    }
                    let slotItem = activeItems.first { $0.order == slotIndex }
                    if let item = slotItem {
                        PriorityRowView(item: item)
                            .offset(y: draggingSlot == slotIndex ? dragOffset : 0)
                            .zIndex(draggingSlot == slotIndex ? 1 : 0)
                            .overlay(alignment: .leading) {
                                // Invisible drag handle — covers the 16pt left padding only,
                                // so it never overlaps the circle button or text.
                                Color.clear
                                    .frame(width: 16, height: 44)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 4, coordinateSpace: .local)
                                            .onChanged { value in
                                                // Only respond to primarily vertical drags
                                                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                                                draggingSlot = slotIndex
                                                let maxDown = CGFloat(2 - slotIndex) * 44
                                                let maxUp   = CGFloat(-slotIndex) * 44
                                                dragOffset = max(maxUp, min(maxDown, value.translation.height))
                                            }
                                            .onEnded { value in
                                                commitSlotDrag(fromSlot: slotIndex, translation: value.translation.height)
                                                draggingSlot = nil
                                                dragOffset = 0
                                            }
                                    )
                            }
                    } else {
                        EmptySlotView(slotOrder: slotIndex)
                    }
                }
            }

            Divider()

            // ── Always-visible add area ───────────────────────────
            HStack {
                if showSuccess {
                    Text("Added to your list ✓")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("Add a task…", text: $newTaskText)
                        .textFieldStyle(.plain)
                        .focused($inputFocused)
                        .onSubmit { commitAdd() }
                    if !newTaskText.isEmpty {
                        Button("Add") { commitAdd() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 16)

            Divider()

            // ── Footer ───────────────────────────────────────────
            Button("View all tasks") {
                NotificationCenter.default.post(name: .showEditModal, object: nil)
            }
            .buttonStyle(.plain)
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 44)
            .padding(.horizontal, 16)
        }
        .frame(width: 320)
    }

    private func commitSlotDrag(fromSlot: Int, translation: CGFloat) {
        // Determine how many slots to move (threshold = half a row height)
        let moved = Int((translation + (translation >= 0 ? 22 : -22)) / 44)
        let targetSlot = max(0, min(2, fromSlot + moved))
        guard targetSlot != fromSlot,
              let fromItem = activeItems.first(where: { $0.order == fromSlot }),
              let toItem   = activeItems.first(where: { $0.order == targetSlot }) else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            store.swapOrder(fromItem, toItem, context: context)
        }
    }

    private func commitAdd() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addTask(text: trimmed, context: context)
        newTaskText = ""
        showSuccess = true
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            showSuccess = false
        }
    }
}

// MARK: - Empty slot

private struct EmptySlotView: View {
    let slotOrder: Int

    @Environment(\.modelContext) private var context
    @Environment(FocusStore.self) private var store
    @Query(filter: #Predicate<FocusItem> { !$0.isComplete },
           sort: \FocusItem.order) private var allActive: [FocusItem]

    @State private var text = ""
    @FocusState private var focused: Bool

    private var upcomingItems: [FocusItem] { allActive.filter { $0.order >= 3 } }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.dotted")
                .foregroundStyle(.tertiary)
                .font(.title3)
                .frame(width: 32, height: 44)

            TextField("New priority…", text: $text)
                .textFieldStyle(.plain)
                .focused($focused)
                .foregroundStyle(.secondary)
                .onSubmit { commit() }
                .frame(maxWidth: .infinity)

            if !upcomingItems.isEmpty {
                Menu {
                    ForEach(upcomingItems) { item in
                        Button(item.text) {
                            store.promoteToSlot(item, slotOrder: slotOrder, context: context)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 44)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.insertAtSlot(text: trimmed, slotOrder: slotOrder, context: context)
        text = ""
    }
}
