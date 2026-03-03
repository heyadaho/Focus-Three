import Combine
import SwiftUI
import SwiftData

struct PriorityRowView: View {
    @Environment(\.modelContext) private var context
    @Environment(FocusStore.self) private var store

    let item: FocusItem

    // Completion animation
    @State private var isCompleting = false
    @State private var strikethroughProgress: CGFloat = 0
    @State private var completionTask: Task<Void, Never>?

    // Inline editing
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    // Live timer tick
    @State private var now = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Computed

    private var elapsed: TimeInterval {
        TimeInterval(item.timeLoggedSeconds) +
            (item.timerStartedAt.map { now.timeIntervalSince($0) } ?? 0)
    }

    private var isTimerRunning: Bool { item.timerStartedAt != nil }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // ── Circle completion button ──────────────────────────
            Button {
                if isCompleting {
                    cancelCompletion()
                } else {
                    startCompletion()
                }
            } label: {
                Image(systemName: isCompleting ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleting ? .green : .secondary)
                    .font(.title3)
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // ── Task text (with strikethrough overlay) ────────────
            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .focused($fieldFocused)
                    .onSubmit { commitEdit() }
                    .onExitCommand { cancelEdit() }
            } else {
                Text(item.text)
                    .foregroundStyle(isCompleting ? .secondary : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(
                        GeometryReader { geo in
                            if isCompleting {
                                Rectangle()
                                    .fill(Color.primary.opacity(0.6))
                                    .frame(width: geo.size.width * strikethroughProgress,
                                           height: 1.5)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                    )
                    .gesture(
                        TapGesture(count: 2).onEnded {
                            guard !isCompleting else { return }
                            editText = item.text
                            isEditing = true
                            fieldFocused = true
                        }
                    )
            }

            // ── Timer button ──────────────────────────────────────
            if !isCompleting {
                Button {
                    if isTimerRunning {
                        store.pauseTimer(item, context: context)
                    } else {
                        store.startTimer(item, context: context)
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: isTimerRunning ? "clock.fill" : "clock")
                            .font(.caption)
                        // Always rendered to keep row height stable; invisible until used
                        Text(elapsed > 0 || isTimerRunning ? formatElapsed(elapsed) : "0s")
                            .font(.system(size: 8, design: .monospaced))
                            .lineLimit(1)
                            .opacity(elapsed > 0 || isTimerRunning ? 1 : 0)
                    }
                    .foregroundStyle(isTimerRunning ? Color.accentColor : .secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(isTimerRunning ? "Pause timer" : "Start timer")
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onReceive(ticker) { date in now = date }
    }

    // MARK: - Completion

    private func startCompletion() {
        isCompleting = true
        withAnimation(.linear(duration: 2)) {
            strikethroughProgress = 1.0
        }
        completionTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            store.completeTask(item, context: context)
        }
    }

    private func cancelCompletion() {
        completionTask?.cancel()
        completionTask = nil
        isCompleting = false
        withAnimation(.easeIn(duration: 0.15)) {
            strikethroughProgress = 0
        }
    }

    // MARK: - Editing

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { item.text = trimmed }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return "\(h)h\(m)m" }
        if m > 0 { return "\(m)m\(s)s" }
        return "\(s)s"
    }
}
