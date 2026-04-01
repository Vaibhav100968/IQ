import SwiftUI

// ── SHIMMER LOADING EFFECT ───────────────────────────────────────────────────

struct ShimmerView: View {
    @State private var phase: CGFloat = -1
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat = .infinity, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width; self.height = height; self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(hex: "E8E9FF").opacity(0.5))
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.4), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * phase)
                }
                .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

struct SkeletonCardRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        ShimmerView(height: 90, cornerRadius: 14)
                        ShimmerView(width: 120, height: 14)
                        ShimmerView(width: 80, height: 10)
                    }
                    .frame(width: 170)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// ── CATEGORY PILLS (Large, Femometer-style) ──────────────────────────────────

struct CategoryPillsView: View {
    @ObservedObject var manager: ContentManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ContentCategory.allCases) { cat in
                    let isActive = manager.activeCategory == cat
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            manager.activeCategory = isActive ? nil : cat
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(cat.label)
                                .font(IQFont.semibold(13))
                        }
                        .foregroundColor(isActive ? .white : cat.color)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(
                                isActive
                                ? AnyShapeStyle(cat.color)
                                : AnyShapeStyle(cat.color.opacity(0.08))
                            )
                        )
                        .overlay(
                            Capsule().stroke(isActive ? Color.clear : cat.color.opacity(0.2), lineWidth: 0.8)
                        )
                        .shadow(color: isActive ? cat.color.opacity(0.25) : .clear, radius: 8, y: 3)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// ── EXPERT CARD ──────────────────────────────────────────────────────────────

struct ExpertCardView: View {
    let expert: Expert
    let onTap: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: {
            onTap()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            expert.accentColor.opacity(0.15)
                        )
                        .frame(width: 56, height: 56)
                    Text(expert.initial)
                        .font(IQFont.bold(20))
                        .foregroundColor(expert.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(expert.name)
                        .font(IQFont.bold(15))
                        .foregroundColor(IQColors.textPrimary)
                    Text(expert.specialty)
                        .font(IQFont.semibold(11))
                        .foregroundColor(expert.accentColor)
                    Text(expert.bio)
                        .font(IQFont.regular(11))
                        .foregroundColor(IQColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(IQColors.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        Color.white
                    )
                    .shadow(color: expert.accentColor.opacity(0.08), radius: 12, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(IQColors.border.opacity(0.5), lineWidth: 0.6)
            )
        }
        .buttonStyle(ContentPressStyle())
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
    }
}

// ── CONTENT SECTION (Title + Horizontal Scroll) ─────────────────────────────

struct DiscoverySectionView: View {
    let title: String
    let icon: String
    let items: [ContentItem]
    let onSelect: (ContentItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(IQColors.lavenderDark)
                Text(title)
                    .font(IQFont.bold(16))
                    .foregroundColor(IQColors.textPrimary)
                Spacer()
                Text("See all")
                    .font(IQFont.medium(12))
                    .foregroundColor(IQColors.lavenderDark)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        DiscoveryCardView(item: item, index: index) { onSelect(item) }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// ── CONTENT CARD ─────────────────────────────────────────────────────────────

struct DiscoveryCardView: View {
    let item: ContentItem
    let index: Int
    let onTap: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: {
            onTap()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(item.category.gradient.first ?? IQColors.lavender)
                        .frame(height: 88)
                        .overlay(
                            Image(systemName: item.icon)
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(item.category.color.opacity(0.2))
                                .offset(x: 30, y: 10),
                            alignment: .bottomTrailing
                        )

                    HStack(spacing: 4) {
                        if !item.tags.isEmpty {
                            Text(item.tags.first ?? "")
                                .font(IQFont.bold(8))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(item.category.color.opacity(0.85)))
                        }
                        if item.type == .video {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                    }
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(IQFont.semibold(13))
                        .foregroundColor(IQColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        if let dur = item.duration {
                            HStack(spacing: 3) {
                                Image(systemName: "clock").font(.system(size: 8))
                                Text(dur).font(IQFont.regular(9))
                            }
                        }
                        HStack(spacing: 3) {
                            Image(systemName: "eye").font(.system(size: 8))
                            Text(formatCount(item.views)).font(IQFont.regular(9))
                        }
                        if item.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "16a34a"))
                        }
                    }
                    .foregroundColor(IQColors.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .frame(width: 170)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
            )
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(IQColors.border.opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(ContentPressStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.06)) {
                appeared = true
            }
        }
    }

    private func formatCount(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}

// ── ARTICLE ROW (Vertical Feed) ──────────────────────────────────────────────

struct ArticleRowView: View {
    let item: ContentItem
    @ObservedObject var manager: ContentManager

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(item.category.gradient.first ?? IQColors.lavender)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(item.category.color.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(IQFont.semibold(14))
                    .foregroundColor(IQColors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: "eye").font(.system(size: 9))
                        Text(formatCount(item.views)).font(IQFont.regular(10))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill").font(.system(size: 9))
                        Text("\(item.likes)").font(IQFont.regular(10))
                    }
                    if let dur = item.duration {
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.system(size: 9))
                            Text(dur).font(IQFont.regular(10))
                        }
                    }
                }
                .foregroundColor(IQColors.textMuted)
            }

            Spacer(minLength: 0)

            Button {
                manager.toggleSave(item)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: manager.progress.savedIds.contains(item.id) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14))
                    .foregroundColor(manager.progress.savedIds.contains(item.id) ? IQColors.lavenderDark : IQColors.textMuted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(IQColors.border.opacity(0.3), lineWidth: 0.5))
    }

    private func formatCount(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}

// ── CONTINUE LEARNING CARD ───────────────────────────────────────────────────

struct ContinueLearningCard: View {
    let item: ContentItem
    let progress: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(IQColors.border, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(IQColors.lavenderDark, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundColor(IQColors.lavenderDark)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue Learning")
                        .font(IQFont.bold(10))
                        .foregroundColor(IQColors.lavenderDark)
                        .tracking(0.5)
                    Text(item.title)
                        .font(IQFont.semibold(13))
                        .foregroundColor(IQColors.textPrimary)
                        .lineLimit(1)
                    Text("\(Int(progress * 100))% complete")
                        .font(IQFont.regular(10))
                        .foregroundColor(IQColors.textMuted)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(IQColors.lavenderDark)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: IQColors.lavenderDark.opacity(0.08), radius: 10, y: 4)
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(IQColors.lavender.opacity(0.4), lineWidth: 0.8))
        }
        .buttonStyle(ContentPressStyle())
        .padding(.horizontal, 16)
    }
}

// ── TAP TO REVEAL CARD ───────────────────────────────────────────────────────

struct TapToRevealCard: View {
    let question: String
    let answer: String
    @State private var isRevealed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { isRevealed.toggle() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "d97706"))
                    Text("Did you know?")
                        .font(IQFont.bold(10))
                        .foregroundColor(Color(hex: "d97706"))
                        .tracking(0.5)
                }

                Text(question)
                    .font(IQFont.semibold(14))
                    .foregroundColor(IQColors.textPrimary)
                    .multilineTextAlignment(.leading)

                if isRevealed {
                    Text(answer)
                        .font(IQFont.regular(12))
                        .foregroundColor(IQColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("Tap to reveal")
                        .font(IQFont.medium(11))
                        .foregroundColor(IQColors.lavenderDark)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(IQColors.blush.opacity(0.3))
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "d97706").opacity(0.2), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

// ── MINI QUIZ CARD ───────────────────────────────────────────────────────────

struct MiniQuizCard: View {
    let question: QuizQuestion
    @State private var selectedIndex: Int? = nil
    @State private var showExplanation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.diamond.fill")
                    .font(.system(size: 12))
                    .foregroundColor(IQColors.pinkDark)
                Text("Quick Quiz")
                    .font(IQFont.bold(10))
                    .foregroundColor(IQColors.pinkDark)
                    .tracking(0.5)
            }

            Text(question.question)
                .font(IQFont.semibold(14))
                .foregroundColor(IQColors.textPrimary)

            VStack(spacing: 6) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                    Button {
                        guard selectedIndex == nil else { return }
                        withAnimation(.spring(response: 0.3)) {
                            selectedIndex = idx
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.spring(response: 0.4)) { showExplanation = true }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(optionColor(for: idx))
                                .frame(width: 24, height: 24)
                                .overlay(optionIcon(for: idx))
                            Text(option)
                                .font(IQFont.medium(12))
                                .foregroundColor(IQColors.textPrimary)
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(optionBg(for: idx)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(optionBorder(for: idx), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedIndex != nil)
                }
            }

            if showExplanation {
                Text(question.explanation)
                    .font(IQFont.regular(11))
                    .foregroundColor(IQColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "F5F4FF")))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(IQColors.border.opacity(0.4), lineWidth: 0.6))
        .padding(.horizontal, 16)
    }

    private func optionColor(for idx: Int) -> Color {
        guard let sel = selectedIndex else { return IQColors.border }
        if idx == question.correctIndex { return Color(hex: "16a34a") }
        if idx == sel { return IQColors.pinkDark }
        return IQColors.border
    }

    private func optionBg(for idx: Int) -> Color {
        guard let sel = selectedIndex else { return Color.clear }
        if idx == question.correctIndex { return Color(hex: "dcfce7").opacity(0.5) }
        if idx == sel { return Color(hex: "FFCAE9").opacity(0.3) }
        return Color.clear
    }

    private func optionBorder(for idx: Int) -> Color {
        guard let sel = selectedIndex else { return IQColors.border.opacity(0.5) }
        if idx == question.correctIndex { return Color(hex: "16a34a").opacity(0.4) }
        if idx == sel { return IQColors.pinkDark.opacity(0.4) }
        return IQColors.border.opacity(0.3)
    }

    @ViewBuilder
    private func optionIcon(for idx: Int) -> some View {
        if let sel = selectedIndex {
            if idx == question.correctIndex {
                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            } else if idx == sel {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            } else {
                EmptyView()
            }
        } else {
            Text("\(Character(UnicodeScalar(65 + idx)!))")
                .font(IQFont.semibold(10))
                .foregroundColor(IQColors.textMuted)
        }
    }
}

// ── ERROR / EMPTY STATES ─────────────────────────────────────────────────────

struct ContentErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundColor(IQColors.textMuted)
            Text("Something went wrong")
                .font(IQFont.semibold(16))
                .foregroundColor(IQColors.textPrimary)
            Text(message)
                .font(IQFont.regular(13))
                .foregroundColor(IQColors.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Text("Tap to retry")
                    .font(IQFont.semibold(13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(IQColors.lavenderDark))
            }
        }
        .padding(32)
    }
}

struct ContentEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(IQColors.textMuted)
            Text("No content available yet")
                .font(IQFont.semibold(15))
                .foregroundColor(IQColors.textPrimary)
            Text("Check back soon for new articles and courses")
                .font(IQFont.regular(12))
                .foregroundColor(IQColors.textSecondary)
        }
        .padding(32)
    }
}

// ── BUTTON STYLE ─────────────────────────────────────────────────────────────

struct ContentPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
