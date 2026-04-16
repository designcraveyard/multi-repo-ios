import SwiftUI

// MARK: - Chat Input Bar
// Pill-shaped text input with send button and optional mic button.
// Mic button is wired in Task 32 via AppAudioRecorder.

struct ChatInputBar: View {
    // --- Props
    @Binding var text: String
    let isStreaming: Bool
    let onSend: (String) -> Void

    // --- Voice recording (wired to AppAudioRecorder)
    var isRecording: Bool = false
    var onMicTap: (() -> Void)? = nil

    // --- State
    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStreaming
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: CGFloat.space2) {
            // --- Mic button (shown when onMicTap is wired)
            if let onMicTap {
                Button(action: onMicTap) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.appSurfaceErrorSolid : Color.surfacesBaseLowContrast)
                            .frame(width: 36, height: 36)

                        Ph.microphone.regular
                            .iconSize(.sm)
                            .foregroundStyle(isRecording ? Color.white : Color.typographySecondary)
                    }
                }
                .accessibilityLabel(isRecording ? "Stop recording" : "Voice input")
            }

            // --- Text input container
            HStack(alignment: .bottom, spacing: CGFloat.space2) {
                TextField("Message...", text: $text, axis: .vertical)
                    .font(.appBodyMedium)
                    .foregroundStyle(Color.typographyPrimary)
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .onSubmit {
                        if canSend {
                            sendAndClear()
                        }
                    }

                // --- Send button
                Button(action: sendAndClear) {
                    ZStack {
                        Circle()
                            .fill(canSend ? Color.surfacesBrandInteractive : Color.surfacesBaseLowContrast)
                            .frame(width: 32, height: 32)

                        if isStreaming {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(canSend ? Color.white : Color.typographyMuted)
                        }
                    }
                }
                .disabled(!canSend)
                .animation(.easeInOut(duration: 0.15), value: canSend)
            }
            .padding(.horizontal, .space3)
            .padding(.vertical, .space2)
            .background(
                Capsule()
                    .strokeBorder(Color.borderDefault, lineWidth: 1)
                    .background(Color.surfacesBasePrimary, in: Capsule())
            )
        }
        .padding(.horizontal, .space4)
        .padding(.vertical, .space3)
        .background(Color.surfacesBasePrimary)
    }

    private func sendAndClear() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }
}

#Preview {
    VStack {
        Spacer()
        ChatInputBar(text: .constant(""), isStreaming: false, onSend: { _ in })
        ChatInputBar(text: .constant("Tell me about Pikachu"), isStreaming: false, onSend: { _ in })
        ChatInputBar(text: .constant("Loading..."), isStreaming: true, onSend: { _ in })
    }
    .background(Color.surfacesBasePrimary)
}
