import SwiftUI

// TODO: Replace mock data with Supabase content table
// TODO: Connect ML personalization layer
// TODO: Add web-scraped content pipeline
// TODO: fetchContent() / processContent() / storeContent()

// ── Content Type ─────────────────────────────────────────────────────────────

enum ContentType: String, Codable, CaseIterable {
    case article, video, course, quiz

    var icon: String {
        switch self {
        case .article: return "doc.text.fill"
        case .video:   return "play.rectangle.fill"
        case .course:  return "book.fill"
        case .quiz:    return "questionmark.diamond.fill"
        }
    }

    var label: String {
        switch self {
        case .article: return "Article"
        case .video:   return "Video"
        case .course:  return "Course"
        case .quiz:    return "Quiz"
        }
    }
}

// ── Content Category ─────────────────────────────────────────────────────────

enum ContentCategory: String, Codable, CaseIterable, Identifiable {
    case dietGut, flareTriggers, symptoms, mentalHealth, dailyHabits, research
    var id: String { rawValue }

    var label: String {
        switch self {
        case .dietGut:       return "Diet & Gut"
        case .flareTriggers: return "Flare Triggers"
        case .symptoms:      return "Symptoms"
        case .mentalHealth:  return "Mental Health"
        case .dailyHabits:   return "Daily Habits"
        case .research:      return "Research"
        }
    }

    var icon: String {
        switch self {
        case .dietGut:       return "fork.knife"
        case .flareTriggers: return "flame.fill"
        case .symptoms:      return "waveform.path.ecg"
        case .mentalHealth:  return "brain.head.profile"
        case .dailyHabits:   return "sun.max.fill"
        case .research:      return "microscope"
        }
    }

    var color: Color {
        switch self {
        case .dietGut:       return Color(hex: "e67e22")
        case .flareTriggers: return Color(hex: "c4458a")
        case .symptoms:      return Color(hex: "5057d5")
        case .mentalHealth:  return Color(hex: "7c3aed")
        case .dailyHabits:   return Color(hex: "16a34a")
        case .research:      return Color(hex: "0ea5e9")
        }
    }

    var gradient: [Color] {
        switch self {
        case .dietGut:       return [Color(hex: "fef3c7"), Color(hex: "fffbeb")]
        case .flareTriggers: return [Color(hex: "FFCAE9"), Color(hex: "fff5fb")]
        case .symptoms:      return [Color(hex: "CDD0F8"), Color(hex: "F5F4FF")]
        case .mentalHealth:  return [Color(hex: "ede9fe"), Color(hex: "f5f3ff")]
        case .dailyHabits:   return [Color(hex: "dcfce7"), Color(hex: "f0fdf4")]
        case .research:      return [Color(hex: "e0f2fe"), Color(hex: "f0f9ff")]
        }
    }
}

// ── Content Difficulty ───────────────────────────────────────────────────────

enum ContentDifficulty: String, Codable {
    case beginner, intermediate, advanced

    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .beginner:     return Color(hex: "16a34a")
        case .intermediate: return Color(hex: "d97706")
        case .advanced:     return Color(hex: "c4458a")
        }
    }
}

// ── Content Item (Production Schema) ─────────────────────────────────────────

struct ContentItem: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var description: String
    var type: ContentType
    var category: ContentCategory
    var tags: [String]
    var difficulty: ContentDifficulty
    var duration: String?
    var isPremium: Bool
    var isCompleted: Bool
    var isSaved: Bool
    var views: Int
    var likes: Int
    var icon: String
    var sections: [ContentSection]
    var lessons: [CourseLesson]
    var relatedIds: [String]

    static func == (lhs: ContentItem, rhs: ContentItem) -> Bool { lhs.id == rhs.id }

    init(id: String = UUID().uuidString, title: String, description: String,
         type: ContentType = .article, category: ContentCategory,
         tags: [String] = [], difficulty: ContentDifficulty = .beginner,
         duration: String? = nil, isPremium: Bool = false,
         isCompleted: Bool = false, isSaved: Bool = false,
         views: Int = 0, likes: Int = 0, icon: String = "doc.text.fill",
         sections: [ContentSection] = [], lessons: [CourseLesson] = [],
         relatedIds: [String] = []) {
        self.id = id; self.title = title; self.description = description
        self.type = type; self.category = category; self.tags = tags
        self.difficulty = difficulty; self.duration = duration
        self.isPremium = isPremium; self.isCompleted = isCompleted
        self.isSaved = isSaved; self.views = views; self.likes = likes
        self.icon = icon; self.sections = sections; self.lessons = lessons
        self.relatedIds = relatedIds
    }
}

// ── Content Section (for articles) ───────────────────────────────────────────

struct ContentSection: Identifiable, Codable {
    let id: String
    var heading: String
    var body: String
    var isKeyInsight: Bool

    init(id: String = UUID().uuidString, heading: String, body: String, isKeyInsight: Bool = false) {
        self.id = id; self.heading = heading; self.body = body; self.isKeyInsight = isKeyInsight
    }
}

// ── Course Lesson ────────────────────────────────────────────────────────────

struct CourseLesson: Identifiable, Codable {
    let id: String
    var title: String
    var duration: String
    var isLocked: Bool
    var isCompleted: Bool
    var type: ContentType

    init(id: String = UUID().uuidString, title: String, duration: String = "3 min",
         isLocked: Bool = false, isCompleted: Bool = false, type: ContentType = .article) {
        self.id = id; self.title = title; self.duration = duration
        self.isLocked = isLocked; self.isCompleted = isCompleted; self.type = type
    }
}

// ── Expert ────────────────────────────────────────────────────────────────────

struct Expert: Identifiable {
    let id: String
    var name: String
    var specialty: String
    var bio: String
    var initial: String
    var accentColor: Color

    init(id: String = UUID().uuidString, name: String, specialty: String,
         bio: String, initial: String? = nil, accentColor: Color = Color(hex: "5057d5")) {
        self.id = id; self.name = name; self.specialty = specialty
        self.bio = bio; self.initial = initial ?? String(name.prefix(1))
        self.accentColor = accentColor
    }
}

// ── User Progress ────────────────────────────────────────────────────────────

struct UserProgress: Codable {
    var completedIds: Set<String> = []
    var savedIds: Set<String> = []
    var historyIds: [String] = []
    var courseProgress: [String: Double] = [:]
    var lastViewedId: String?
    var totalTimeSpent: Int = 0

    var completedCount: Int { completedIds.count }

    mutating func markCompleted(_ id: String) {
        completedIds.insert(id)
    }

    mutating func toggleSaved(_ id: String) {
        if savedIds.contains(id) { savedIds.remove(id) }
        else { savedIds.insert(id) }
    }

    mutating func addToHistory(_ id: String) {
        historyIds.removeAll { $0 == id }
        historyIds.insert(id, at: 0)
        if historyIds.count > 50 { historyIds = Array(historyIds.prefix(50)) }
        lastViewedId = id
    }

    mutating func updateCourseProgress(_ courseId: String, progress: Double) {
        courseProgress[courseId] = min(progress, 1.0)
    }
}

// ── Content State ────────────────────────────────────────────────────────────

enum ContentLoadState: Equatable {
    case loading
    case loaded
    case empty
    case error(String)
}

// ── Quiz ─────────────────────────────────────────────────────────────────────

struct QuizQuestion: Identifiable {
    let id = UUID().uuidString
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOCK DATA — Production-structured content
// ═══════════════════════════════════════════════════════════════════════════════

struct MockContent {

    static let expert = Expert(
        name: "Dr. Sarah Chen",
        specialty: "Gastroenterology",
        bio: "15+ years specializing in Crohn’s care. Research focus on dietary interventions and flare prevention.",
        accentColor: Color(hex: "5057d5")
    )

    static let experts: [Expert] = [
        expert,
        Expert(name: "Dr. James Park", specialty: "Nutrition & Crohn’s", bio: "Dietitian specializing in anti-inflammatory nutrition for Crohn's patients.", accentColor: Color(hex: "16a34a")),
        Expert(name: "Dr. Mia Alvarez", specialty: "Gut-Brain Axis", bio: "Psychiatrist researching the connection between mental health and Crohn’s outcomes.", accentColor: Color(hex: "7c3aed")),
    ]

    // ── "Things You Should Know" ─────────────────────────────────────────────

    static let shouldKnow: [ContentItem] = [
        ContentItem(id: "sk1", title: "What Is a Flare?", description: "Understanding the inflammatory episodes that define Crohn's disease", category: .symptoms, tags: ["NEW", "Essential"], duration: "4 min", views: 3420, likes: 289, icon: "flame.fill",
            sections: [
                ContentSection(heading: "Overview", body: "A flare is a period of increased disease activity where inflammation intensifies in the digestive tract. Symptoms worsen noticeably — abdominal pain, diarrhea, fatigue, and sometimes fever."),
                ContentSection(heading: "What Triggers a Flare", body: "Triggers vary by person but commonly include stress, dietary changes, missed medications, infections, and sleep deprivation. Your personal trigger profile is unique.", isKeyInsight: true),
                ContentSection(heading: "How Long Do Flares Last", body: "Flares can last days to weeks. Early intervention — adjusting diet, managing stress, and consulting your doctor — can shorten their duration significantly."),
                ContentSection(heading: "What to Do", body: "Track symptoms daily, follow your treatment plan, rest, stay hydrated, and contact your care team if symptoms are severe or persistent."),
            ]),
        ContentItem(id: "sk2", title: "Why Inflammation Happens", description: "The biology behind your symptoms explained simply", category: .research, tags: ["Science"], duration: "6 min", views: 2810, likes: 198, icon: "bolt.fill",
            sections: [
                ContentSection(heading: "The Immune System Gone Wrong", body: "In Crohn's, your immune system mistakes harmless gut bacteria for invaders. It launches an inflammatory response that damages healthy tissue."),
                ContentSection(heading: "The Inflammatory Cascade", body: "Immune cells release cytokines — chemical signals that recruit more immune cells. This creates a self-reinforcing cycle of inflammation and tissue damage.", isKeyInsight: true),
                ContentSection(heading: "Why It's Chronic", body: "Unlike normal inflammation that resolves, Crohn's inflammation persists because the immune system doesn't turn off. This is why ongoing treatment is essential."),
            ]),
        ContentItem(id: "sk3", title: "Early Warning Signs", description: "How to recognize a flare before it hits", category: .symptoms, tags: ["Practical"], duration: "3 min", views: 4100, likes: 367, icon: "exclamationmark.triangle.fill",
            sections: [
                ContentSection(heading: "The Pre-Flare Window", body: "Most flares don't hit suddenly. There's usually a 24–72 hour window where subtle signs appear: increased fatigue, mild cramping, changes in stool frequency."),
                ContentSection(heading: "Track These Signals", body: "Pay attention to: sleep quality dropping, appetite changes, mild bloating after meals, and increased urgency. These patterns become clearer with consistent tracking.", isKeyInsight: true),
            ]),
    ]

    // ── "Healthy Concerns" ───────────────────────────────────────────────────

    static let concerns: [ContentItem] = [
        ContentItem(id: "hc1", title: "Chronic Inflammation", description: "Long-term effects on your body and how to manage them", category: .symptoms, tags: ["Important"], duration: "5 min", views: 1890, likes: 145, icon: "heart.fill",
            sections: [ContentSection(heading: "The Silent Damage", body: "Even when you feel okay, low-grade inflammation may be present. Over time, this can cause strictures, fistulas, and nutritional deficiencies. Regular monitoring is key.")]),
        ContentItem(id: "hc2", title: "Gut Lining Damage", description: "What happens to your intestinal wall during active disease", category: .research, difficulty: .intermediate, duration: "6 min", views: 1540, likes: 112, icon: "shield.lefthalf.filled",
            sections: [ContentSection(heading: "Barrier Breakdown", body: "Inflammation erodes the mucosal lining — your gut's protective barrier. This increases permeability ('leaky gut'), allowing bacteria to trigger more inflammation.", isKeyInsight: true)]),
        ContentItem(id: "hc3", title: "Nutrient Deficiencies", description: "Common deficiencies in Crohn's and how to address them", category: .dietGut, tags: ["Practical"], duration: "4 min", views: 2200, likes: 178, icon: "leaf.fill",
            sections: [ContentSection(heading: "What You May Be Missing", body: "Iron, B12, vitamin D, folate, and zinc are commonly deficient in Crohn's patients. Inflammation reduces absorption, and restricted diets compound the problem.")]),
    ]

    // ── "Your Gut & Lifestyle" ───────────────────────────────────────────────

    static let lifestyle: [ContentItem] = [
        ContentItem(id: "gl1", title: "Food and Flare Cycles", description: "How diet patterns influence symptom cycles", category: .dietGut, tags: ["Personalized"], duration: "5 min", views: 3890, likes: 312, icon: "fork.knife",
            sections: [ContentSection(heading: "The Food-Inflammation Loop", body: "Certain foods trigger immune responses in your gut. When consumed repeatedly, they create a cycle: inflammation → sensitivity → more inflammation. Elimination diets help identify your specific triggers.", isKeyInsight: true)]),
        ContentItem(id: "gl2", title: "Sleep and Gut Recovery", description: "Why quality sleep is your gut's best medicine", category: .dailyHabits, duration: "4 min", views: 2670, likes: 234, icon: "moon.fill",
            sections: [ContentSection(heading: "The Repair Window", body: "During deep sleep, your body produces anti-inflammatory cytokines and repairs gut tissue. Sleep deprivation increases TNF-α levels — a key driver of Crohn's inflammation.")]),
        ContentItem(id: "gl3", title: "Stress and Inflammation", description: "The gut-brain axis and why stress management matters", category: .mentalHealth, tags: ["Essential"], duration: "5 min", views: 3100, likes: 267, icon: "brain",
            sections: [ContentSection(heading: "How Stress Fuels Flares", body: "Stress activates your HPA axis, releasing cortisol. Chronic cortisol disrupts gut barrier function and alters your microbiome composition, creating conditions for flares.", isKeyInsight: true)]),
    ]

    // ── Courses ──────────────────────────────────────────────────────────────

    static let courses: [ContentItem] = [
        ContentItem(id: "c1", title: "Flare Management 101", description: "A structured guide to recognizing, managing, and preventing flares", type: .course, category: .symptoms, tags: ["Popular"], difficulty: .beginner, duration: "25 min", views: 5200, likes: 489, icon: "flame.fill",
            lessons: [
                CourseLesson(title: "What is a Flare?", duration: "4 min", isCompleted: true),
                CourseLesson(title: "Recognizing Early Signs", duration: "5 min"),
                CourseLesson(title: "Emergency Action Plan", duration: "4 min"),
                CourseLesson(title: "Dietary Adjustments During Flares", duration: "6 min", isLocked: true),
                CourseLesson(title: "When to Contact Your Doctor", duration: "3 min", isLocked: true),
                CourseLesson(title: "Recovery & Prevention", duration: "5 min", isLocked: true, type: .video),
            ]),
        ContentItem(id: "c2", title: "Nutrition for Crohn’s", description: "Evidence-based dietary strategies for Crohn's management", type: .course, category: .dietGut, difficulty: .intermediate, duration: "40 min", isPremium: true, views: 3800, likes: 356, icon: "carrot.fill",
            lessons: [
                CourseLesson(title: "Anti-Inflammatory Foods", duration: "5 min"),
                CourseLesson(title: "The Low-FODMAP Approach", duration: "6 min"),
                CourseLesson(title: "Meal Planning During Remission", duration: "7 min", isLocked: true),
                CourseLesson(title: "Supplements That Help", duration: "5 min", isLocked: true),
            ]),
    ]

    // ── Articles Feed ────────────────────────────────────────────────────────

    static let articles: [ContentItem] = [
        ContentItem(id: "a1", title: "What Causes Crohn's Flares?", description: "A deep dive into the triggers behind inflammatory episodes", category: .flareTriggers, duration: "5 min", views: 4500, likes: 312, icon: "flame.fill",
            sections: [ContentSection(heading: "Multi-Factor Triggers", body: "Flares rarely have a single cause. They result from a combination of dietary, environmental, psychological, and immunological factors converging.")]),
        ContentItem(id: "a2", title: "Best Foods During Inflammation", description: "What to eat when your gut needs gentle support", category: .dietGut, tags: ["Practical"], duration: "4 min", views: 3200, likes: 278, icon: "leaf.fill",
            sections: [ContentSection(heading: "Gentle Nutrition", body: "Focus on bone broth, well-cooked vegetables, lean proteins, and bananas. Avoid raw vegetables, dairy, and high-fiber foods during active inflammation.")]),
        ContentItem(id: "a3", title: "Why Fatigue Happens", description: "Understanding the exhaustion that comes with Crohn's", category: .symptoms, duration: "3 min", views: 2800, likes: 234, icon: "battery.25",
            sections: [ContentSection(heading: "More Than Just Tiredness", body: "Crohn's fatigue has multiple drivers: chronic inflammation diverts energy, nutrient malabsorption causes deficiencies, and disrupted sleep compounds exhaustion.", isKeyInsight: true)]),
        ContentItem(id: "a4", title: "The Gut-Brain Connection", description: "How your emotions directly influence your digestive health", category: .mentalHealth, tags: ["Science"], duration: "6 min", views: 2100, likes: 189, icon: "brain.head.profile",
            sections: [ContentSection(heading: "Bidirectional Communication", body: "Your gut produces 95% of your body's serotonin. The vagus nerve creates a direct line between gut and brain. When one suffers, the other responds.")]),
        ContentItem(id: "a5", title: "Exercise During a Flare", description: "Safe movement strategies when symptoms are active", category: .dailyHabits, duration: "3 min", views: 1900, likes: 156, icon: "figure.walk",
            sections: [ContentSection(heading: "Move Gently", body: "Walking, yoga, and stretching can reduce inflammation markers. Listen to your body — if it hurts, stop. Even 10 minutes helps.")]),
    ]

    // ── Quiz ─────────────────────────────────────────────────────────────────

    static let quizQuestions: [QuizQuestion] = [
        QuizQuestion(question: "Which nutrient deficiency is most common in Crohn's?", options: ["Vitamin C", "Iron", "Vitamin A", "Calcium"], correctIndex: 1, explanation: "Iron deficiency is the most common nutritional deficiency in Crohn's disease, affecting up to 75% of patients due to chronic bleeding and impaired absorption."),
        QuizQuestion(question: "What percentage of serotonin is produced in the gut?", options: ["50%", "75%", "95%", "30%"], correctIndex: 2, explanation: "About 95% of serotonin is produced in the gut, which is why digestive health directly impacts mood and mental well-being."),
        QuizQuestion(question: "Which of these can trigger a Crohn's flare?", options: ["Sleep deprivation", "Moderate walking", "Drinking water", "Reading"], correctIndex: 0, explanation: "Sleep deprivation increases inflammatory cytokines and disrupts gut barrier function, making it a significant flare trigger."),
    ]

    static var allContent: [ContentItem] {
        shouldKnow + concerns + lifestyle + courses + articles
    }
}
