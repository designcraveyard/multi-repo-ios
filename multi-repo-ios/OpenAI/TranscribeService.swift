//
//  TranscribeService.swift
//  multi-repo-ios
//
//  Speech-to-text service using OpenAI's Whisper API (POST /audio/transcriptions).
//
//  Unlike TransformService which streams SSE events, this service makes a single
//  non-streaming POST request with multipart/form-data encoding (required by the
//  Whisper API) and returns the full transcript at once.
//
//  Multipart construction:
//    The Whisper API requires audio uploaded as a file field in a multipart body.
//    We build the body manually using RFC 2046 boundary-delimited parts rather than
//    using a third-party multipart library, keeping the dependency footprint zero.
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

// MARK: - TranscribeService

/// Singleton service that transcribes audio data to text via the Whisper API.
/// Accepts raw audio `Data` (typically M4A from AppAudioRecorder) and returns
/// a `TranscribeResult` with the transcript text, detected language, and duration.
@MainActor
final class TranscribeService {
    static let shared = TranscribeService()

    private init() {}

    /// Transcribes audio data using OpenAI's Whisper model.
    ///
    /// - Parameters:
    ///   - audioData: Raw audio bytes (M4A from AppAudioRecorder, or WebM from web).
    ///   - mimeType: MIME type of the audio. Defaults to "audio/m4a" which matches
    ///     AppAudioRecorder's AAC/M4A output. Used to set the correct file extension
    ///     in the multipart body so the API can identify the codec.
    ///   - language: Optional ISO-639-1 language hint (e.g. "en"). When provided,
    ///     Whisper skips language detection and may produce better results.
    /// - Returns: A `TranscribeResult` with transcript text and optional metadata.
    /// - Throws: `TranscribeServiceError.apiError` on HTTP failures,
    ///           `TranscribeServiceError.formatError` if the response can't be parsed.
    func transcribe(audioData: Data, mimeType: String = "audio/m4a", language: String? = nil) async throws -> TranscribeResult {

        // --- Build multipart/form-data request ---
        // Use a UUID as the boundary separator — guaranteed unique, avoids collisions with body content.
        let boundary = UUID().uuidString
        var request = OpenAIManager.shared.makeMultipartRequest(path: "audio/transcriptions")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Part 1: model name — tells the API which Whisper model to use
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(OpenAIConfig.whisperModel)\r\n".data(using: .utf8)!)

        // Part 2: response format — "verbose_json" gives us language and duration metadata
        // alongside the transcript text (vs plain "json" which only returns text)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)

        // Part 3 (optional): language hint — improves accuracy when the language is known
        if let language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }

        // Part 4: audio file — the actual audio data with filename and MIME type.
        // The filename extension must match the actual codec for the API to decode correctly.
        let ext = mimeType == "audio/m4a" ? "m4a" : "webm"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.\(ext)\"\r\n".data(using: .utf8)!)
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
            // Include the API's error body in the exception for debugging
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscribeServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }

        // Parse the verbose_json response. The "text" field is always present;
        // "language" and "duration" are extras from the verbose format.
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw TranscribeServiceError.formatError("Cannot parse transcription response")
        }

        return TranscribeResult(
            text: text,
            language: json["language"] as? String,
            duration: json["duration"] as? Double
        )
    }
}
