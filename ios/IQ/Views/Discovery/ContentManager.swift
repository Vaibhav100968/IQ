import SwiftUI

// TODO: Connect Supabase content table
// TODO: Connect ML personalization layer
// TODO: Add web-scraped content pipeline
// TODO: fetchContent() from API
// TODO: processContent() with AI summarization
// TODO: storeContent() to local + remote DB

// ── ContentManager — service layer for all discovery content ─────────────────

@MainActor
class ContentManager: ObservableObject {

    static let shared = ContentManager()

    // ── State
    @Published var loadState: ContentLoadState = .loading
    @Published var allContent: [ContentItem] = []
    @Published var progress: UserProgress = UserProgress()
    @Published var activeCategory: ContentCategory? = nil

    // ── Persistence keys
    private let progressKey = "iq_user_progress"
    private let cacheKey = "iq_content_cache"
    private let cacheTimestampKey = "iq_cache_timestamp"
    private let cacheTTL: TimeInterval = 3600 // 1 hour

    init() {
        loadProgress()
        loadContent()
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONTENT LOADING + STATE
    // ═══════════════════════════════════════════════════════════════════════════

    func loadContent() {
        loadState = .loading

        // TODO: Replace with real API call
        // Example: let items = try await SupabaseClient.shared.from("content").select().execute()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            let items = MockContent.allContent
            if items.isEmpty {
                self.loadState = .empty
            } else {
                self.allContent = self.applyUserProgress(to: items)
                self.loadState = .loaded
            }
        }
    }

    func retry() {
        loadContent()
    }

    private func applyUserProgress(to items: [ContentItem]) -> [ContentItem] {
        items.map { item in
            var copy = item
            copy.isCompleted = progress.completedIds.contains(item.id)
            copy.isSaved = progress.savedIds.contains(item.id)
            return copy
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONTENT PRIORITIZATION ENGINE
    // ═══════════════════════════════════════════════════════════════════════════

    // TODO: Replace with ML scoring: getPersonalizedContent(user_id)
    // score = personalization_weight + recency_weight + popularity_weight

    func rankedContent(for category: ContentCategory? = nil) -> [ContentItem] {
        let filtered = category == nil ? allContent : allContent.filter { $0.category == category }
        return filtered.sorted { scoreItem($0) > scoreItem($1) }
    }

    private func scoreItem(_ item: ContentItem) -> Double {
        var score: Double = 0

        // Personalization: items matching user history rank higher
        if progress.historyIds.contains(item.id) { score += 5 }
        if item.isSaved { score += 8 }
        if !item.isCompleted { score += 3 }

        // Popularity
        score += Double(item.likes) / 100.0
        score += Double(item.views) / 1000.0

        // Recency boost for tagged content
        if item.tags.contains("NEW") { score += 10 }
        if item.tags.contains("Essential") { score += 6 }
        if item.tags.contains("Popular") { score += 4 }

        // Difficulty preference (beginners first for new users)
        if progress.completedCount < 5 && item.difficulty == .beginner { score += 5 }

        return score
    }

    // ── Filtered views ───────────────────────────────────────────────────────

    var shouldKnowItems: [ContentItem] {
        allContent.filter { ["sk1", "sk2", "sk3"].contains($0.id) }
    }

    var concernItems: [ContentItem] {
        allContent.filter { ["hc1", "hc2", "hc3"].contains($0.id) }
    }

    var lifestyleItems: [ContentItem] {
        allContent.filter { ["gl1", "gl2", "gl3"].contains($0.id) }
    }

    var courseItems: [ContentItem] {
        allContent.filter { $0.type == .course }
    }

    var articleItems: [ContentItem] {
        allContent.filter { $0.type == .article && !["sk1","sk2","sk3","hc1","hc2","hc3","gl1","gl2","gl3"].contains($0.id) }
    }

    var savedItems: [ContentItem] {
        allContent.filter { progress.savedIds.contains($0.id) }
    }

    var historyItems: [ContentItem] {
        progress.historyIds.compactMap { hid in allContent.first { $0.id == hid } }
    }

    var continueLearnItem: ContentItem? {
        guard let lastId = progress.lastViewedId else { return nil }
        return allContent.first { $0.id == lastId && !$0.isCompleted }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // USER ACTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    func toggleSave(_ item: ContentItem) {
        progress.toggleSaved(item.id)
        updateItemState(item.id, keyPath: \.isSaved, value: progress.savedIds.contains(item.id))
        saveProgress()
        // TODO: trackEvent("content_save", itemId: item.id)
    }

    func markViewed(_ item: ContentItem) {
        progress.addToHistory(item.id)
        saveProgress()
        // TODO: trackEvent("content_view", itemId: item.id)
    }

    func markCompleted(_ item: ContentItem) {
        progress.markCompleted(item.id)
        updateItemState(item.id, keyPath: \.isCompleted, value: true)
        saveProgress()
        // TODO: trackEvent("content_completed", itemId: item.id)
    }

    func toggleLike(_ item: ContentItem) {
        if let idx = allContent.firstIndex(where: { $0.id == item.id }) {
            allContent[idx].likes += 1
        }
        // TODO: trackEvent("content_like", itemId: item.id)
    }

    func updateCourseProgress(_ courseId: String, lessonIndex: Int, totalLessons: Int) {
        let prog = Double(lessonIndex + 1) / Double(totalLessons)
        progress.updateCourseProgress(courseId, progress: prog)
        saveProgress()
    }

    func courseProgress(for courseId: String) -> Double {
        progress.courseProgress[courseId] ?? 0
    }

    private func updateItemState<T>(_ id: String, keyPath: WritableKeyPath<ContentItem, T>, value: T) {
        if let idx = allContent.firstIndex(where: { $0.id == id }) {
            allContent[idx][keyPath: keyPath] = value
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PERSISTENCE (UserDefaults — TODO: migrate to Supabase)
    // ═══════════════════════════════════════════════════════════════════════════

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let saved = try? JSONDecoder().decode(UserProgress.self, from: data) {
            progress = saved
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CACHE (offline support — TODO: full SQLite/CoreData)
    // ═══════════════════════════════════════════════════════════════════════════

    func cacheContent() {
        if let data = try? JSONEncoder().encode(allContent) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }

    func loadCachedContent() -> [ContentItem]? {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        guard Date().timeIntervalSince1970 - timestamp < cacheTTL else { return nil }
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let items = try? JSONDecoder().decode([ContentItem].self, from: data) else { return nil }
        return items
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ANALYTICS (TODO: connect real analytics)
    // ═══════════════════════════════════════════════════════════════════════════

    func trackEvent(_ event: String, itemId: String? = nil, metadata: [String: String] = [:]) {
        // TODO: trackEvent(event, properties: [...])
        // TODO: track time spent on content
        #if DEBUG
        print("[Analytics] \(event) — item: \(itemId ?? "none") \(metadata)")
        #endif
    }
}
