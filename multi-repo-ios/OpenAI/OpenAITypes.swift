//
//  OpenAITypes.swift
//  multi-repo-ios
//
//  Shared types for the OpenAI Transform and Transcribe service layer.
//
//  This file defines every data type, configuration struct, event enum,
//  and error type used across TransformService, TranscribeService, and
//  AppAudioRecorder. Keeping them in one file avoids circular imports
//  and makes it easy to see the full "shape" of the OpenAI integration.
//
//  Typical call chain:
//    TransformConfig (defines model + tools + handlers)
//      -> TransformService.stream(config:input:)
//        -> yields TransformStreamEvent values
//
//  For transcription:
//    AppAudioRecorder (captures audio Data)
//      -> TranscribeService.transcribe(audioData:)
//        -> returns TranscribeResult
//

import Foundation

// MARK: - Transform Config
// TransformConfig bundles everything needed for a single OpenAI Responses API call:
// the model, system prompt, tools the model may invoke, accepted input modalities,
// and a dictionary of ToolHandlers that execute tool calls locally.

/// Declares what kinds of user input a given transform config accepts.
/// Configs that accept `.image` can receive base64 or URL image content
/// alongside (or instead of) plain text.
enum TransformInputType: Hashable, Sendable {
    case text
    case image
}

/// A complete configuration for a single AI transform use-case (e.g. food logging, code review).
///
/// Each config is self-contained: it carries the model name, system prompt, the set of tools
/// the model may call, and — critically — the `toolHandlers` dictionary that maps tool names
/// to local Swift closures that execute those tools. This means adding a new feature only
/// requires creating a new `TransformConfig` value; no changes to `TransformService` itself.
///
/// Usage:
/// ```swift
/// let config = TransformConfig(id: "my-feature", systemPrompt: "...", tools: [...], toolHandlers: ["tool_name": handler])
/// let stream = TransformService.shared.stream(config: config, input: .init(text: userText))
/// ```
struct TransformConfig {
    let id: String                              // Unique identifier for this config (used for logging/analytics)
    let model: String                           // OpenAI model ID, e.g. "gpt-4o"
    let systemPrompt: String                    // System instructions sent as `instructions` in the Responses API
    let tools: [TransformTool]                  // Tools the model is allowed to invoke during generation
    let inputTypes: Set<TransformInputType>     // Declares accepted input modalities (text, image, or both)
    let maxOutputTokens: Int?                   // Optional cap on generated tokens (nil = model default)
    let temperature: Double?                    // Optional temperature override (nil = model default)
    let toolHandlers: [String: ToolHandler]     // Maps tool name -> async closure that executes the tool locally

    init(
        id: String,
        model: String = OpenAIConfig.defaultModel,
        systemPrompt: String,
        tools: [TransformTool] = [],
        inputTypes: Set<TransformInputType> = [.text],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        toolHandlers: [String: ToolHandler] = [:]
    ) {
        self.id = id
        self.model = model
        self.systemPrompt = systemPrompt
        self.tools = tools
        self.inputTypes = inputTypes
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
        self.toolHandlers = toolHandlers
    }
}

// MARK: - Tool Types
// Tools represent capabilities the model can invoke during generation.
// `ToolHandler` is the local closure signature; `TransformTool` describes
// the tool schema sent to the API.

/// A closure that receives the JSON arguments string from the model's function call
/// and returns a JSON result string. Marked `@Sendable` because it runs inside
/// a structured `Task` in TransformService and may cross actor boundaries.
///
/// Pattern: each config file (e.g. FoodLoggerConfig) defines static ToolHandler
/// closures and registers them in the `toolHandlers` dictionary by tool name.
/// TransformService looks up and invokes the matching handler when the model
/// emits a function_call. Errors thrown here are caught and sent back to the
/// model as `{"error": "..."}` so it can retry or report gracefully.
typealias ToolHandler = @Sendable (String) async throws -> String

/// Describes a tool the model may invoke. Each case maps to an OpenAI tool type.
/// The `.function` case is the most common — it defines a custom tool with a JSON
/// Schema `parameters` dict that tells the model what arguments to provide.
///
/// `toJSON()` serializes the tool into the format expected by the Responses API
/// request body's `tools` array.
enum TransformTool {
    case webSearchPreview
    case codeInterpreter
    case fileSearch(vectorStoreIds: [String])
    case function(name: String, description: String, parameters: [String: Any])

    func toJSON() -> [String: Any] {
        switch self {
        case .webSearchPreview:
            return ["type": "web_search_preview"]
        case .codeInterpreter:
            return ["type": "code_interpreter"]
        case .fileSearch(let ids):
            return ["type": "file_search", "vector_store_ids": ids]
        case .function(let name, let description, let parameters):
            return [
                "type": "function",
                "name": name,
                "description": description,
                "parameters": parameters,
                "strict": true,
            ]
        }
    }
}

// MARK: - Stream Events
// These events are yielded by TransformService's AsyncThrowingStream as the
// server-sent event (SSE) stream is parsed in real time. Callers (typically
// a ViewModel) switch on these to update the UI incrementally.

/// Events emitted during a streaming transform. Callers typically handle:
/// - `.textDelta` — append text to the displayed output (arrives in small chunks)
/// - `.functionCallStart/Delta/Done` — optionally show tool-call progress in the UI
/// - `.error` — display an inline error (non-fatal; the stream may continue)
/// - `.done` — the entire response is complete, safe to finalize UI state
enum TransformStreamEvent {
    case textDelta(String)
    case functionCallStart(callId: String, name: String)
    case functionCallDelta(callId: String, delta: String)
    case functionCallDone(callId: String, name: String, arguments: String)
    case imageUrl(String)
    case error(String)
    case done
}

// MARK: - Transform Input
// Encapsulates user-provided content for a transform call. At least one of
// `text` or `imageUrl` should be non-nil. TransformService converts this
// into the Responses API `input` message array with the appropriate content types.

/// User input for a transform call. Supports text, image, or both simultaneously.
/// The `imageUrl` can be a remote URL or a base64 data URI (data:image/png;base64,...).
struct TransformInput {
    let text: String?
    let imageUrl: String?

    init(text: String? = nil, imageUrl: String? = nil) {
        self.text = text
        self.imageUrl = imageUrl
    }
}

// MARK: - Transcribe Result
// Returned by TranscribeService after a successful Whisper API call.
// Uses `verbose_json` response format to get language and duration metadata
// alongside the transcript text.

/// The result of a Whisper transcription. `language` and `duration` are optional
/// because they come from the `verbose_json` response format extras.
struct TranscribeResult {
    let text: String
    let language: String?
    let duration: Double?
}

// MARK: - Errors
// Typed error enums for each service layer. All conform to LocalizedError so
// callers can display `error.localizedDescription` directly in the UI.
// Separate enums (TransformServiceError, TranscribeServiceError, AudioRecorderError)
// keep error domains isolated and make catch-site pattern matching precise.

/// Errors from TransformService — covers API failures, config issues,
/// tool execution failures, SSE stream parsing errors, and bad input.
enum TransformServiceError: LocalizedError {
    case apiError(String)
    case configError(String)
    case toolError(String)
    case streamError(String)
    case inputError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return "API error: \(msg)"
        case .configError(let msg): return "Config error: \(msg)"
        case .toolError(let msg): return "Tool error: \(msg)"
        case .streamError(let msg): return "Stream error: \(msg)"
        case .inputError(let msg): return "Input error: \(msg)"
        }
    }
}

/// Errors from TranscribeService — covers HTTP/API failures and response parsing issues.
enum TranscribeServiceError: LocalizedError {
    case apiError(String)
    case formatError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return "API error: \(msg)"
        case .formatError(let msg): return "Format error: \(msg)"
        }
    }
}

/// Errors from AppAudioRecorder — covers microphone permission denial,
/// recording hardware/session failures, and attempts to stop when no recording exists.
enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case recordingFailed(String)
    case noRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Microphone permission denied"
        case .recordingFailed(let msg): return "Recording failed: \(msg)"
        case .noRecording: return "No recording available"
        }
    }
}
