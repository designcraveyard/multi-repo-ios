import SwiftUI

// MARK: - Chat View
// Primary chat interface with SSE streaming, card rendering, and history.

struct ChatView: View {
    // --- State
    @State private var vm = ChatViewModel()
    @State private var inputText = ""
    @State private var showHistory = false
    @State private var audioRecorder = AppAudioRecorder()
    @State private var isTranscribing = false

    private var isRecording: Bool { audioRecorder.state == .recording }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Message list
                messageList

                AppDivider(type: .row)

                // --- Input bar with mic
                ChatInputBar(
                    text: $inputText,
                    isStreaming: vm.isStreaming || isTranscribing,
                    onSend: { text in
                        Task { await vm.sendMessage(text) }
                    },
                    isRecording: isRecording,
                    onMicTap: handleMicTap
                )
            }
            .background(Color.surfacesBasePrimary)
            .navigationTitle("PokéChat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Ph.clock.regular
                            .iconSize(.md)
                            .iconColor(.appIconPrimary)
                    }
                    .accessibilityLabel("Chat history")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.newChat()
                    } label: {
                        Ph.pencilSimple.regular
                            .iconSize(.md)
                            .iconColor(.appIconPrimary)
                    }
                    .accessibilityLabel("New chat")
                }
            }
            .sheet(isPresented: $showHistory) {
                ChatHistoryView(
                    sessions: vm.historySessions,
                    onSelect: { summary in
                        Task { await vm.loadSession(summary) }
                    },
                    onDelete: { id in
                        Task { await vm.deleteSession(id) }
                    },
                    onNewChat: {
                        vm.newChat()
                    }
                )
            }
            .task {
                await vm.loadHistory()
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: .space3) {
                    if vm.messages.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        ForEach(vm.messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }
                    }

                    // Invisible anchor for auto-scroll
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, .space4)
                .padding(.vertical, .space4)
            }
            .onChange(of: vm.streamToken) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Message Row

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        switch message {
        case .user(_, let text):
            HStack {
                Spacer(minLength: 60)
                Text(text)
                    .font(.appBodyMedium)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, .space4)
                    .padding(.vertical, .space3)
                    .background(Color.surfacesBrandInteractive, in: RoundedRectangle(cornerRadius: .radiusLG))
            }

        case .aiText(_, let markdown):
            HStack(alignment: .top, spacing: .space2) {
                aiAvatar
                VStack(alignment: .leading, spacing: 0) {
                    markdownText(markdown)
                        .font(.appBodyMedium)
                        .foregroundStyle(Color.typographyPrimary)
                }
                Spacer(minLength: 40)
            }

        case .aiEvent(_, let label):
            HStack(alignment: .top, spacing: .space2) {
                aiAvatar
                SSEStreamEventView(label: label)
                Spacer()
            }

        case .aiPokemonCard(_, let data):
            HStack(alignment: .top, spacing: .space2) {
                aiAvatar
                PokemonCardView(data: data)
                Spacer(minLength: 0)
            }

        case .aiEvolutionCard(_, let data):
            HStack(alignment: .top, spacing: .space2) {
                aiAvatar
                EvolutionCardView(data: data)
                Spacer(minLength: 0)
            }

        case .aiTypeMatchupCard(_, let data):
            HStack(alignment: .top, spacing: .space2) {
                aiAvatar
                TypeMatchupCardView(data: data)
                Spacer(minLength: 0)
            }

        case .aiTeamCard(_, let data):
            HStack(alignment: .top, spacing: .space2) {
                aiAvatar
                TeamCardView(data: data)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Markdown Rendering

    @ViewBuilder
    private func markdownText(_ markdown: String) -> some View {
        if let attributed = try? AttributedString(markdown: markdown) {
            Text(attributed)
        } else {
            Text(markdown)
        }
    }

    // MARK: - AI Avatar

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.surfacesBrandInteractive.opacity(0.12))
                .frame(width: 28, height: 28)
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(Color.surfacesBrandInteractive)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: .space4) {
            ZStack {
                Circle()
                    .fill(Color.surfacesBrandInteractive.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.surfacesBrandInteractive)
            }

            VStack(spacing: .space2) {
                Text("PokéChat")
                    .font(.appTitleMedium)
                    .foregroundStyle(Color.typographyPrimary)

                Text("Ask me anything about Pokémon —\nteam building, type matchups, evolutions.")
                    .font(.appBodyMedium)
                    .foregroundStyle(Color.typographySecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: .space2) {
                ForEach(["Who should I use against Water types?", "Build me a balanced team", "Show Eevee's evolution chain"], id: \.self) { suggestion in
                    Button {
                        inputText = suggestion
                    } label: {
                        Text(suggestion)
                            .font(.appBodySmall)
                            .foregroundStyle(Color.surfacesBrandInteractive)
                            .padding(.horizontal, .space4)
                            .padding(.vertical, .space2)
                            .background(
                                Color.surfacesBrandInteractive.opacity(0.08),
                                in: Capsule()
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Voice Input

    private func handleMicTap() {
        if isRecording {
            // Stop recording and transcribe
            isTranscribing = true
            Task {
                defer { isTranscribing = false }
                do {
                    let audioData = try audioRecorder.stopRecording()
                    let result = try await TranscribeService.shared.transcribe(audioData: audioData)
                    inputText = result.text
                } catch {
                    print("[ChatView] Transcription failed: \(error)")
                }
            }
        } else {
            // Start recording
            Task {
                do {
                    try await audioRecorder.startRecording()
                } catch {
                    print("[ChatView] Recording failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    ChatView()
}
