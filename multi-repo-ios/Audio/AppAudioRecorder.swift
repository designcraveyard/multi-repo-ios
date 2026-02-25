//
//  AppAudioRecorder.swift
//  multi-repo-ios
//
//  Observable AVFoundation audio recorder designed for voice transcription workflows.
//
//  This class wraps AVAudioRecorder with a clean start/stop/pause/resume lifecycle
//  and handles the common pain points of iOS audio recording:
//    - Microphone permission requests (async, bridged from callback API)
//    - Audio session category configuration (playAndRecord for simultaneous playback)
//    - Temporary file management (UUID-named files in tmp/, cleaned up on stop)
//    - State tracking via `@Observable` so SwiftUI views can react to recording state
//
//  Recording format: AAC in M4A container at 44.1kHz mono. This matches what
//  TranscribeService expects (mimeType: "audio/m4a") and gives good quality
//  at a reasonable file size for speech.
//
//  Typical usage with TranscribeService:
//  ```swift
//  let recorder = AppAudioRecorder()
//  try await recorder.startRecording()
//  // ... user speaks ...
//  let audioData = try recorder.stopRecording()
//  let result = try await TranscribeService.shared.transcribe(audioData: audioData)
//  ```
//
//  Edge cases handled:
//  - Permission denied: sets `error` property AND throws, so both UI binding and catch work
//  - Stop when idle: throws `AudioRecorderError.noRecording` (no crash)
//  - File missing after stop: throws `noRecording` (guards against OS cleanup race)
//  - Pause/resume when in wrong state: silently no-ops (safe to call anytime)
//

import Foundation
import AVFoundation

// MARK: - RecorderState
// Simple three-state enum for the recording lifecycle. Used by SwiftUI views
// to show/hide record/pause/stop buttons and display recording indicators.

enum RecorderState {
    case idle       // Not recording — initial state and state after stopRecording()
    case recording  // Actively capturing audio
    case paused     // Recording paused — can resume or stop
}

// MARK: - AppAudioRecorder

/// Observable audio recorder that manages the full AVFoundation recording lifecycle.
/// Marked `@Observable` for SwiftUI reactivity and `@MainActor` to match the project's
/// default isolation. Inherits from `NSObject` because `AVAudioRecorder` historically
/// required its delegate to be an NSObject (not currently using delegate methods, but
/// keeps the door open for metering/interruption handling).
@Observable
@MainActor
final class AppAudioRecorder: NSObject {

    // MARK: - Observable State
    // These properties drive the UI. `@Observable` makes SwiftUI views automatically
    // re-render when they change — no `@Published` needed.

    var state: RecorderState = .idle   // Current recording lifecycle state
    var error: String?                  // Human-readable error message for UI display

    // MARK: - Private State

    private var audioRecorder: AVAudioRecorder?  // The underlying AVFoundation recorder
    private var recordingURL: URL?               // File URL where audio is being written

    // MARK: - Permission

    /// Requests microphone permission asynchronously. Bridges AVAudioApplication's
    /// callback-based API into async/await using `withCheckedContinuation`.
    /// Returns true if permission was granted (either now or previously).
    ///
    /// Note: On first call, iOS shows the system permission dialog. On subsequent calls,
    /// returns the cached permission state instantly without showing a dialog.
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording Lifecycle

    /// Starts a new audio recording. Requests permission, configures the audio session,
    /// creates a temporary M4A file, and begins capturing.
    ///
    /// The audio session is set to `.playAndRecord` so the app can play sounds while
    /// recording (e.g. a "recording started" chime). Mode `.default` is used rather than
    /// `.measurement` or `.voiceChat` because those apply voice processing filters that
    /// can reduce transcription quality.
    ///
    /// - Throws: `AudioRecorderError.permissionDenied` if the user denies microphone access.
    ///           Also throws if AVAudioSession or AVAudioRecorder setup fails.
    func startRecording() async throws {
        error = nil  // Clear any previous error

        // Step 1: Ensure we have microphone permission
        let granted = await requestPermission()
        guard granted else {
            error = AudioRecorderError.permissionDenied.errorDescription
            throw AudioRecorderError.permissionDenied
        }

        // Step 2: Configure the shared audio session for recording
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        // Step 3: Create a unique temp file URL for this recording.
        // UUID ensures no collisions if multiple recordings happen in a session.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        // Step 4: Configure recording format — AAC in M4A container.
        // Mono channel is sufficient for speech and halves the file size.
        // 44.1kHz sample rate is the standard for AAC encoding.
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        // Step 5: Create the recorder and start capturing
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        recordingURL = url
        audioRecorder?.record()
        state = .recording
    }

    /// Stops recording and returns the audio data. Cleans up the temporary file.
    ///
    /// This is a synchronous method because `AVAudioRecorder.stop()` is synchronous
    /// and the file is immediately available after it returns. The audio data is read
    /// into memory and the temp file is deleted to avoid filling the tmp directory.
    ///
    /// - Returns: Raw audio `Data` in M4A format, ready to pass to `TranscribeService.transcribe()`.
    /// - Throws: `AudioRecorderError.noRecording` if called when idle or if the file doesn't exist.
    func stopRecording() throws -> Data {
        guard let recorder = audioRecorder, state != .idle else {
            throw AudioRecorderError.noRecording
        }

        recorder.stop()
        state = .idle

        // Read the recorded audio data from the temp file
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else {
            throw AudioRecorderError.noRecording
        }

        let data = try Data(contentsOf: url)

        // Clean up: delete the temp file and nil out references.
        // `try?` on removeItem because cleanup failure shouldn't prevent returning data.
        try? FileManager.default.removeItem(at: url)
        recordingURL = nil
        audioRecorder = nil
        return data
    }

    /// Pauses the current recording. Safe to call in any state — no-ops if not recording.
    /// The recording can be resumed with `resume()` or finalized with `stopRecording()`.
    func pause() {
        guard state == .recording else { return }
        audioRecorder?.pause()
        state = .paused
    }

    /// Resumes a paused recording. Safe to call in any state — no-ops if not paused.
    /// Internally calls `record()` again on the same AVAudioRecorder, which appends
    /// to the existing file rather than starting a new one.
    func resume() {
        guard state == .paused else { return }
        audioRecorder?.record()
        state = .recording
    }
}
