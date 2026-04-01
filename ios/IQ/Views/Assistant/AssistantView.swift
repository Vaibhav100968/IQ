import SwiftUI

// ── AssistantView — mirrors assistant/page.tsx ──────────────────────────────
struct AssistantView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var inputText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil

    // Quick suggestion chips
    private let suggestions: [String] = [
        "What is my risk score?",
        "What happens if I eat dairy?",
        "Show me flare prevention tips",
        "What triggers flare-ups?",
        "What should I eat today?",
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── Messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Welcome message if empty
                            if appVM.chatHistory.isEmpty {
                                welcomeCard
                            }

                            ForEach(appVM.chatHistory) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }

                            if appVM.isChatLoading {
                                typingIndicator
                                    .id("typing")
                            }

                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .onChange(of: appVM.chatHistory.count) { _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                .onChange(of: appVM.isChatLoading) { _ in
                    if appVM.isChatLoading {
                        withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                    }
                }
            }

            // ── Suggestion chips (shown when empty or after response)
            if !appVM.isChatLoading && appVM.chatHistory.isEmpty {
                suggestionsRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Divider()

            // ── Input bar
            inputBar
        }
        .background(IQColors.background.ignoresSafeArea())
    }

    // ── Welcome card
    private var welcomeCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(IQColors.pink)
                    .frame(width: 56, height: 56)
                Text("IQ")
                    .font(IQFont.black(20))
                    .foregroundColor(.black)
            }

            Text("Gut Intelligence Assistant")
                .font(IQFont.bold(17))
                .foregroundColor(IQColors.textPrimary)

            Text("Ask me about your symptoms, risk score, diet, and flare management.")
                .font(IQFont.regular(13))
                .foregroundColor(IQColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        )
        .padding(.top, 8)
    }

    // ── Suggestion chips
    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button {
                        inputText = s
                        send()
                    } label: {
                        Text(s)
                            .font(IQFont.medium(12))
                            .foregroundColor(IQColors.lavenderDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(IQColors.lavender.opacity(0.3))
                                    .overlay(Capsule().stroke(IQColors.border, lineWidth: 1))
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
        .background(Color.white)
    }

    // ── Message bubble
    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.role == .assistant {
                // Avatar
                ZStack {
                    Circle()
                        .fill(IQColors.pink)
                        .frame(width: 28, height: 28)
                    Text("IQ")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(IQColors.pinkDark)
                }
            }

            VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 4) {
                Text(msg.content)
                    .font(IQFont.regular(14))
                    .foregroundColor(msg.role == .user ? .white : IQColors.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                msg.role == .user
                                ? AnyShapeStyle(IQColors.lavender)
                                : AnyShapeStyle(Color.white)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
                    .frame(maxWidth: 300, alignment: msg.role == .user ? .trailing : .leading)

                Text(msg.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(IQColors.textMuted)
            }

            if msg.role == .user { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)
    }

    // ── Typing indicator
    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(IQColors.pink)
                    .frame(width: 28, height: 28)
                Text("IQ")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(IQColors.pinkDark)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    TypingDot(delay: Double(i) * 0.2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )

            Spacer()
        }
    }

    // ── Input bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your gut health...", text: $inputText, axis: .vertical)
                .font(IQFont.regular(14))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(IQColors.inputBg)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(IQColors.border, lineWidth: 1))
                )

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? IQColors.textMuted
                        : IQColors.pinkDark
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appVM.isChatLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        appVM.sendMessage(text)
    }
}

// ── Animated typing dot ──────────────────────────────────────────────────────
private struct TypingDot: View {
    let delay: Double
    @State private var offset: CGFloat = 0

    var body: some View {
        Circle()
            .fill(IQColors.textMuted)
            .frame(width: 7, height: 7)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    offset = -5
                }
            }
    }
}
