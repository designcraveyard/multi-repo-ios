//
//  OpenAIManager.swift
//  multi-repo-ios
//
//  Singleton that owns the URLSession and request-builder methods for all
//  OpenAI API calls. Mirrors the SupabaseManager.swift pattern used elsewhere
//  in this project: one shared instance, private init, preconfigured session.
//
//  Design rationale:
//  - A single URLSession lets the OS reuse HTTP/2 connections across calls.
//  - `httpAdditionalHeaders` on the session config automatically injects the
//    Authorization and Content-Type headers into every request made through
//    `session`, so callers don't need to set them manually.
//  - Two factory methods (`makeRequest` and `makeMultipartRequest`) cover the
//    two request shapes used by this layer: JSON body (TransformService) and
//    multipart/form-data body (TranscribeService).
//
//  Usage:
//    let req = OpenAIManager.shared.makeRequest(path: "responses", body: jsonData)
//    let (bytes, resp) = try await URLSession.shared.bytes(for: req)
//

import Foundation

// MARK: - OpenAIManager

/// Singleton that configures and vends URLRequests for the OpenAI REST API.
/// Marked `@MainActor` to match the project's default actor isolation
/// (`SWIFT_APPROACHABLE_CONCURRENCY = YES`). The underlying URLSession work
/// is non-blocking — URLSession dispatches networking off the main thread internally.
@MainActor
final class OpenAIManager {
    static let shared = OpenAIManager()

    /// Pre-configured session with Authorization and Content-Type headers baked in.
    /// Used directly for simple calls; for streaming, callers may use `URLSession.shared`
    /// with a request from `makeRequest(path:body:)` instead (since `bytes(for:)` needs
    /// the default session's delegate chain).
    let session: URLSession

    /// Private init enforces the singleton pattern — only `shared` can be accessed.
    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Authorization": "Bearer \(OpenAIConfig.apiKey)",
            "Content-Type": "application/json",
        ]
        session = URLSession(configuration: config)
    }

    // MARK: - Request Builders

    /// Creates a JSON POST request for the given API path.
    /// Used by TransformService for the `/responses` endpoint.
    ///
    /// - Parameters:
    ///   - path: Relative path appended to `OpenAIConfig.baseURL` (e.g. "responses").
    ///   - body: Pre-serialized JSON data to send as the HTTP body.
    /// - Returns: A fully configured URLRequest ready for `URLSession.data(for:)` or `.bytes(for:)`.
    ///
    /// Note: Headers are set explicitly on the request (not relying on session config)
    /// because TransformService uses `URLSession.shared` for streaming, which doesn't
    /// carry this manager's session-level headers.
    func makeRequest(path: String, body: Data) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(OpenAIConfig.baseURL)/\(path)")!)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    /// Creates a POST request without Content-Type — the caller (TranscribeService)
    /// sets the multipart boundary in Content-Type and builds the body manually.
    /// Only Authorization is pre-set here.
    ///
    /// - Parameter path: Relative path (e.g. "audio/transcriptions").
    /// - Returns: A URLRequest with method and auth header set; caller must add body and Content-Type.
    func makeMultipartRequest(path: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(OpenAIConfig.baseURL)/\(path)")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }
}
