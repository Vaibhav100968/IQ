import Foundation
import SwiftUI

// ── AppViewModel — central state ────────────────────────────────────────────
@MainActor
class AppViewModel: ObservableObject {

    // ── Persistence
    private let storage = LocalStorageService.shared

    // ── Navigation
    @Published var onboardingCompleted: Bool = false

    // ── Data
    @Published var symptoms:    [SymptomEntry] = []
    @Published var foods:       [FoodEntry]    = []
    @Published var profile:     UserProfile?   = nil
    @Published var chatHistory: [ChatMessage]  = []

    // ── Derived risk (rule-based)
    @Published var flareRisk: FlareRisk = FlareRisk(
        overallScore: 0, level: .low,
        timeWindow: "Low risk period",
        explanation: "Start logging to see your risk.",
        symptomScore: 0, triggerScore: 0, trendScore: 0, patternScore: 0
    )
    @Published var preFlare: PreFlareWarning = PreFlareWarning(detected: false, confidence: 0, message: "")

    // ── ML state (on-device Core ML)
    @Published var mlPrediction: OnDevicePrediction? = nil
    @Published var isMLLoading: Bool = false
    @Published var currentFeatures = MLFeatures()

    // ── Auth (userId shared with ML backend)
    var userId: String { AuthService.shared.userId }
    var isGuest: Bool  { AuthService.shared.isGuest }

    // ── Tab
    @Published var selectedTab: AppTab = .home

    /// Opens AI Assistant (e.g. from Home toolbar).
    @Published var assistantPresented: Bool = false

    // ── Chat state
    @Published var isChatLoading: Bool = false

    init() { loadAll() }

    /// Instant tab change (no TabView transition / blur animation).
    func selectTab(_ tab: AppTab) {
        var t = Transaction()
        t.animation = nil
        t.disablesAnimations = true
        withTransaction(t) {
            selectedTab = tab
        }
    }

    // ── Load ─────────────────────────────────────────────────────────────────
    func loadAll() {
        symptoms    = storage.loadSymptoms()
        foods       = storage.loadFoods()
        profile     = storage.loadProfile()
        chatHistory = storage.loadChat()
        onboardingCompleted = profile?.onboardingCompleted ?? false
        if selectedTab == .health { selectedTab = .discovery }
        recalcRisk()
        refreshCurrentFeatures()
    }

    func recalcRisk() {
        flareRisk = calculateFlareRisk(symptoms: symptoms, foods: foods, profile: profile)
        preFlare  = detectPreFlare(symptoms: symptoms)
    }

    // ── Symptoms ─────────────────────────────────────────────────────────────
    func addSymptom(_ entry: SymptomEntry) {
        symptoms.insert(entry, at: 0)
        storage.saveSymptoms(symptoms)
        recalcRisk()
        refreshCurrentFeatures()
    }

    func deleteSymptom(id: String) {
        symptoms.removeAll { $0.id == id }
        storage.saveSymptoms(symptoms)
        recalcRisk()
        refreshCurrentFeatures()
    }

    // ── Foods ─────────────────────────────────────────────────────────────────
    func addFood(_ entry: FoodEntry) {
        foods.insert(entry, at: 0)
        storage.saveFoods(foods)
        recalcRisk()
        refreshCurrentFeatures()
    }

    func deleteFood(id: String) {
        foods.removeAll { $0.id == id }
        storage.saveFoods(foods)
        recalcRisk()
        refreshCurrentFeatures()
    }

    // ── Profile ───────────────────────────────────────────────────────────────
    func saveProfile(_ p: UserProfile) {
        profile = p
        storage.saveProfile(p)
        onboardingCompleted = p.onboardingCompleted
        recalcRisk()
    }

    // ── ML Prediction (on-device Core ML) ────────────────────────────────────
    @Published var mlError: String? = nil

    func fetchMLPrediction() {
        isMLLoading = true
        mlError = nil
        let engine = PredictionEngine.shared
        guard engine.isReady else {
            mlError = "Core ML model not loaded"
            isMLLoading = false
            return
        }
        mlPrediction = engine.predict(features: currentFeatures.dictionary)
        isMLLoading = false
    }

    func runSimulate(changes: [String: Double]) -> OnDeviceSimulation? {
        let engine = PredictionEngine.shared
        guard engine.isReady else { return nil }
        return engine.simulate(features: currentFeatures.dictionary, changes: changes)
    }

    // Build MLFeatures from today's logged symptoms + foods
    func refreshCurrentFeatures() {
        let cal = Calendar.current
        let todaySymptoms = symptoms.filter { cal.isDateInToday($0.timestamp) }
        let todayFoods    = foods.filter    { cal.isDateInToday($0.timestamp) }

        func avg(_ type: SymptomType) -> Double {
            let vals = todaySymptoms.filter { $0.type == type }.map(\.severity)
            return vals.isEmpty ? 0 : vals.reduce(0,+) / Double(vals.count)
        }
        func hasTag(_ tag: FoodTag) -> Double {
            todayFoods.contains(where: { $0.tags.contains(tag) }) ? 1 : 0
        }

        // Days since last flare: approximate using last blood_in_stool or pain > 8
        let lastFlare = symptoms
            .filter { $0.type == .blood_in_stool || ($0.type == .abdominal_pain && $0.severity >= 8) }
            .sorted { $0.timestamp > $1.timestamp }
            .first?.timestamp
        let daysSince: Double
        if let lf = lastFlare {
            daysSince = Double(cal.dateComponents([.day], from: lf, to: Date()).day ?? 30)
        } else {
            daysSince = 30
        }

        var f = MLFeatures()
        f.pain           = avg(.abdominal_pain)
        f.diarrhea       = avg(.diarrhea)
        f.fatigue        = avg(.fatigue)
        f.bloating       = avg(.bloating)
        f.nausea         = avg(.nausea)
        f.cramping       = avg(.cramping)
        f.urgency        = avg(.urgency)
        f.appetite_loss  = avg(.appetite_loss)
        f.blood_in_stool = avg(.blood_in_stool)
        f.dairy          = hasTag(.dairy)
        f.spicy_food     = hasTag(.spicy)
        f.fiber          = hasTag(.high_fiber)
        f.days_since_last_flare = daysSince
        // sleep_hours and stress default to 7/5 — not tracked in current app
        currentFeatures = f
    }

    // ── Chat ──────────────────────────────────────────────────────────────────
    func sendMessage(_ text: String) {
        let userMsg = ChatMessage(role: .user, content: text)
        chatHistory.append(userMsg)
        isChatLoading = true
        storage.saveChat(chatHistory)

        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                let responseText: String
                if MockResponseService.isScenarioQuery(text) {
                    let result = simulateScenario(input: text, currentScore: flareRisk.overallScore,
                                                  symptoms: symptoms, foods: foods, profile: profile)
                    responseText = result.explanation
                } else {
                    responseText = MockResponseService.getResponse(text)
                }
                let assistantMsg = ChatMessage(role: .assistant, content: responseText)
                chatHistory.append(assistantMsg)
                storage.saveChat(chatHistory)
                isChatLoading = false
            }
        }
    }

    func clearChat() {
        chatHistory = []
        storage.saveChat(chatHistory)
    }

    // ── Today stats ──────────────────────────────────────────────────────────
    var todaySymptomCount: Int {
        let cal = Calendar.current
        return symptoms.filter { cal.isDateInToday($0.timestamp) }.count
    }

    var todayMealCount: Int {
        let cal = Calendar.current
        return foods.filter { cal.isDateInToday($0.timestamp) }.count
    }

    var todayTotal: Int { todaySymptomCount + todayMealCount }

    func logCountForDate(_ date: Date) -> Int {
        let cal = Calendar.current
        let s = symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) }.count
        let f = foods.filter    { cal.isDate($0.timestamp, inSameDayAs: date) }.count
        return s + f
    }

    // MARK: - Per-day ML features (flare prediction calendar)

    /// Feature vector for a specific calendar day (historical logging).
    func mlFeatures(forDay date: Date) -> MLFeatures {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let daySymptoms = symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: dayStart) }
        let dayFoods = foods.filter { cal.isDate($0.timestamp, inSameDayAs: dayStart) }

        func avg(_ type: SymptomType) -> Double {
            let vals = daySymptoms.filter { $0.type == type }.map(\.severity)
            return vals.isEmpty ? 0 : vals.reduce(0, +) / Double(vals.count)
        }
        func hasTag(_ tag: FoodTag) -> Double {
            dayFoods.contains(where: { $0.tags.contains(tag) }) ? 1 : 0
        }

        let endOfDay = dayStart.addingTimeInterval(86400 - 1)
        let lastFlareBefore = symptoms
            .filter { $0.timestamp <= endOfDay }
            .filter { $0.type == .blood_in_stool || ($0.type == .abdominal_pain && $0.severity >= 8) }
            .sorted { $0.timestamp > $1.timestamp }
            .first?.timestamp

        let daysSince: Double
        if let lf = lastFlareBefore {
            daysSince = Double(max(0, cal.dateComponents([.day], from: lf, to: dayStart).day ?? 0))
        } else {
            daysSince = 30
        }

        var f = MLFeatures()
        f.pain = avg(.abdominal_pain)
        f.diarrhea = avg(.diarrhea)
        f.fatigue = avg(.fatigue)
        f.bloating = avg(.bloating)
        f.nausea = avg(.nausea)
        f.cramping = avg(.cramping)
        f.urgency = avg(.urgency)
        f.appetite_loss = avg(.appetite_loss)
        f.blood_in_stool = avg(.blood_in_stool)
        f.dairy = hasTag(.dairy)
        f.spicy_food = hasTag(.spicy)
        f.fiber = hasTag(.high_fiber)
        f.days_since_last_flare = daysSince
        return f
    }

    /// Slightly evolve current features for future-day forecasts.
    func projectedMLFeatures(daysAheadFromToday: Int) -> MLFeatures {
        var f = currentFeatures
        f.days_since_last_flare = min(90, f.days_since_last_flare + Double(max(0, daysAheadFromToday)))
        let wobble = sin(Double(daysAheadFromToday) * 0.65) * 1.15
        f.stress = min(10, max(0, f.stress + wobble))
        f.sleep_hours = min(10, max(4, f.sleep_hours - abs(wobble) * 0.12))
        return f
    }

    /// On-device prediction for any calendar day (past uses that day’s logs; future uses projection).
    func onDevicePrediction(forDay date: Date) -> OnDevicePrediction? {
        guard PredictionEngine.shared.isReady else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let d = cal.startOfDay(for: date)
        let features: MLFeatures
        if d > today {
            let ahead = cal.dateComponents([.day], from: today, to: d).day ?? 0
            features = projectedMLFeatures(daysAheadFromToday: ahead)
        } else {
            features = mlFeatures(forDay: date)
        }
        return PredictionEngine.shared.predict(features: features.dictionary)
    }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────
enum AppTab: String, CaseIterable {
    case home, symptoms, food, calendar, analytics, health, discovery, profile

    var title: String {
        switch self {
        case .home:      return "Today"
        case .symptoms:  return "Calendar"
        case .food:      return "Calendar"
        case .calendar:  return "Analysis"
        case .analytics: return "Analysis"
        case .health, .discovery: return "Content"
        case .profile:   return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "sun.max.fill"
        case .symptoms:  return "calendar"
        case .food:      return "calendar"
        case .calendar:  return "chart.xyaxis.line"
        case .analytics: return "chart.xyaxis.line"
        case .health, .discovery: return "book.fill"
        case .profile:   return "person.fill"
        }
    }

    /// Tab bar order: Today · Calendar · Analysis · Content · Profile
    static let primaryTabs: [AppTab] = [.home, .symptoms, .analytics, .discovery, .profile]
}
