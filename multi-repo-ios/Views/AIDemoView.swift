//
//  AIDemoView.swift
//  multi-repo-ios
//
//  Demo screen for the AI Transform and Transcribe services, both backed by
//  JWT-protected Supabase Edge Functions (ai-transform / ai-transcribe).
//  Cross-platform counterpart of the web /ai-demo route.
//
//  Pick a transform action, type or dictate some text, and run it. The mic
//  button records via AppAudioRecorder, transcribes through TranscribeService,
//  and drops the transcript into the input field.
//

import SwiftUI

struct AIDemoView: View {

    // MARK: - Transform actions
    // Each action maps to a MarkdownTransformConfig preset (plain text-in/text-out
    // prompts that work for any text, not just markdown).

    private enum DemoAction: String, CaseIterable, Identifiable {
        case summarise = "Summarise"
        case keyPoints = "Key Points"
        case actions = "List Actions"

        var id: String { rawValue }

        var config: TransformConfig {
            switch self {
            case .summarise: return MarkdownTransformConfig.summarise
            case .keyPoints: return MarkdownTransformConfig.keyPointers
            case .actions:   return MarkdownTransformConfig.listActions
            }
        }
    }

    // MARK: - State

    @State private var inputText = ""
    @State private var selectedAction: DemoAction = .summarise
    @State private var responseText = ""
    @State private var transcriptText = ""
    @State private var isStreaming = false
    @State private var isTranscribing = false
    @State private var errorMessage: String?
    @State private var audioRecorder = AppAudioRecorder()

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CGFloat.space4) {
                // MARK: - Header
                Text("AI Transform & Transcribe")
                    .font(.appHeadingLarge)
                    .foregroundStyle(Color.typographyPrimary)

                Text("Type or dictate some text, pick an action, and run it through the JWT-protected edge functions.")
                    .font(.appBodyMedium)
                    .foregroundStyle(Color.typographyMuted)

                // MARK: - Action Picker
                Picker("Action", selection: $selectedAction) {
                    ForEach(DemoAction.allCases) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                .pickerStyle(.segmented)

                // MARK: - Input Area
                HStack(spacing: CGFloat.space2) {
                    TextField("e.g. paste meeting notes, a long paragraph...", text: $inputText, axis: .vertical)
                        .font(.appBodyMedium)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await handleSend() } }

                    Button {
                        Task { await handleSend() }
                    } label: {
                        Ph.paperPlaneRight.fill.iconSize(.md)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isStreaming)
                    .tint(Color.surfacesBrandInteractive)

                    Button {
                        Task { await handleMicToggle() }
                    } label: {
                        Group {
                            if audioRecorder.state == .recording {
                                Ph.stop.fill.iconSize(.md)
                            } else {
                                Ph.microphone.regular.iconSize(.md)
                            }
                        }
                    }
                    .disabled(isStreaming || isTranscribing)
                    .tint(audioRecorder.state == .recording ? Color.typographyError : Color.typographyPrimary)
                }

                // MARK: - Recording Indicator
                if audioRecorder.state == .recording {
                    HStack(spacing: CGFloat.space2) {
                        Circle()
                            .fill(Color.typographyError)
                            .frame(width: 8, height: 8)
                        Text("Recording... tap stop when done")
                            .font(.appBodySmall)
                            .foregroundStyle(Color.typographyError)
                    }
                    .padding(.horizontal, CGFloat.space3)
                    .padding(.vertical, CGFloat.space2)
                    .background(Color.surfacesErrorSubtle.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CGFloat.radiusSM))
                }

                if isTranscribing {
                    Text("Transcribing audio...")
                        .font(.appBodySmall)
                        .foregroundStyle(Color.typographyMuted)
                }

                // MARK: - Transcript
                if !transcriptText.isEmpty {
                    HStack {
                        Text("Transcript: ").font(.appBodySmallEm)
                        + Text(transcriptText).font(.appBodySmall)
                    }
                    .foregroundStyle(Color.typographySecondary)
                    .padding(CGFloat.space3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surfacesBaseLowContrast)
                    .clipShape(RoundedRectangle(cornerRadius: CGFloat.radiusSM))
                }

                // MARK: - AI Response
                if !responseText.isEmpty || isStreaming {
                    VStack(alignment: .leading) {
                        Text(responseText.isEmpty ? "Thinking..." : responseText)
                            .font(.appBodyMedium)
                            .foregroundStyle(Color.typographyPrimary)
                    }
                    .padding(CGFloat.space4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surfacesBaseLowContrast)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat.radiusMD)
                            .stroke(Color.borderDefault, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CGFloat.radiusMD))
                }

                // MARK: - Error
                if let errorMessage {
                    Text(errorMessage)
                        .font(.appBodySmall)
                        .foregroundStyle(Color.typographyError)
                        .padding(CGFloat.space3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfacesErrorSubtle.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: CGFloat.radiusSM))
                }

                // MARK: - Clear Button
                if !responseText.isEmpty && !isStreaming {
                    Button("Clear & start over") {
                        inputText = ""
                        responseText = ""
                        transcriptText = ""
                        errorMessage = nil
                    }
                    .font(.appBodySmall)
                    .foregroundStyle(Color.typographyMuted)
                }
            }
            .padding(CGFloat.space4)
        }
        .background(Color.surfacesBasePrimary)
    }

    // MARK: - Actions

    private func handleSend() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        responseText = ""
        errorMessage = nil
        isStreaming = true

        do {
            let stream = TransformService.shared.stream(
                config: selectedAction.config,
                input: TransformInput(text: text)
            )
            for try await event in stream {
                switch event {
                case .textDelta(let delta):
                    responseText += delta
                case .error(let msg):
                    errorMessage = msg
                case .done:
                    break
                default:
                    break
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isStreaming = false
    }

    private func handleMicToggle() async {
        if audioRecorder.state == .recording {
            do {
                let data = try audioRecorder.stopRecording()
                isTranscribing = true
                let result = try await TranscribeService.shared.transcribe(audioData: data)
                transcriptText = result.text
                inputText = result.text
                isTranscribing = false
            } catch {
                isTranscribing = false
                errorMessage = error.localizedDescription
            }
        } else {
            do {
                try await audioRecorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
