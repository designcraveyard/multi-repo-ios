//
//  OpenAIConfig.swift
//  multi-repo-ios
//
//  API configuration constants for OpenAI and third-party services.
//
//  This file follows the same env-var-override pattern used by SupabaseManager/Config:
//  each secret is read from a Xcode scheme environment variable first, falling back to
//  a compiled-in value from `OpenAISecrets.swift` (which is gitignored). This lets
//  developers override keys per-scheme (e.g. staging vs production) without touching code,
//  while keeping a convenient default for local development.
//
//  To set env vars: Edit Scheme -> Run -> Arguments -> Environment Variables.
//
//  The `enum` (not `struct`/`class`) prevents accidental instantiation — this is a
//  pure namespace for static constants, matching the SupabaseConfig pattern.
//

import Foundation

// MARK: - OpenAIConfig
// Namespace for all OpenAI-related configuration. Uses `static let` with closures
// so each value is computed exactly once at first access and cached for the process lifetime.

enum OpenAIConfig {
    // MARK: API Keys
    // Each key uses the pattern: env var -> compiled-in fallback.
    // `OpenAISecrets` is a separate gitignored file that holds default keys
    // so they never appear in version control.

    /// OpenAI API key. Used by OpenAIManager for Authorization headers.
    /// Override via OPENAI_API_KEY env var in the Xcode scheme.
    static let apiKey: String = {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? OpenAISecrets.apiKey
    }()

    /// USDA FoodData Central API key. Used by FoodLoggerConfig's food_search tool handler.
    /// Override via USDA_API_KEY env var in the Xcode scheme.
    static let usdaApiKey: String = {
        ProcessInfo.processInfo.environment["USDA_API_KEY"]
            ?? OpenAISecrets.usdaApiKey
    }()

    // MARK: Endpoints & Defaults

    /// Base URL for all OpenAI REST API calls. OpenAIManager appends specific paths
    /// (e.g. "/responses", "/audio/transcriptions") to this.
    static let baseURL = "https://api.openai.com/v1"

    /// Default model for transform configs. Individual TransformConfig instances can
    /// override this by passing a different `model` to their init.
    static let defaultModel = "gpt-4o"

    /// Model used by TranscribeService for speech-to-text. Whisper-1 is currently
    /// the only model available on OpenAI's transcription endpoint.
    static let whisperModel = "whisper-1"
}
