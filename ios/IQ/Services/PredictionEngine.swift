import Foundation
import CoreML

/// On-device prediction engine combining Core ML + personalization + trends.
/// Replaces the remote MLService for instant, offline predictions.
@MainActor
final class PredictionEngine: ObservableObject {
    static let shared = PredictionEngine()

    private var coreMLModel: MLModel?
    private let personalization = PersonalizationService.shared

    @Published var latestPrediction: OnDevicePrediction?
    @Published var isReady = false

    private init() { loadModel() }

    // MARK: - Model loading

    private func loadModel() {
        guard let url = Bundle.main.url(forResource: "FlarePredictor", withExtension: "mlmodelc")
              ?? compileModel() else {
            print("⚠️ FlarePredictor model not found")
            return
        }
        do {
            coreMLModel = try MLModel(contentsOf: url)
            isReady = true
        } catch {
            print("⚠️ Core ML load error: \(error)")
        }
    }

    private func compileModel() -> URL? {
        guard let asset = Bundle.main.url(forResource: "FlarePredictor", withExtension: "mlmodel") else { return nil }
        return try? MLModel.compileModel(at: asset)
    }

    // MARK: - Predict

    func predict(features: [String: Double]) -> OnDevicePrediction {
        let history = personalization.history
        let (painAvg, stressAvg, sleepTrend) = TrendService.extract(from: history)

        var input = features
        input["pain_3d_avg"] = painAvg
        input["stress_3d_avg"] = stressAvg
        input["sleep_trend"] = sleepTrend

        // Apply food adjustments
        let dairyEffect = personalization.foodImpact(food: "dairy", symptom: "pain")
        let spicyEffect = personalization.foodImpact(food: "spicy_food", symptom: "diarrhea")
        if (input["dairy"] ?? 0) == 1 { input["pain"] = min(10, (input["pain"] ?? 0) + dairyEffect) }
        if (input["spicy_food"] ?? 0) == 1 { input["diarrhea"] = min(10, (input["diarrhea"] ?? 0) + spicyEffect) }

        // Global model probability
        let globalProb = coreMLPredict(input: input)

        // Personal probability
        let personalProb = personalization.multiFeatureProb(input: input)

        // Trend factor
        let trend = TrendService.trendFactor(input: input, history: history)

        // Blend
        let pw = personalization.personalizationWeight
        let finalRisk: Double
        if let pp = personalProb {
            finalRisk = (1 - pw) * (0.6 * globalProb + 0.4 * trend)
                      + pw * (0.4 * globalProb + 0.4 * pp + 0.2 * trend)
        } else {
            finalRisk = 0.6 * globalProb + 0.4 * trend
        }

        // Contributions
        let contributions = personalization.featureContributions(input: input)

        // Explanation
        let (riskFactors, protectiveFactors) = buildExplanation(contributions: contributions)

        let prediction = OnDevicePrediction(
            finalRisk: max(0, min(1, finalRisk)),
            globalProb: globalProb,
            personalProb: personalProb,
            personalizationWeight: pw,
            trendFactor: trend,
            featureContributions: contributions,
            daysLogged: personalization.daysLogged,
            riskFactors: riskFactors,
            protectiveFactors: protectiveFactors
        )

        latestPrediction = prediction
        return prediction
    }

    // MARK: - Simulate (what-if)

    func simulate(features: [String: Double], changes: [String: Double]) -> OnDeviceSimulation {
        let original = predict(features: features)
        var modified = features
        for (k, v) in changes { modified[k] = v }
        let newResult = predict(features: modified)
        let delta = newResult.finalRisk - original.finalRisk

        return OnDeviceSimulation(
            originalRisk: original.finalRisk,
            newRisk: newResult.finalRisk,
            delta: delta,
            interpretation: "Risk \(delta < 0 ? "decreases" : "increases") by \(String(format: "%.1f", abs(delta) * 100))% with these changes."
        )
    }

    // MARK: - Log entry

    func logEntry(features: [String: Double], flare: Int) {
        personalization.addEntry(features, flare: flare)
    }

    // MARK: - Core ML inference

    private func coreMLPredict(input: [String: Double]) -> Double {
        guard let model = coreMLModel else { return 0.5 }

        let featureOrder = [
            "sleep_hours", "stress", "pain", "diarrhea", "fatigue", "bloating",
            "nausea", "cramping", "urgency", "appetite_loss", "blood_in_stool",
            "dairy", "spicy_food", "fiber", "days_since_last_flare",
            "pain_3d_avg", "stress_3d_avg", "sleep_trend"
        ]

        let provider = try? MLDictionaryFeatureProvider(dictionary:
            Dictionary(uniqueKeysWithValues: featureOrder.map { ($0, MLFeatureValue(double: input[$0] ?? 0)) })
        )

        guard let provider, let output = try? model.prediction(from: provider) else { return 0.5 }

        if let probDict = output.featureValue(for: "classProbability")?.dictionaryValue,
           let flareProb = probDict[1 as NSNumber] as? Double {
            return flareProb
        }
        return 0.5
    }

    // MARK: - Explanation

    private func buildExplanation(contributions: [String: Double]) -> (risk: [String], protective: [String]) {
        let labels: [String: String] = [
            "pain": "High pain", "stress": "High stress", "diarrhea": "Frequent diarrhea",
            "sleep": "Poor sleep", "recency": "Recent previous flare",
            "dairy": "Dairy consumption", "spicy_food": "Spicy food consumption"
        ]

        var risk: [String] = []
        var protective: [String] = []

        for (feature, contrib) in contributions.sorted(by: { $0.value > $1.value }) {
            let label = labels[feature] ?? feature
            if contrib >= 0.55 {
                risk.append("\(label) (\(Int(contrib * 100))%)")
            } else if contrib <= 0.35 {
                protective.append("\(label) (\(Int(contrib * 100))%)")
            }
        }
        return (risk, protective)
    }
}

// MARK: - Data types

struct OnDevicePrediction {
    let finalRisk: Double
    let globalProb: Double
    let personalProb: Double?
    let personalizationWeight: Double
    let trendFactor: Double
    let featureContributions: [String: Double]
    let daysLogged: Int
    let riskFactors: [String]
    let protectiveFactors: [String]

    var riskPercent: Int { Int(finalRisk * 100) }
    var riskLabel: String {
        if finalRisk < 0.3 { return "Low" }
        if finalRisk < 0.7 { return "Moderate" }
        return "High"
    }
    var personalizationStatus: String {
        if personalizationWeight == 0 { return "Using general model — log more days to personalize (\(daysLogged)/5 needed)" }
        if personalizationWeight < 1.0 { return "Personalizing (\(daysLogged)/30 days, \(Int(personalizationWeight * 100))% personalized)" }
        return "Fully personalized (\(daysLogged) days logged)"
    }
}

struct OnDeviceSimulation {
    let originalRisk: Double
    let newRisk: Double
    let delta: Double
    let interpretation: String

    var newRiskPercent: Int { Int(newRisk * 100) }
    var deltaPercent: Int { Int(abs(delta) * 100) }
    var isImprovement: Bool { delta < 0 }
}
