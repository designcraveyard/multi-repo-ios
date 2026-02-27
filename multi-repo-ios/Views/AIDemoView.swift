//
//  AIDemoView.swift
//  multi-repo-ios
//
//  Demo screen for OpenAI Transform (food logger) and Transcribe services.
//

import SwiftUI
import PhosphorSwift

struct AIDemoView: View {
    @State private var inputText = ""
    @State private var responseText = ""
    @State private var transcriptText = ""
    @State private var isStreaming = false
    @State private var isTranscribing = false
    @State private var errorMessage: String?
    @State private var audioRecorder = AppAudioRecorder()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CGFloat.space4) {
                // MARK: - Header
                Text("AI Food Logger Demo")
                    .font(.appHeadingLarge)
                    .foregroundStyle(Color.typographyPrimary)

                Text("Type or speak what you ate and get nutritional info from the USDA database.")
                    .font(.appBodyMedium)
                    .foregroundStyle(Color.typographyMuted)

                // MARK: - Input Area
                HStack(spacing: CGFloat.space2) {
                    TextField("e.g. a large apple, grilled chicken breast...", text: $inputText)
                        .font(.appBodyMedium)
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
                        if isStreaming {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.typographyPrimary)
                                .frame(width: 2, height: 16)
                                .opacity(0.6)
                        }
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
                config: FoodLoggerConfig.config,
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
                await handleSend()
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
