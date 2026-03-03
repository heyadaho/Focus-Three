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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────
            HStack {
                Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    NotificationCenter.default.post(name: .togglePinnedWindow, object: nil)
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.caption)
                        .foregroundStyle(isPinned ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .help(isPinned ? "Return to menu bar" : "Pin to screen")
            }
            .frame(height: 44)
            .padding(.horizontal, 16)

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
            Button("Edit") {
                NotificationCenter.default.post(name: .showEditModal, object: nil)
            }
            .buttonStyle(.plain)
            .font(.callout)
            .frame(height: 44)
            .padding(.horizontal, 16)
        }
        .frame(width: 320)
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
                    Image(systemName: "chevron.up.circle")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
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
