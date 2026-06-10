//
//  TranscribeService.swift
//  multi-repo-ios
//
//  Speech-to-text service backed by the `ai-transcribe` Supabase Edge Function.
//
//  History: this service previously POSTed straight to OpenAI's Whisper API with a
//  client-side API key. The key now lives only in Supabase function secrets and all
//  calls go through the JWT-protected edge function instead.
//
//  Unlike TransformService, this makes a single non-streaming POST with
//  multipart/form-data encoding (the audio must upload as a binary file field)
//  and returns the full transcript at once.
//
//  Multipart construction:
//    The body is built manually using RFC 2046 boundary-delimited parts rather than
//    a third-party multipart library, keeping the dependency footprint zero.
//    Each part follows the pattern:
//      --<boundary>\r\n
//      Content-Disposition: form-data; name="fieldName"\r\n\r\n
//      <value>\r\n
//    The final boundary ends with -- to signal completion.
//
//  Usage:
//    let audioData = try recorder.stopRecording()
//    let result = try await TranscribeService.shared.transcribe(audioData: audioData)
//    print(result.text)  // "Hello world"
//

import Foundation
import Supabase

// MARK: - TranscribeService

/// Singleton service that transcribes audio data to text via the `ai-transcribe`
/// edge function. Accepts raw audio `Data` (typically M4A from AppAudioRecorder)
/// and returns a `TranscribeResult` with the transcript text and language.
@MainActor
final class TranscribeService {
    static let shared = TranscribeService()

    private init() {}

    /// Transcribes audio data via the `ai-transcribe` edge function (Whisper-backed).
    ///
    /// - Parameters:
    ///   - audioData: Raw audio bytes (M4A from AppAudioRecorder, or WebM from web).
    ///   - mimeType: MIME type of the audio. Defaults to "audio/m4a" which matches
    ///     AppAudioRecorder's AAC/M4A output. Used to set the correct file extension
    ///     in the multipart body so the API can identify the codec.
    ///   - language: Optional ISO-639-1 language hint (e.g. "en"). When provided,
    ///     Whisper skips language detection and may produce better results.
    /// - Returns: A `TranscribeResult` with transcript text and detected language.
    ///   (`duration` is always nil — the edge function does not report it.)
    /// - Throws: `TranscribeServiceError.apiError` on HTTP failures,
    ///           `TranscribeServiceError.formatError` if the response can't be parsed.
    func transcribe(audioData: Data, mimeType: String = "audio/m4a", language: String? = nil) async throws -> TranscribeResult {

        // The edge function enforces verify_jwt — a valid signed-in session is required.
        let session = try await SupabaseManager.shared.client.auth.session

        let url = SupabaseManager.shared.supabaseURL
            .appendingPathComponent("functions/v1/ai-transcribe")

        // --- Build multipart/form-data request ---
        // Use a UUID as the boundary separator — guaranteed unique, avoids collisions with body content.
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Part 1 (optional): language hint — improves accuracy when the language is known
        if let language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }

        // Part 2: audio file — the actual audio data with filename and MIME type.
        // The filename extension must match the actual codec for Whisper to decode correctly.
        let ext = mimeType == "audio/m4a" ? "m4a" : "webm"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.\(ext)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Closing boundary (note the trailing --)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // --- Send request and parse response ---
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscribeServiceError.apiError("Invalid response")
        }
        guard httpResponse.statusCode == 200 else {
            // Include the edge function's error body in the exception for debugging
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscribeServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }

        // Parse the JSON response: { text, language }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw TranscribeServiceError.formatError("Cannot parse transcription response")
        }

        return TranscribeResult(
            text: text,
            language: json["language"] as? String,
            duration: nil
        )
    }
}
