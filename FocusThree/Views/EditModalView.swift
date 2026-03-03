import SwiftUI
import SwiftData

struct EditModalView: View {
    @Environment(\.modelContext) private var context
    @Environment(FocusStore.self) private var store

    @Query(filter: #Predicate<FocusItem> { !$0.isComplete },
           sort: \FocusItem.order) private var activeItems: [FocusItem]

    @Query(filter: #Predicate<FocusItem> { $0.isComplete },
           sort: \FocusItem.archivedAt,
           order: .reverse) private var archivedItems: [FocusItem]

    @State private var selectedTab: Tab = .tasks
    @State private var newTaskText = ""
    @FocusState private var addFieldFocused: Bool

    enum Tab { case tasks, archive }

    var body: some View {
        VStack(spacing: 0) {
            // ── Tab bar ──────────────────────────────────────────
            HStack(spacing: 0) {
                tabButton("Tasks", tab: .tasks)
                tabButton("Archive", tab: .archive)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            // ── Content ──────────────────────────────────────────
            Group {
                if selectedTab == .tasks {
                    tasksTab
                } else {
                    archiveTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 480, height: 520)
    }

    // MARK: - Tasks tab

    private var tasksTab: some View {
        VStack(spacing: 0) {
            if activeItems.isEmpty {
                emptyState(message: "No tasks yet. Add one below.")
            } else {
                List {
                    Section {
                        ForEach(Array(activeItems.enumerated()), id: \.element.id) { index, item in
                            // Inject "Upcoming tasks" divider at the first item with order ≥ 3
                            VStack(spacing: 0) {
                                if item.order >= 3 && (index == 0 || activeItems[index - 1].order < 3) {
                                    HStack {
                                        Text("Upcoming tasks")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.top, 16)
                                    .padding(.bottom, 6)
                                    Divider()
                                }
                                EditTaskRowView(item: item) {
                                    store.deleteTask(item, context: context)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                        }
                        .onMove { from, to in
                            store.moveItems(from: from, to: to,
                                            items: activeItems,
                                            context: context)
                        }
                    } header: {
                        Text("Top 3 — shown in menu bar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // Add-task row
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
                    .font(.body)
                TextField("Add a task…", text: $newTaskText)
                    .textFieldStyle(.plain)
                    .focused($addFieldFocused)
                    .onSubmit { commitAdd() }
                if !newTaskText.isEmpty {
                    Button("Add") { commitAdd() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Archive tab

    private var archiveTab: some View {
        VStack(spacing: 0) {
            if archivedItems.isEmpty {
                emptyState(message: "Completed tasks will appear here.")
            } else {
                List(archivedItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.text)
                                .lineLimit(1)
                            HStack(spacing: 8) {
                                if let date = item.archivedAt {
                                    Text("Completed \(date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                if item.timeLoggedSeconds > 0 {
                                    Text("· \(formatDuration(item.timeLoggedSeconds))")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Spacer()
                        Button {
                            store.reopenTask(item, context: context)
                        } label: {
                            Image(systemName: "arrow.uturn.backward.circle")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Restore to upcoming list")

                        Button {
                            store.deleteTask(item, context: context)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Delete permanently")
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.inset)

                Divider()

                HStack {
                    Spacer()
                    Button("Clear All", role: .destructive) {
                        store.clearArchive(archivedItems, context: context)
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Helpers

    private func emptyState(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundStyle(.secondary)
                .font(.callout)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func tabButton(_ label: String, tab: Tab) -> some View {
        Button(label) { selectedTab = tab }
            .buttonStyle(.plain)
            .font(.callout.weight(selectedTab == tab ? .semibold : .regular))
            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                selectedTab == tab
                    ? AnyShapeStyle(.quinary)
                    : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 6)
            )
    }

    private func commitAdd() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addTask(text: trimmed, context: context)
        newTaskText = ""
        addFieldFocused = true
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}

// MARK: - Editable task row

private struct EditTaskRowView: View {
    @Environment(\.modelContext) private var context
    let item: FocusItem
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .font(.caption)
                .frame(width: 16)

            // Task text / inline editor
            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .focused($fieldFocused)
                    .onSubmit { commitEdit() }
                    .onExitCommand { cancelEdit() }
            } else {
                Text(item.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gesture(TapGesture(count: 2).onEnded {
                        editText = item.text
                        isEditing = true
                        fieldFocused = true
                    })
            }

            // Delete
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Delete")
        }
        .padding(.vertical, 8)
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { item.text = trimmed }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }
}
