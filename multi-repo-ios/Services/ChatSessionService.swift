import Foundation

// MARK: - Chat Session Summary

struct ChatSessionSummary: Codable, Identifiable {
    let id: String
    let title: String?
    let status: String
    let activeAgent: String?
    let messageCount: Int
    let lastMessageAt: String
    let startedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case activeAgent = "active_agent"
        case messageCount = "message_count"
        case lastMessageAt = "last_message_at"
        case startedAt = "started_at"
    }
}

// MARK: - Chat Message Record

struct ChatMessageRecord: Codable, Identifiable {
    let id: String
    let role: String
    let content: String?
    let agentName: String?
    let toolCalls: ToolCallsPayload?
    let createdAt: String
    let sequenceNumber: Int

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case agentName = "agent_name"
        case toolCalls = "tool_calls"
        case createdAt = "created_at"
        case sequenceNumber = "sequence_number"
    }
}

struct ToolCallsPayload: Codable {
    let pokemonCards: [PokemonCardData]?
    let evolutionCards: [EvolutionCardData]?
    let typeMatchupCards: [TypeMatchupCardData]?
    let teamCards: [TeamCardData]?
}

// MARK: - Chat Session Service

final class ChatSessionService: Sendable {
    static let shared = ChatSessionService()
    private init() {}

    private var baseURL: String { AgentService.shared.baseURL_internal }

    func listSessions(jwt: String) async throws -> [ChatSessionSummary] {
        guard let url = URL(string: "\(baseURL)/api/chat/sessions") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ChatSessionSummary].self, from: data)
    }

    func loadMessages(sessionId: String, jwt: String) async throws -> [ChatMessageRecord] {
        guard let url = URL(string: "\(baseURL)/api/chat/sessions/\(sessionId)/messages") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ChatMessageRecord].self, from: data)
    }

    func deleteSession(sessionId: String, jwt: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/chat/sessions/\(sessionId)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        _ = try await URLSession.shared.data(for: request)
    }
}
