import SwiftUI

// MARK: - ChatView
// Primary chat surface for the multi-agent Pokémon demo.
// Matches 99-neo-iOS chat visual language: floating header that blurs on scroll,
// light-grey asymmetric user bubble, avatar-less AI turns, sticky input bar.

struct ChatView: View {

    // MARK: - State

    @State private var vm = ChatViewModel()
    @State private var inputText = ""
    @State private var showHistory = false
    @State private var audioRecorder = AppAudioRecorder()
    @State private var isTranscribing = false
    @State private var scrollOffset: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    private var isRecording: Bool { audioRecorder.state == .recording }
    private let headerHeight: CGFloat = 56

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Spacer below the floating header
                Color.clear.frame(height: headerHeight)

                messageList

                bottomInputBar
            }

            customHeader
        }
        .background(Color.surfacesBasePrimary)
        .sheet(isPresented: $showHistory) {
            ChatHistoryView(
                sessions: vm.historySessions,
                onSelect: { summary in
                    Task { await vm.loadSession(summary) }
                    showHistory = false
                },
                onDelete: { id in
                    Task { await vm.deleteSession(id) }
                },
                onNewChat: {
                    vm.newChat()
                    showHistory = false
                }
            )
            .presentationDetents([.fraction(0.9)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .task { await vm.loadHistory() }
    }

    // MARK: - Custom Header (blurs on scroll)

    private var customHeader: some View {
        HStack(spacing: .space3) {
            AppIconButton(
                icon: AnyView(Ph.clock.regular),
                label: "Chat history",
                variant: .tertiary,
                size: .lg
            ) {
                showHistory = true
            }

            Spacer()

            Text("PokéChat")
                .font(.appTitleSmall)
                .foregroundStyle(Color.typographyPrimary)

            Spacer()

            AppIconButton(
                icon: AnyView(Ph.pencilSimple.regular),
                label: "New chat",
                variant: .tertiary,
                size: .lg
            ) {
                vm.newChat()
            }
        }
        .padding(.horizontal, .space5)
        .frame(height: headerHeight)
        .background {
            if scrollOffset > 10 {
                Color.surfacesBasePrimary.opacity(0.85)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            } else {
                Color.surfacesBasePrimary
                    .ignoresSafeArea()
            }
        }
        .animation(.easeOut(duration: 0.2), value: scrollOffset > 10)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetKey.self,
                            value: -geo.frame(in: .named("chatScroll")).minY
                        )
                }
                .frame(height: 0)

                LazyVStack(alignment: .leading, spacing: 0) {
                    if vm.messages.isEmpty {
                        emptyState
                            .padding(.top, 60)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(vm.messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }
                    }

                    Color.clear
                        .frame(height: 16)
                        .id("bottom")
                }
                .padding(.top, .space4)
            }
            .coordinateSpace(name: "chatScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
            .simultaneousGesture(TapGesture().onEnded { isInputFocused = false })
            .onChange(of: vm.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: vm.streamToken) { _, _ in
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: vm.isStreaming) { _, streaming in
                if !streaming { scrollToBottom(proxy: proxy) }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    // MARK: - Message Row

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        switch message {
        case .user(_, let text):
            userBubble(text: text)
                .padding(.horizontal, .space5)
                .padding(.vertical, .space2)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .aiText(_, let markdown):
            aiTextView(text: markdown)
                .padding(.horizontal, .space5)
                .padding(.vertical, .space3)
                .transition(.opacity)

        case .aiEvent(_, let label):
            HStack {
                SSEStreamEventView(label: label)
                Spacer()
            }
            .padding(.horizontal, .space5)
            .padding(.vertical, .space2)
            .transition(.opacity)

        case .aiPokemonCard(_, let data):
            PokemonCardView(data: data)
                .padding(.horizontal, .space5)
                .padding(.vertical, .space2)
                .transition(.opacity)

        case .aiEvolutionCard(_, let data):
            EvolutionCardView(data: data)
                .padding(.horizontal, .space5)
                .padding(.vertical, .space2)
                .transition(.opacity)

        case .aiTypeMatchupCard(_, let data):
            TypeMatchupCardView(data: data)
                .padding(.horizontal, .space5)
                .padding(.vertical, .space2)
                .transition(.opacity)

        case .aiTeamCard(_, let data):
            TeamCardView(data: data)
                .padding(.horizontal, .space5)
                .padding(.vertical, .space2)
                .transition(.opacity)
        }
    }

    // MARK: - User Bubble (99-neo shape: asymmetric radius, light grey)

    private func userBubble(text: String) -> some View {
        Text(text)
            .font(.appBodyLarge)
            .foregroundStyle(Color.typographySecondary)
            .padding(.horizontal, .space4)
            .padding(.vertical, .space3)
            .background(Color.surfacesBaseLowContrast)
            .clipShape(
                .rect(
                    topLeadingRadius: .radiusMD,
                    bottomLeadingRadius: .radiusMD,
                    bottomTrailingRadius: .radiusMD,
                    topTrailingRadius: .radiusXS
                )
            )
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
    }

    // MARK: - AI Text (markdown via AttributedString; upgrade to MarkdownUI later)

    @ViewBuilder
    private func aiTextView(text: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
                .font(.appBodyLarge)
                .foregroundStyle(Color.typographyPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        } else {
            Text(text)
                .font(.appBodyLarge)
                .foregroundStyle(Color.typographyPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: .space4) {
            ZStack {
                Circle()
                    .fill(Color.surfacesBrandInteractive.opacity(0.1))
                    .frame(width: 72, height: 72)
                Ph.star.regular
                    .iconSize(.xl)
                    .iconColor(Color.iconsBrand)
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
                ForEach([
                    "Who should I use against Water types?",
                    "Build me a balanced team",
                    "Show Eevee's evolution chain"
                ], id: \.self) { suggestion in
                    Button {
                        inputText = suggestion
                        isInputFocused = true
                    } label: {
                        Text(suggestion)
                            .font(.appBodySmall)
                            .foregroundStyle(Color.appTextBrand)
                            .padding(.horizontal, .space4)
                            .padding(.vertical, .space2)
                            .background(
                                Color.surfacesBrandInteractive.opacity(0.08),
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(.top, .space2)
        }
        .padding(.horizontal, .space6)
    }

    // MARK: - Bottom Input Bar

    private var bottomInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(Color.borderMuted)

            ChatInputBar(
                text: $inputText,
                isStreaming: vm.isStreaming || isTranscribing,
                onSend: { text in
                    Task { await vm.sendMessage(text) }
                },
                isRecording: isRecording,
                onMicTap: handleMicTap
            )
            .focused($isInputFocused)
        }
    }

    // MARK: - Voice Input

    private func handleMicTap() {
        if isRecording {
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

// MARK: - Scroll Offset Preference

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ChatView()
}
