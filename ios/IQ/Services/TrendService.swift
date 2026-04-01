import Foundation

/// Computes time-series trend factors from recent user history.
struct TrendService {

    /// Extract trend features from the last 7 entries.
    static func extract(from history: [[String: Double]]) -> (painAvg: Double, stressAvg: Double, sleepTrend: Double) {
        let window = history.count >= 7 ? Array(history.suffix(7)) : history
        guard !window.isEmpty else { return (5, 5, 0) }

        let painAvg = window.compactMap { $0["pain"] }.reduce(0, +) / Double(window.count)
        let stressAvg = window.compactMap { $0["stress"] }.reduce(0, +) / Double(window.count)

        let sleepTrend: Double
        if window.count >= 2,
           let first = window.first?["sleep_hours"],
           let last = window.last?["sleep_hours"] {
            sleepTrend = last - first
        } else {
            sleepTrend = 0
        }

        return (painAvg, stressAvg, sleepTrend)
    }

    /// Compute a 0–1 trend factor from current input and recent averages.
    static func trendFactor(input: [String: Double], history: [[String: Double]]) -> Double {
        let (painAvg, stressAvg, _) = extract(from: history)
        let currentPain = input["pain"] ?? 5
        let currentSleep = input["sleep_hours"] ?? 7

        var factor = 0.35 * (painAvg / 10)
                   + 0.20 * (stressAvg / 10)
                   + 0.25 * (currentPain / 10)
                   - 0.50 * (currentSleep / 10)

        return max(0, min(1, factor))
    }
}
