import Foundation

/// On-device personalization engine.
/// Tracks user history locally and computes conditional flare probabilities.
@MainActor
final class PersonalizationService: ObservableObject {
    static let shared = PersonalizationService()

    private let historyKey = "iq_user_log_history"
    private let minSamples = 5
    private let fullSamples = 30

    @Published private(set) var history: [[String: Double]] = []

    private init() { loadHistory() }

    // MARK: - History

    var daysLogged: Int { history.count }

    func addEntry(_ features: [String: Double], flare: Int) {
        var entry = features
        entry["flare"] = Double(flare)
        history.append(entry)
        saveHistory()
    }

    // MARK: - Personalization weight (cold-start ramp)

    var personalizationWeight: Double {
        let n = daysLogged
        if n < minSamples { return 0 }
        if n >= fullSamples { return 1 }
        return Double(n - minSamples) / Double(fullSamples - minSamples)
    }

    // MARK: - Conditional probability

    func conditionalProb(feature: String, threshold: Double) -> Double? {
        guard history.count >= minSamples else { return nil }
        let relevant = history.filter { ($0[feature] ?? 0) >= threshold }.compactMap { $0["flare"] }
        guard relevant.count >= 3 else { return nil }
        return relevant.reduce(0, +) / Double(relevant.count)
    }

    func multiFeatureProb(input: [String: Double]) -> Double? {
        var weightedSum = 0.0
        var weightTotal = 0.0

        for feature in ["pain", "stress", "diarrhea"] {
            let threshold = input[feature] ?? 0
            let relevant = history.filter { ($0[feature] ?? 0) >= threshold }.compactMap { $0["flare"] }
            if relevant.count >= 3 {
                let prob = relevant.reduce(0, +) / Double(relevant.count)
                weightedSum += prob * Double(relevant.count)
                weightTotal += Double(relevant.count)
            }
        }
        return weightTotal > 0 ? weightedSum / weightTotal : nil
    }

    // MARK: - Food impact (confound-corrected)

    func foodImpact(food: String, symptom: String) -> Double {
        guard history.count >= 10 else { return 0 }
        let stresses = history.compactMap { $0["stress"] }
        let medianStress = stresses.sorted()[stresses.count / 2]

        let withFood = history
            .filter { ($0[food] ?? 0) == 1 && abs(($0["stress"] ?? 5) - medianStress) <= 2 }
            .compactMap { $0[symptom] }

        let withoutFood = history
            .filter { ($0[food] ?? 0) == 0 && abs(($0["stress"] ?? 5) - medianStress) <= 2 }
            .compactMap { $0[symptom] }

        guard withFood.count >= 3, withoutFood.count >= 3 else { return 0 }
        let avgWith = withFood.reduce(0, +) / Double(withFood.count)
        let avgWithout = withoutFood.reduce(0, +) / Double(withoutFood.count)
        return avgWith - avgWithout
    }

    // MARK: - Feature contributions

    func featureContributions(input: [String: Double]) -> [String: Double] {
        var contributions: [String: Double] = [:]

        for (label, feature) in [("pain", "pain"), ("stress", "stress"), ("diarrhea", "diarrhea")] {
            let threshold = input[feature] ?? 0
            if let p = conditionalProb(feature: feature, threshold: threshold) {
                contributions[label] = p
            } else {
                contributions[label] = threshold > 6 ? 0.5 : 0.25
            }
        }

        let sleepHours = input["sleep_hours"] ?? 8
        let sleepEntries = history
            .filter { ($0["sleep_hours"] ?? 8) <= sleepHours }
            .compactMap { $0["flare"] }
        if sleepEntries.count >= 3 {
            contributions["sleep"] = sleepEntries.reduce(0, +) / Double(sleepEntries.count)
        } else {
            contributions["sleep"] = sleepHours < 5 ? 0.55 : 0.25
        }

        let daysSinceFlare = input["days_since_last_flare"] ?? 30
        contributions["recency"] = max(0, 0.8 - daysSinceFlare * 0.03)

        if (input["dairy"] ?? 0) == 1 {
            let impact = foodImpact(food: "dairy", symptom: "pain")
            contributions["dairy"] = min(1.0, 0.3 + impact / 10)
        }
        if (input["spicy_food"] ?? 0) == 1 {
            let impact = foodImpact(food: "spicy_food", symptom: "diarrhea")
            contributions["spicy_food"] = min(1.0, 0.3 + impact / 10)
        }

        return contributions
    }

    // MARK: - Persistence

    private func saveHistory() {
        if let data = try? JSONSerialization.data(withJSONObject: history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Double]] else { return }
        history = arr
    }
}
