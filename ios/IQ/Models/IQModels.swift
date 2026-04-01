import Foundation

// ── Enums ──────────────────────────────────────────────────────────────────

enum SymptomType: String, Codable, CaseIterable, Identifiable {
    case abdominal_pain, diarrhea, fatigue, bloating
    case nausea, joint_pain, appetite_loss, cramping
    case urgency, blood_in_stool

    var id: String { rawValue }

    var label: String {
        switch self {
        case .abdominal_pain:  return "Abdominal Pain"
        case .diarrhea:        return "Diarrhea"
        case .fatigue:         return "Fatigue"
        case .bloating:        return "Bloating"
        case .nausea:          return "Nausea"
        case .joint_pain:      return "Joint Pain"
        case .appetite_loss:   return "Appetite Loss"
        case .cramping:        return "Cramping"
        case .urgency:         return "Urgency"
        case .blood_in_stool:  return "Blood in Stool"
        }
    }

    var icon: String {
        switch self {
        case .abdominal_pain, .cramping: return "bolt.fill"
        case .diarrhea, .urgency:        return "figure.run"
        case .fatigue:                   return "moon.fill"
        case .bloating:                  return "circle.fill"
        case .nausea:                    return "face.dashed"
        case .joint_pain:                return "figure.walk"
        case .appetite_loss:             return "fork.knife"
        case .blood_in_stool:            return "drop.fill"
        }
    }
}

enum FoodTag: String, Codable, CaseIterable, Identifiable {
    case dairy, gluten, spicy, fried, high_fiber
    case raw, alcohol, caffeine, processed, sugar, safe_food

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dairy:       return "Dairy"
        case .gluten:      return "Gluten"
        case .spicy:       return "Spicy"
        case .fried:       return "Fried"
        case .high_fiber:  return "High Fiber"
        case .raw:         return "Raw"
        case .alcohol:     return "Alcohol"
        case .caffeine:    return "Caffeine"
        case .processed:   return "Processed"
        case .sugar:       return "Sugar"
        case .safe_food:   return "Safe Food"
        }
    }

    var isTrigger: Bool { self != .safe_food }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.stars.fill"
        case .snack:     return "leaf.fill"
        }
    }
}

enum RiskLevel: String, Codable {
    case low, moderate, high

    var color: String {
        switch self { case .low: return "16a34a"; case .moderate: return "d97706"; case .high: return "c4458a" }
    }
    var bgColor: String {
        switch self { case .low: return "dcfce7"; case .moderate: return "fef3c7"; case .high: return "FFCAE9" }
    }
    var label: String {
        switch self { case .low: return "Low Risk"; case .moderate: return "Moderate Risk"; case .high: return "High Risk" }
    }
}

// ── Data Models ────────────────────────────────────────────────────────────

struct SymptomEntry: Codable, Identifiable, Equatable {
    var id: String
    var timestamp: Date
    var type: SymptomType
    var severity: Double
    var notes: String?

    init(type: SymptomType, severity: Double, notes: String? = nil) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.type = type
        self.severity = severity
        self.notes = notes
    }
}

struct FoodEntry: Codable, Identifiable, Equatable {
    var id: String
    var timestamp: Date
    var name: String
    var tags: [FoodTag]
    var mealType: MealType
    var portionSize: String?
    var spiceLevel: Int // 0 to 5
    var notes: String?

    init(name: String, tags: [FoodTag], mealType: MealType, portionSize: String? = nil, spiceLevel: Int = 0, notes: String? = nil) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.name = name
        self.tags = tags
        self.mealType = mealType
        self.portionSize = portionSize
        self.spiceLevel = spiceLevel
        self.notes = notes
    }
}

struct FlareRisk {
    var overallScore: Int
    var level: RiskLevel
    var timeWindow: String
    var explanation: String
    var symptomScore: Int
    var triggerScore: Int
    var trendScore: Int
    var patternScore: Int
}

struct UserProfile: Codable {
    var name: String
    var conditionType: ConditionType
    var severity: ConditionSeverity
    var knownTriggers: [FoodTag]
    var onboardingCompleted: Bool

    enum ConditionType: String, Codable, CaseIterable {
        case crohns, ulcerative_colitis, ibd_unspecified
        var label: String {
            switch self {
            case .crohns:              return "Crohn's Disease"
            case .ulcerative_colitis:  return "Ulcerative Colitis"
            case .ibd_unspecified:     return "Crohn’s (unspecified)"
            }
        }
    }

    enum ConditionSeverity: String, Codable, CaseIterable {
        case mild, moderate, severe
        var label: String { rawValue.capitalized }
    }
}

struct ChatMessage: Codable, Identifiable {
    var id: String
    var role: Role
    var content: String
    var timestamp: Date

    enum Role: String, Codable { case user, assistant }

    init(role: Role, content: String) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

struct PreFlareWarning {
    var detected: Bool
    var confidence: Int
    var message: String
}

struct ScenarioResult {
    var currentScore: Int
    var projectedScore: Int
    var delta: Int
    var explanation: String
}

// ── Helper ─────────────────────────────────────────────────────────────────

func severityLabel(_ s: Double) -> String {
    if s <= 3 { return "Mild" }
    if s <= 6 { return "Moderate" }
    return "Severe"
}

let triggerTags: [FoodTag] = [.dairy, .gluten, .spicy, .fried, .high_fiber, .raw, .alcohol, .caffeine, .processed, .sugar]
