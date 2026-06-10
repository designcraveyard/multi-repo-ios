//
//  TransformService.swift
//  multi-repo-ios
//
//  Text-transform service backed by the `ai-transform` Supabase Edge Function.
//
//  History: this service previously streamed directly from the OpenAI Responses API
//  using a client-side API key (with a transparent tool-call loop). That exposed the
//  key inside the shipped binary, so all OpenAI calls now go through the JWT-protected
//  edge function — the key lives only in Supabase function secrets.
//
//  Public API is unchanged: callers still receive an
//  `AsyncThrowingStream<TransformStreamEvent, Error>` and iterate events. The edge
//  function is request/response (not streaming), so the stream yields a single
//  `.textDelta` with the full result followed by `.done`. Existing call-sites
//  (AppMarkdownEditor AI toolbar, AIDemoView) work without modification.
//
//  The config's `systemPrompt` is sent as the edge function's `custom` action prompt,
//  so every TransformConfig keeps working. Client-side tool handlers are no longer
//  supported — tools must be implemented server-side (see lib/agents on web for the
//  tool-calling pattern, or the /api/chat agent graph for streaming + tools).
//

import Foundation
import Supabase

// MARK: - TransformService

/// Singleton service that transforms text via the `ai-transform` edge function.
/// Callers provide a `TransformConfig` and `TransformInput`, then iterate the returned
/// `AsyncThrowingStream<TransformStreamEvent, Error>` for the result and completion.
@MainActor
final class TransformService {
    static let shared = TransformService()

    private init() {}

    // MARK: - Public API

    /// Starts a transform and returns events as a stream (single result + done).
    ///
    /// Usage:
    /// ```swift
    /// let stream = TransformService.shared.stream(config: myConfig, input: .init(text: "Hello"))
    /// for try await event in stream {
    ///     switch event {
    ///     case .textDelta(let chunk): output += chunk
    ///     case .done: break
    ///     default: break
    ///     }
    /// }
    /// ```
    func stream(config: TransformConfig, input: TransformInput) -> AsyncThrowingStream<TransformStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let result = try await self.transform(config: config, input: input)
                    continuation.yield(.textDelta(result))
                    continuation.yield(.done)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Edge Function Call

    /// Performs the actual `ai-transform` request and returns the transformed text.
    ///
    /// The edge function accepts `{ text, action, customPrompt? }` where action is one
    /// of summarize/keypoints/rewrite/custom. We always send `custom` with the config's
    /// system prompt — this preserves the full flexibility of TransformConfig presets.
    private func transform(config: TransformConfig, input: TransformInput) async throws -> String {
        guard let text = input.text, !text.isEmpty else {
            throw TransformServiceError.apiError("Transform input requires text")
        }

        // The edge function enforces verify_jwt — a valid signed-in session is required.
        let session = try await SupabaseManager.shared.client.auth.session

        let url = SupabaseManager.shared.supabaseURL
            .appendingPathComponent("functions/v1/ai-transform")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "text": text,
            "action": "custom",
            "customPrompt": config.systemPrompt,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransformServiceError.apiError("Invalid response")
        }
        guard httpResponse.statusCode == 200 else {
            // Edge function errors come back as { error, code } JSON — surface the message.
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TransformServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? String else {
            throw TransformServiceError.streamError("Cannot parse transform response")
        }

        return result
    }
}
