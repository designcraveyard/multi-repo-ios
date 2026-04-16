import SwiftUI

// MARK: - Chat History View
// Sheet showing past sessions with swipe-to-delete and session loading.

struct ChatHistoryView: View {
    // --- Props
    let sessions: [ChatSessionSummary]
    let onSelect: (ChatSessionSummary) -> Void
    let onDelete: (String) -> Void
    let onNewChat: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "bubble.left.and.text.bubble.right",
                        description: Text("Your past conversations will appear here.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(sessions) { session in
                        Button {
                            onSelect(session)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: .space1) {
                                Text(session.title ?? "New chat")
                                    .font(.appBodyMediumEm)
                                    .foregroundStyle(Color.typographyPrimary)
                                    .lineLimit(1)

                                HStack(spacing: .space2) {
                                    Text(relativeTime(from: session.lastMessageAt))
                                        .font(.appCaptionSmall)
                                        .foregroundStyle(Color.typographyMuted)

                                    Text("·")
                                        .font(.appCaptionSmall)
                                        .foregroundStyle(Color.typographyMuted)

                                    Text("\(session.messageCount) messages")
                                        .font(.appCaptionSmall)
                                        .foregroundStyle(Color.typographyMuted)
                                }
                            }
                            .padding(.vertical, .space1)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDelete(session.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.surfacesBasePrimary)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New Chat") {
                        onNewChat()
                        dismiss()
                    }
                    .font(.appBodyMediumEm)
                    .foregroundStyle(Color.surfacesBrandInteractive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.appBodyMediumEm)
                    .foregroundStyle(Color.surfacesBrandInteractive)
                }
            }
        }
    }

    // MARK: - Helpers

    private func relativeTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: isoString) else { return "" }
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChatHistoryView(
        sessions: [],
        onSelect: { _ in },
        onDelete: { _ in },
        onNewChat: {}
    )
}
