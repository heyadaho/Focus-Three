import SwiftUI
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(\.modelContext) private var context
    @Environment(FocusStore.self) private var store
    @Query(filter: #Predicate<FocusItem> { !$0.isComplete },
           sort: \FocusItem.order) private var activeItems: [FocusItem]

    @State private var isAddingTask = false
    @State private var newTaskText = ""
    @FocusState private var addFieldFocused: Bool

    private var topThree: [FocusItem] { Array(activeItems.prefix(3)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────
            HStack {
                Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // ── Top-3 items ──────────────────────────────────────
            if topThree.isEmpty && !isAddingTask {
                VStack(spacing: 8) {
                    Text("No tasks yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Button("Open task editor →") {
                        NotificationCenter.default.post(name: .showEditModal, object: nil)
                    }
                    .buttonStyle(.link)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(topThree) { item in
                        PriorityRowView(item: item)
                        if item.order < topThree.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }

                    // Inline add field
                    if isAddingTask {
                        if !topThree.isEmpty { Divider().padding(.leading, 44) }
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                                .frame(width: 20)
                            TextField("New task…", text: $newTaskText)
                                .textFieldStyle(.plain)
                                .focused($addFieldFocused)
                                .onSubmit { commitNewTask() }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }

            Divider()

            // ── Footer ───────────────────────────────────────────
            HStack(spacing: 4) {
                // Gear → Settings
                Button {
                    NotificationCenter.default.post(name: .showSettingsPanel, object: nil)
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Settings")

                Divider().frame(height: 14).padding(.horizontal, 4)

                // Edit
                Button("Edit") {
                    NotificationCenter.default.post(name: .showEditModal, object: nil)
                }
                .buttonStyle(.plain)
                .font(.callout)

                Spacer()

                // Add (+)
                Button {
                    isAddingTask = true
                    addFieldFocused = true
                } label: {
                    Image(systemName: "plus")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.plain)
                .help("Add task")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 320)
        .onChange(of: isAddingTask) { _, adding in
            if !adding { newTaskText = "" }
        }
    }

    private func commitNewTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { isAddingTask = false; return }
        store.addTask(text: trimmed, context: context)
        newTaskText = ""
        isAddingTask = false
    }
}
