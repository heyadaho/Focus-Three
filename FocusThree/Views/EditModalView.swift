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
                    // Top-3 section
                    if activeItems.count > 0 {
                        Section {
                            ForEach(activeItems.prefix(3)) { item in
                                taskRow(item)
                            }
                            .onMove { from, to in
                                store.moveItems(from: from, to: to,
                                                items: Array(activeItems.prefix(3)),
                                                context: context)
                            }
                        } header: {
                            Text("Top 3 — shown in menu bar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }

                    // Remaining tasks
                    if activeItems.count > 3 {
                        Section {
                            ForEach(activeItems.dropFirst(3)) { item in
                                taskRow(item)
                            }
                            .onMove { from, to in
                                // Offset indices to account for the prefix(3) section.
                                let offset = IndexSet(from.map { $0 + 3 })
                                store.moveItems(from: offset, to: to + 3,
                                                items: activeItems,
                                                context: context)
                            }
                        } header: {
                            Text("Other tasks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
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
        Group {
            if archivedItems.isEmpty {
                emptyState(message: "Completed tasks will appear here.")
            } else {
                List(archivedItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.text)
                                .lineLimit(1)
                            if let date = item.archivedAt {
                                Text("Completed \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
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
                        .help("Restore to top of list")

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
            }
        }
    }

    // MARK: - Helpers

    private func taskRow(_ item: FocusItem) -> some View {
        HStack {
            Text(item.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                store.deleteTask(item, context: context)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Delete")
        }
        .padding(.vertical, 2)
    }

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
}
