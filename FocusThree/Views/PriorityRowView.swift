import SwiftUI
import SwiftData

struct PriorityRowView: View {
    @Environment(\.modelContext) private var context
    @Environment(FocusStore.self) private var store

    let item: FocusItem

    var body: some View {
        Button {
            store.completeTask(item, context: context)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)
                    .frame(width: 20)

                Text(item.text)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
