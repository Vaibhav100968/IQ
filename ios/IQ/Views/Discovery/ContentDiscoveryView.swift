import SwiftUI

// ── Content Discovery — Production "Fun" tab ─────────────────────────────────

struct ContentDiscoveryView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var manager = ContentManager.shared
    @State private var selectedItem: ContentItem?
    @State private var selectedCourse: ContentItem?
    @State private var showDetail = false
    @State private var showCourse = false
    @State private var activeTab: FunTab = .explore

    enum FunTab { case explore, saved }

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            switch manager.loadState {
            case .loading:
                loadingState
            case .error(let msg):
                ContentErrorView(message: msg) { manager.retry() }
            case .empty:
                ContentEmptyView()
            case .loaded:
                loadedContent
            }
        }
        .sheet(isPresented: $showDetail) {
            if let item = selectedItem {
                ArticleDetailView(item: item, manager: manager)
                    .environmentObject(appVM)
            }
        }
        .sheet(isPresented: $showCourse) {
            if let course = selectedCourse {
                CourseDetailView(course: course, manager: manager)
                    .environmentObject(appVM)
            }
        }
        .onAppear { appVM.fetchMLPrediction() }
    }

    // ── LOADING STATE ────────────────────────────────────────────────────────

    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                funHeader
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerView(width: 100, height: 40, cornerRadius: 20)
                    }
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 12) {
                    ShimmerView(width: 160, height: 16).padding(.horizontal, 16)
                    SkeletonCardRow()
                }
                VStack(alignment: .leading, spacing: 12) {
                    ShimmerView(width: 140, height: 16).padding(.horizontal, 16)
                    SkeletonCardRow()
                }
            }
            .padding(.top, 8)
        }
    }

    // ── LOADED CONTENT ───────────────────────────────────────────────────────

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                funHeader

                DiscoveryMLLinkedBanner()

                if activeTab == .explore {
                    exploreContent
                } else {
                    savedContent
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    // ── HEADER ───────────────────────────────────────────────────────────────

    private var funHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.3)) { activeTab = .explore }
                } label: {
                    Text("Fun")
                        .font(IQFont.black(26))
                        .foregroundColor(activeTab == .explore ? IQColors.textPrimary : IQColors.textMuted)
                }

                Button {
                    withAnimation(.spring(response: 0.3)) { activeTab = .saved }
                } label: {
                    Text("Saved")
                        .font(IQFont.semibold(16))
                        .foregroundColor(activeTab == .saved ? IQColors.textPrimary : IQColors.textMuted)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                headerIcon("magnifyingglass")
                headerIcon("person.crop.circle")
            }
        }
        .padding(.horizontal, 16)
    }

    private func headerIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(IQColors.textSecondary)
            .frame(width: 36, height: 36)
            .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.05), radius: 4, y: 2))
    }

    // ── EXPLORE TAB ──────────────────────────────────────────────────────────

    private var exploreContent: some View {
        VStack(spacing: 24) {
            CategoryPillsView(manager: manager)

            if let cat = manager.activeCategory {
                filteredCategoryContent(cat)
            } else {
                fullExploreContent
            }
        }
    }

    private var fullExploreContent: some View {
        VStack(spacing: 24) {
            if let item = manager.continueLearnItem {
                ContinueLearningCard(
                    item: item,
                    progress: manager.courseProgress(for: item.id)
                ) { openItem(item) }
            }

            ExpertCardView(expert: MockContent.expert) {
                manager.trackEvent("expert_tap", itemId: MockContent.expert.id)
            }

            DiscoverySectionView(title: "Things You Should Know", icon: "brain", items: manager.shouldKnowItems, onSelect: openItem)
            DiscoverySectionView(title: "Healthy Concerns", icon: "heart.fill", items: manager.concernItems, onSelect: openItem)

            TapToRevealCard(
                question: "Your gut produces 95% of your body's serotonin — the 'happiness hormone'",
                answer: "This is why digestive issues often co-occur with anxiety and depression. Taking care of your gut is directly taking care of your mental health."
            )

            DiscoverySectionView(title: "Your Gut & Lifestyle", icon: "figure.run", items: manager.lifestyleItems, onSelect: openItem)

            if !manager.courseItems.isEmpty {
                DiscoverySectionView(title: "Courses", icon: "book.fill", items: manager.courseItems) { item in
                    selectedCourse = item
                    showCourse = true
                    manager.markViewed(item)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            MiniQuizCard(question: MockContent.quizQuestions[0])

            articlesFeed
        }
    }

    private func filteredCategoryContent(_ cat: ContentCategory) -> some View {
        let items = manager.rankedContent(for: cat)
        return VStack(spacing: 20) {
            if items.isEmpty {
                ContentEmptyView()
            } else {
                DiscoverySectionView(title: cat.label, icon: cat.icon, items: items, onSelect: openItem)

                VStack(spacing: 10) {
                    ForEach(items) { item in
                        Button { openItem(item) } label: {
                            ArticleRowView(item: item, manager: manager)
                        }
                        .buttonStyle(ContentPressStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // ── ARTICLES FEED ────────────────────────────────────────────────────────

    private var articlesFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(IQColors.lavenderDark)
                Text("Latest Articles")
                    .font(IQFont.bold(16))
                    .foregroundColor(IQColors.textPrimary)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(manager.articleItems) { item in
                    Button { openItem(item) } label: {
                        ArticleRowView(item: item, manager: manager)
                    }
                    .buttonStyle(ContentPressStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // ── SAVED TAB ────────────────────────────────────────────────────────────

    private var savedContent: some View {
        VStack(spacing: 16) {
            if manager.savedItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 36))
                        .foregroundColor(IQColors.textMuted)
                    Text("No saved content yet")
                        .font(IQFont.semibold(15))
                        .foregroundColor(IQColors.textPrimary)
                    Text("Bookmark articles and courses to find them here")
                        .font(IQFont.regular(12))
                        .foregroundColor(IQColors.textSecondary)
                }
                .padding(40)
            } else {
                VStack(spacing: 10) {
                    ForEach(manager.savedItems) { item in
                        Button { openItem(item) } label: {
                            ArticleRowView(item: item, manager: manager)
                        }
                        .buttonStyle(ContentPressStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // ── NAVIGATION ───────────────────────────────────────────────────────────

    private func openItem(_ item: ContentItem) {
        manager.markViewed(item)
        manager.trackEvent("content_click", itemId: item.id)
        if item.type == .course {
            selectedCourse = item
            showCourse = true
        } else {
            selectedItem = item
            showDetail = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - ML-linked banner (same `appVM.mlPrediction` as Log calendar & Gut Intelligence)

private struct DiscoveryMLLinkedBanner: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "link.circle.fill")
                    .font(.body)
                    .foregroundStyle(IQColors.lavenderDark)
                Text("Same model as Log & Insights")
                    .font(IQFont.bold(14))
                    .foregroundColor(IQColors.textPrimary)
            }

            if appVM.isMLLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Updating outlook…")
                        .font(IQFont.regular(12))
                        .foregroundColor(IQColors.textSecondary)
                }
            } else if let p = appVM.mlPrediction {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Today’s combined flare outlook:")
                        .font(IQFont.regular(12))
                        .foregroundColor(IQColors.textSecondary)
                    Text("\(p.riskPercent)%")
                        .font(IQFont.bold(12))
                        .foregroundColor(IQColors.textPrimary)
                    Text("(\(p.riskLabel)) — same model as your Log calendar.")
                        .font(IQFont.regular(12))
                        .foregroundColor(IQColors.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Text("General vs personalized predictions are shown only under Gut Intelligence → AI Intelligence.")
                    .font(IQFont.regular(11))
                    .foregroundColor(IQColors.textMuted)
            } else {
                Text("Log on the Log tab to run the on-device model; this card will mirror the same outlook as your flare calendar.")
                    .font(IQFont.regular(12))
                    .foregroundColor(IQColors.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .padding(.horizontal, 16)
    }
}
