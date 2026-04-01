import Foundation

// ── ML feature set sent to the backend ────────────────────────────────────────
struct MLFeatures: Codable {
    // Symptoms (0–10 scale)
    var pain:           Double = 0
    var diarrhea:       Double = 0
    var fatigue:        Double = 0
    var bloating:       Double = 0
    var nausea:         Double = 0
    var cramping:       Double = 0
    var urgency:        Double = 0
    var appetite_loss:  Double = 0
    var blood_in_stool: Double = 0
    // Lifestyle
    var sleep_hours:          Double = 7
    var stress:               Double = 5
    var dairy:                Double = 0   // 0 or 1
    var spicy_food:            Double = 0   // 0 or 1
    var fiber:                Double = 0   // 0 or 1
    var days_since_last_flare: Double = 30

    // Convert to plain [String: Double] for JSON body
    var dictionary: [String: Double] {
        [
            "pain": pain, "diarrhea": diarrhea, "fatigue": fatigue,
            "bloating": bloating, "nausea": nausea, "cramping": cramping,
            "urgency": urgency, "appetite_loss": appetite_loss,
            "blood_in_stool": blood_in_stool, "sleep_hours": sleep_hours,
            "stress": stress, "dairy": dairy, "spicy_food": spicy_food,
            "fiber": fiber, "days_since_last_flare": days_since_last_flare,
        ]
    }
}

// ── Full prediction response from /predict ─────────────────────────────────────
struct MLPrediction: Codable {
    let finalRisk:              Double
    let globalProb:             Double
    let personalProb:           Double?
    let personalizationWeight:  Double
    let trendFactor:            Double
    let featureContributions:   [String: Double]
    let daysLogged:             Int
    let riskFactors:            [String]
    let protectiveFactors:      [String]
    let personalizationStatus:  String

    enum CodingKeys: String, CodingKey {
        case finalRisk             = "final_risk"
        case globalProb            = "global_prob"
        case personalProb          = "personal_prob"
        case personalizationWeight = "personalization_weight"
        case trendFactor           = "trend_factor"
        case featureContributions  = "feature_contributions"
        case daysLogged            = "days_logged"
        case riskFactors           = "risk_factors"
        case protectiveFactors     = "protective_factors"
        case personalizationStatus = "personalization_status"
    }

    var riskPercent: Int { Int(finalRisk * 100) }

    var riskLabel: String {
        if finalRisk < 0.3 { return "Low" }
        if finalRisk < 0.7 { return "Moderate" }
        return "High"
    }
}

// ── Simulate response from /simulate ──────────────────────────────────────────
struct MLSimulateResult: Codable {
    let originalRisk:  Double
    let newRisk:       Double
    let delta:         Double
    let interpretation: String

    enum CodingKeys: String, CodingKey {
        case originalRisk  = "original_risk"
        case newRisk       = "new_risk"
        case delta
        case interpretation
    }

    var newRiskPercent: Int { Int(newRisk * 100) }
    var deltaPercent:   Int { Int(abs(delta) * 100) }
    var isImprovement:  Bool { delta < 0 }
}
