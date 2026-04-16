import SwiftUI
import Supabase

// MARK: - Chat Message

enum ChatMessage: Identifiable {
    case user(id: UUID = UUID(), text: String)
    case aiText(id: UUID = UUID(), markdown: String)
    case aiEvent(id: UUID = UUID(), label: String)
    case aiPokemonCard(id: UUID = UUID(), data: PokemonCardData)
    case aiEvolutionCard(id: UUID = UUID(), data: EvolutionCardData)
    case aiTypeMatchupCard(id: UUID = UUID(), data: TypeMatchupCardData)
    case aiTeamCard(id: UUID = UUID(), data: TeamCardData)

    var id: UUID {
        switch self {
        case .user(let id, _):           return id
        case .aiText(let id, _):         return id
        case .aiEvent(let id, _):        return id
        case .aiPokemonCard(let id, _):  return id
        case .aiEvolutionCard(let id, _): return id
        case .aiTypeMatchupCard(let id, _): return id
        case .aiTeamCard(let id, _):     return id
        }
    }
}

// MARK: - Chat ViewModel

@Observable @MainActor
final class ChatViewModel {
    // --- State
    var messages: [ChatMessage] = []
    var sessionId: String?
    var isStreaming = false
    var historySessions: [ChatSessionSummary] = []
    var streamToken: Int = 0

    // --- Private
    private var textBuffer = ""
    private var currentTextId: UUID?
    private var deltaCount = 0

    // MARK: - Send

    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isStreaming else { return }

        seedMessages(for: text)
        isStreaming = true
        textBuffer = ""
        deltaCount = 0

        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            appendError("Session expired. Please sign in again.")
            isStreaming = false
            return
        }
        let jwt = session.accessToken

        for await event in AgentService.shared.send(message: text, sessionId: sessionId, jwt: jwt) {
            handleEvent(event)
        }

        isStreaming = false
    }

    func seedMessages(for text: String) {
        let textId = UUID()
        currentTextId = textId
        messages.append(.user(text: text))
        messages.append(.aiEvent(label: "Thinking..."))
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: AgentEvent) {
        switch event {
        case .session(let id, _):
            sessionId = id

        case .agentThinking:
            updateLastEvent("Thinking...")

        case .toolCall(let label):
            updateLastEvent(label)

        case .textDelta(let token):
            textBuffer += token
            deltaCount += 1

            // Replace event pill with text bubble, or update existing text bubble
            if let idx = messages.lastIndex(where: {
                if case .aiEvent = $0 { return true }
                if case .aiText(let id, _) = $0, id == currentTextId { return true }
                return false
            }) {
                messages[idx] = .aiText(id: currentTextId ?? UUID(), markdown: textBuffer)
            }

            streamToken += 1

            // Haptic every 5th token
            if deltaCount % 5 == 0 {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }

        case .pokemonCard(let data):
            withAnimation { messages.append(.aiPokemonCard(data: data)) }

        case .evolutionCard(let data):
            withAnimation { messages.append(.aiEvolutionCard(data: data)) }

        case .typeMatchupCard(let data):
            withAnimation { messages.append(.aiTypeMatchupCard(data: data)) }

        case .teamCard(let data):
            withAnimation { messages.append(.aiTeamCard(data: data)) }

        case .messageDone(let fullText, _):
            if let idx = messages.lastIndex(where: {
                if case .aiText(let id, _) = $0, id == currentTextId { return true }
                return false
            }) {
                messages[idx] = .aiText(id: currentTextId ?? UUID(), markdown: fullText)
            }
            textBuffer = ""

        case .done:
            isStreaming = false

        case .error(let message):
            appendError(message)
        }
    }

    private func updateLastEvent(_ label: String) {
        if let idx = messages.lastIndex(where: { if case .aiEvent = $0 { return true }; return false }) {
            messages[idx] = .aiEvent(label: label)
        }
    }

    private func appendError(_ message: String) {
        withAnimation { messages.append(.aiText(markdown: "Error: \(message)")) }
    }

    // MARK: - History

    func loadHistory() async {
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
            historySessions = try await ChatSessionService.shared.listSessions(jwt: session.accessToken)
        } catch {
            print("[ChatViewModel] Failed to load history: \(error)")
        }
    }

    func loadSession(_ summary: ChatSessionSummary) async {
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
            let records = try await ChatSessionService.shared.loadMessages(
                sessionId: summary.id,
                jwt: session.accessToken
            )
            sessionId = summary.id
            messages = records.compactMap { record in
                guard let content = record.content else { return nil }
                if record.role == "user" {
                    return .user(text: content)
                } else {
                    return .aiText(markdown: content)
                }
            }
        } catch {
            print("[ChatViewModel] Failed to load session: \(error)")
        }
    }

    func deleteSession(_ id: String) async {
        historySessions.removeAll { $0.id == id }
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
            try await ChatSessionService.shared.deleteSession(sessionId: id, jwt: session.accessToken)
        } catch {
            print("[ChatViewModel] Failed to delete session: \(error)")
        }
    }

    func newChat() {
        messages = []
        sessionId = nil
        textBuffer = ""
        currentTextId = nil
        deltaCount = 0
    }
}
