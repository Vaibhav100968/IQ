import SwiftUI

// ── Article Detail — enhanced reading experience ─────────────────────────────

struct ArticleDetailView: View {
    let item: ContentItem
    @ObservedObject var manager: ContentManager
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var collapsedSections: Set<String> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroHeader
                articleBody
            }
        }
        .background(Color.white.ignoresSafeArea())
        .overlay(alignment: .topLeading) { backButton }
        .overlay(alignment: .topTrailing) { actionButtons }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            manager.trackEvent("article_open", itemId: item.id)
        }
        .onDisappear {
            manager.trackEvent("article_close", itemId: item.id)
        }
    }

    // ── Hero Header ──────────────────────────────────────────────────────────

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            (item.category.gradient.first ?? IQColors.lavender)
                .frame(height: 240)

            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 160, height: 160).offset(x: 120, y: -50)
                Image(systemName: item.icon)
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(item.category.color.opacity(0.2))
                    .offset(x: 100, y: -60)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: item.category.icon).font(.system(size: 9, weight: .bold))
                        Text(item.category.label.uppercased()).font(IQFont.bold(9)).tracking(1)
                    }
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.85)))

                    Text(item.difficulty.label)
                        .font(IQFont.bold(8))
                        .foregroundColor(item.difficulty.color)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(item.difficulty.color.opacity(0.1)))
                }

                Text(item.title)
                    .font(IQFont.bold(22))
                    .foregroundColor(IQColors.textPrimary)
                    .lineLimit(3)

                Text(item.description)
                    .font(IQFont.regular(13))
                    .foregroundColor(IQColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 14) {
                    if let dur = item.duration {
                        metaItem(icon: "clock", text: dur + " read")
                    }
                    metaItem(icon: "eye", text: "\(item.views)")
                    metaItem(icon: "heart.fill", text: "\(item.likes)")
                }
            }
            .padding(20)
        }
        .opacity(appeared ? 1 : 0.5)
    }

    private func metaItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(IQFont.medium(11))
        }
        .foregroundColor(IQColors.textMuted)
    }

    // ── Article Body ─────────────────────────────────────────────────────────

    private var articleBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(item.sections.enumerated()), id: \.element.id) { index, section in
                collapsibleSection(section, index: index)
            }

            applyTipCTA
            relatedContent
            markCompletedButton

            Spacer(minLength: 60)
        }
        .padding(20)
    }

    // ── Collapsible Sections ─────────────────────────────────────────────────

    private func collapsibleSection(_ section: ContentSection, index: Int) -> some View {
        let isCollapsed = collapsedSections.contains(section.id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isCollapsed { collapsedSections.remove(section.id) }
                    else { collapsedSections.insert(section.id) }
                }
            } label: {
                HStack {
                    Text(section.heading)
                        .font(IQFont.bold(16))
                        .foregroundColor(IQColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(IQColors.textMuted)
                        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                }
            }

            if !isCollapsed {
                VStack(alignment: .leading, spacing: 8) {
                    if section.isKeyInsight {
                        keyInsightBadge
                    }

                    Text(section.body)
                        .font(IQFont.regular(14))
                        .foregroundColor(IQColors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(0.05 * Double(index)), value: appeared)
    }

    private var keyInsightBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(Color(hex: "d97706"))
            Text("Key Insight").font(IQFont.bold(10)).foregroundColor(Color(hex: "d97706"))
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "fef3c7")))
    }

    // ── Apply Tip CTA ────────────────────────────────────────────────────────

    private var applyTipCTA: some View {
        Button {
            manager.trackEvent("apply_tip", itemId: item.id)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apply This Tip")
                        .font(IQFont.semibold(14))
                    Text("Track how this advice affects your symptoms")
                        .font(IQFont.regular(11))
                        .opacity(0.8)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.black)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(IQColors.pink)
            )
        }
        .buttonStyle(ContentPressStyle())
    }

    // ── Related Content ──────────────────────────────────────────────────────

    private var relatedContent: some View {
        let related = manager.allContent
            .filter { $0.category == item.category && $0.id != item.id }
            .prefix(3)

        return VStack(alignment: .leading, spacing: 12) {
            if !related.isEmpty {
                Divider()
                Text("Related Content")
                    .font(IQFont.bold(16))
                    .foregroundColor(IQColors.textPrimary)

                ForEach(Array(related)) { rel in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(rel.category.gradient.first ?? IQColors.lavender)
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: rel.icon).font(.system(size: 16)).foregroundColor(rel.category.color.opacity(0.5)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rel.title).font(IQFont.semibold(13)).foregroundColor(IQColors.textPrimary).lineLimit(1)
                            Text(rel.duration ?? "").font(IQFont.regular(10)).foregroundColor(IQColors.textMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(IQColors.textMuted)
                    }
                }
            }
        }
    }

    // ── Mark Completed ───────────────────────────────────────────────────────

    private var markCompletedButton: some View {
        Group {
            if !item.isCompleted {
                Button {
                    manager.markCompleted(item)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Completed")
                    }
                    .font(IQFont.semibold(13))
                    .foregroundColor(IQColors.lavenderDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(IQColors.lavenderDark.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Completed")
                }
                .font(IQFont.semibold(13))
                .foregroundColor(Color(hex: "16a34a"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "dcfce7")))
            }
        }
    }

    // ── Back Button ──────────────────────────────────────────────────────────

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(IQColors.textPrimary)
                .padding(10)
                .background(Circle().fill(Color.white.opacity(0.9)).shadow(color: .black.opacity(0.1), radius: 6, y: 2))
        }
        .padding(.leading, 16).padding(.top, 8)
    }

    // ── Action Buttons (save + like) ─────────────────────────────────────────

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                manager.toggleSave(item)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: manager.progress.savedIds.contains(item.id) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(manager.progress.savedIds.contains(item.id) ? IQColors.lavenderDark : IQColors.textPrimary)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.9)).shadow(color: .black.opacity(0.1), radius: 6, y: 2))
            }

            Button {
                manager.toggleLike(item)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "heart")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(IQColors.textPrimary)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.9)).shadow(color: .black.opacity(0.1), radius: 6, y: 2))
            }
        }
        .padding(.trailing, 16).padding(.top, 8)
    }
}
