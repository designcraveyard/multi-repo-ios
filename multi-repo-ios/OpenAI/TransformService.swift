//
//  TransformService.swift
//  multi-repo-ios
//
//  Streaming transform service using the OpenAI Responses API.
//
//  This is the core engine of the OpenAI integration. It takes a TransformConfig
//  (which defines the model, system prompt, tools, and tool handlers) plus user input,
//  and returns an AsyncThrowingStream of TransformStreamEvent values that the caller
//  can iterate to build a real-time UI.
//
//  Key design decisions:
//
//  1. **Streaming via SSE**: The Responses API returns server-sent events (SSE).
//     Each line prefixed with "data: " carries a JSON event. This service parses
//     those lines in real time and yields typed TransformStreamEvent values.
//
//  2. **Transparent tool-call loop**: When the model emits function_call events,
//     this service automatically invokes the matching ToolHandler from the config,
//     sends the results back using `previous_response_id` to continue the conversation,
//     and loops until the model produces a final text response. Callers never need
//     to manage tool-call round-trips themselves.
//
//  3. **Singleton pattern**: Matches OpenAIManager and SupabaseManager. No instance
//     state is held between calls — each `stream()` invocation is independent.
//

import Foundation

// MARK: - TransformService

/// Singleton service that streams AI-generated transforms via the OpenAI Responses API.
/// Callers provide a `TransformConfig` and `TransformInput`, then iterate the returned
/// `AsyncThrowingStream<TransformStreamEvent, Error>` to receive real-time text deltas,
/// tool-call progress events, and completion signals.
@MainActor
final class TransformService {
    static let shared = TransformService()

    private init() {}

    // MARK: - Public API
    // The only public entry point. Returns an AsyncThrowingStream that the caller
    // iterates with `for try await event in stream { ... }`. The stream completes
    // when the model finishes (yielding `.done`) or throws on unrecoverable errors.

    /// Starts a streaming transform and returns events as they arrive.
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
                    try await self.runStream(config: config, input: input, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Stream Execution
    // This is the heart of the service. It runs a while-true loop that:
    //   1. Builds the request body (user input on first iteration, tool outputs on subsequent ones)
    //   2. Sends a streaming POST to the Responses API
    //   3. Parses each SSE line and yields TransformStreamEvent values
    //   4. If the model made function calls, invokes the local handlers and loops back to step 1
    //   5. If no function calls were made, yields `.done` and breaks out
    //
    // The `previous_response_id` parameter is critical for the tool-call loop: it tells
    // the API "this is a continuation of that response — here are the tool outputs".
    // Without it, the model would lose context of what it asked for.

    private func runStream(
        config: TransformConfig,
        input: TransformInput,
        continuation: AsyncThrowingStream<TransformStreamEvent, Error>.Continuation
    ) async throws {
        var previousResponseId: String?  // Set after each response.completed event; used to chain tool-call rounds
        var toolOutputs: [[String: Any]]?  // Non-nil when we're sending tool results back to the model

        // Tool-call loop: keeps running as long as the model requests function calls.
        // Typically runs once (no tools) or twice (one round of tool calls). In theory
        // the model could chain multiple rounds, so we loop indefinitely until it
        // produces a final text response with no pending function calls.
        while true {
            // --- Build request body ---
            // On the first iteration: sends user input as `input` messages.
            // On subsequent iterations (tool-call loop): sends tool outputs as `input`
            // with `previous_response_id` so the API knows this continues the prior response.
            var body: [String: Any] = [
                "model": config.model,
                "instructions": config.systemPrompt,
                "stream": true,                          // Always stream — we parse SSE events
            ]

            if let toolOutputs {
                // Continuation round: send function_call_output items back to the model
                body["input"] = toolOutputs
                body["previous_response_id"] = previousResponseId
            } else if previousResponseId == nil {
                // First round: send the user's text/image input
                body["input"] = buildInputMessages(input)
            }

            // Attach optional config parameters only when set (avoids sending null values)
            if !config.tools.isEmpty {
                body["tools"] = config.tools.map { $0.toJSON() }
            }
            if let maxTokens = config.maxOutputTokens {
                body["max_output_tokens"] = maxTokens
            }
            if let temp = config.temperature {
                body["temperature"] = temp
            }

            // --- Send the streaming request ---
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            let request = OpenAIManager.shared.makeRequest(path: "responses", body: jsonData)

            // Uses URLSession.shared (not OpenAIManager.session) because `bytes(for:)`
            // needs the default delegate chain. Auth headers are already set on the request.
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw TransformServiceError.apiError("HTTP \(statusCode)")
            }

            // --- Parse SSE stream ---
            // `pendingCalls` accumulates function call arguments as they stream in.
            // Key = call_id (from the API), Value = (tool name, accumulated args JSON string).
            var pendingCalls: [String: (name: String, args: String)] = [:]
            var hasFunctionCalls = false

            // Iterate each line of the SSE stream. The Responses API sends lines like:
            //   data: {"type":"response.output_text.delta","delta":"Hello"}
            //   data: [DONE]
            // Non-data lines (e.g. blank lines, "event:" lines) are skipped.
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }  // Skip non-data SSE lines
                let jsonStr = String(line.dropFirst(6))            // Strip "data: " prefix
                if jsonStr == "[DONE]" { break }                   // End-of-stream sentinel

                // Parse the JSON event. If parsing fails, skip silently — the API may send
                // events we don't handle (e.g. rate_limits.updated) and that's fine.
                guard let lineData = jsonStr.data(using: .utf8),
                      let event = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                      let eventType = event["type"] as? String else { continue }

                switch eventType {

                // --- Text output: the model is generating text tokens ---
                case "response.output_text.delta":
                    if let delta = event["delta"] as? String {
                        continuation.yield(.textDelta(delta))
                    }

                // --- Function call started: the model wants to invoke a tool ---
                // Register the call in pendingCalls so we can accumulate its arguments.
                case "response.output_item.added":
                    if let item = event["item"] as? [String: Any],
                       item["type"] as? String == "function_call",
                       let callId = item["call_id"] as? String,
                       let name = item["name"] as? String {
                        continuation.yield(.functionCallStart(callId: callId, name: name))
                        pendingCalls[callId] = (name: name, args: "")
                        hasFunctionCalls = true
                    }

                // --- Function call arguments streaming in ---
                // The model sends argument chunks incrementally; we accumulate them.
                // Note: the API may use either "call_id" or "item_id" depending on the event,
                // so we check both with a fallback chain.
                case "response.function_call_arguments.delta":
                    let callId = (event["call_id"] as? String) ?? (event["item_id"] as? String) ?? ""
                    if let delta = event["delta"] as? String {
                        continuation.yield(.functionCallDelta(callId: callId, delta: delta))
                        if var pending = pendingCalls[callId] {
                            pending.args += delta
                            pendingCalls[callId] = pending
                        }
                    }

                // --- Function call arguments complete ---
                // Replace the accumulated args with the final complete string from the API
                // (more reliable than our incremental accumulation).
                case "response.function_call_arguments.done":
                    let callId = (event["call_id"] as? String) ?? (event["item_id"] as? String) ?? ""
                    if let args = event["arguments"] as? String, let pending = pendingCalls[callId] {
                        pendingCalls[callId] = (name: pending.name, args: args)
                        continuation.yield(.functionCallDone(callId: callId, name: pending.name, arguments: args))
                    }

                // --- Response complete: capture the response ID for potential tool-call continuation ---
                case "response.completed":
                    if let resp = event["response"] as? [String: Any],
                       let id = resp["id"] as? String {
                        previousResponseId = id
                    }

                default:
                    break  // Ignore unhandled event types (rate_limits, metadata, etc.)
                }
            }

            // --- Handle tool calls ---
            // If the model requested any function calls, execute them locally using the
            // ToolHandler closures registered in the config, then loop back to send the
            // results to the API. This is the "tool-call loop" — it continues until the
            // model produces a response with no function calls.
            if hasFunctionCalls && !pendingCalls.isEmpty {
                var results: [[String: Any]] = []
                for (callId, call) in pendingCalls {
                    if let handler = config.toolHandlers[call.name] {
                        do {
                            // Invoke the local tool handler with the model's JSON arguments.
                            // The handler is async and may make network calls (e.g. USDA API).
                            let result = try await handler(call.args)
                            results.append([
                                "type": "function_call_output",
                                "call_id": callId,
                                "output": result,
                            ])
                        } catch {
                            // On tool failure: yield an error event for the UI, but still
                            // send an error output back to the model so it can handle gracefully
                            // (e.g. tell the user the lookup failed) rather than hanging.
                            continuation.yield(.error("Tool '\(call.name)' error: \(error.localizedDescription)"))
                            results.append([
                                "type": "function_call_output",
                                "call_id": callId,
                                "output": "{\"error\": \"\(error.localizedDescription)\"}",
                            ])
                        }
                    }
                }
                // Store tool outputs and loop back to send them with previous_response_id
                toolOutputs = results
                continue
            }

            // No function calls in this response — the model is done generating.
            continuation.yield(.done)
            break
        }
    }

    // MARK: - Helpers
    // Converts the typed TransformInput into the Responses API `input` message array.
    // Supports text-only, image-only, or mixed text+image content in a single user message.

    /// Builds the `input` array for the Responses API request body.
    /// Creates a single user message with one or both content parts (input_text, input_image).
    private func buildInputMessages(_ input: TransformInput) -> [[String: Any]] {
        var content: [[String: String]] = []
        if let text = input.text {
            content.append(["type": "input_text", "text": text])
        }
        if let imageUrl = input.imageUrl {
            content.append(["type": "input_image", "image_url": imageUrl])
        }
        return [["role": "user", "content": content] as [String: Any]]
    }
}
