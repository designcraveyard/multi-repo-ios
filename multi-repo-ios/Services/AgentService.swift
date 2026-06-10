import Foundation

// MARK: - Agent Event

enum AgentEvent {
    case session(id: String, isNew: Bool)
    case agentThinking
    case toolCall(label: String)
    case textDelta(token: String)
    case pokemonCard(PokemonCardData)
    case evolutionCard(EvolutionCardData)
    case typeMatchupCard(TypeMatchupCardData)
    case teamCard(TeamCardData)
    case messageDone(fullText: String, agentName: String)
    case done
    case error(message: String)
}

// MARK: - Agent Service

final class AgentService: Sendable {
    static let shared = AgentService()

    // Internal so ChatSessionService and TranscribeService can read it
    var baseURL_internal: String { baseURL }

    private var baseURL: String {
        // 1. Check Xcode env var
        if let envURL = ProcessInfo.processInfo.environment["AGENT_BASE_URL"], !envURL.isEmpty {
            return envURL
        }
        // 2. Check Info.plist
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "AGENT_BASE_URL") as? String, !plistURL.isEmpty {
            return plistURL
        }
        // 3. Default → hosted Vercel deployment (works on simulator and device).
        //    Override via AGENT_BASE_URL (env var or Info.plist) to point at a
        //    local dev server, e.g. http://localhost:3000 for the simulator.
        return "https://multi-repo-nextjs.vercel.app"
    }

    private init() {}

    func send(message: String, sessionId: String?, jwt: String) -> AsyncStream<AgentEvent> {
        AsyncStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(self.baseURL)/api/chat") else {
                        continuation.yield(.error(message: "Invalid URL"))
                        continuation.finish()
                        return
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
                    request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
                    request.timeoutInterval = 120

                    var body: [String: Any] = ["message": message]
                    if let sid = sessionId { body["sessionId"] = sid }
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.yield(.error(message: "Server error"))
                        continuation.finish()
                        return
                    }

                    var currentEvent = ""

                    for try await line in bytes.lines {
                        if line.hasPrefix("event: ") {
                            currentEvent = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data: ") {
                            let dataStr = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                            guard let data = dataStr.data(using: .utf8) else { continue }

                            if let event = self.parseEvent(type: currentEvent, data: data) {
                                continuation.yield(event)
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.yield(.error(message: error.localizedDescription))
                    continuation.finish()
                }
            }
        }
    }

    func warmup(jwt: String) {
        Task {
            guard let url = URL(string: "\(baseURL)/api/chat") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    // MARK: - Private

    private func parseEvent(type: String, data: Data) -> AgentEvent? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        switch type {
        case "session":
            struct SessionPayload: Decodable { let sessionId: String; let isNew: Bool? }
            guard let payload = try? decoder.decode(SessionPayload.self, from: data) else { return nil }
            return .session(id: payload.sessionId, isNew: payload.isNew ?? true)

        case "agent_thinking":
            return .agentThinking

        case "tool_call":
            struct ToolPayload: Decodable { let label: String? }
            let payload = try? decoder.decode(ToolPayload.self, from: data)
            return .toolCall(label: payload?.label ?? "Working...")

        case "text_delta":
            struct DeltaPayload: Decodable { let token: String }
            guard let payload = try? decoder.decode(DeltaPayload.self, from: data) else { return nil }
            return .textDelta(token: payload.token)

        case "pokemon_card":
            guard let payload = try? decoder.decode(PokemonCardData.self, from: data) else { return nil }
            return .pokemonCard(payload)

        case "evolution_card":
            guard let payload = try? decoder.decode(EvolutionCardData.self, from: data) else { return nil }
            return .evolutionCard(payload)

        case "type_matchup_card":
            guard let payload = try? decoder.decode(TypeMatchupCardData.self, from: data) else { return nil }
            return .typeMatchupCard(payload)

        case "team_card":
            guard let payload = try? decoder.decode(TeamCardData.self, from: data) else { return nil }
            return .teamCard(payload)

        case "message_done":
            struct DonePayload: Decodable { let fullText: String; let agentName: String }
            guard let payload = try? decoder.decode(DonePayload.self, from: data) else { return nil }
            return .messageDone(fullText: payload.fullText, agentName: payload.agentName)

        case "done":
            return .done

        case "error":
            struct ErrorPayload: Decodable { let message: String? }
            let payload = try? decoder.decode(ErrorPayload.self, from: data)
            return .error(message: payload?.message ?? "Unknown error")

        default:
            return nil
        }
    }
}
