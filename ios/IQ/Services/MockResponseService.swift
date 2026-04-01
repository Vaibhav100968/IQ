import Foundation

// ── Mirrors mock-responses.ts exactly ─────────────────────────────────────
struct MockResponseService {

    private struct Entry {
        let patterns: [String]
        let response: String
    }

    private static let entries: [Entry] = [
        Entry(patterns: ["what is crohn","crohn disease","crohns"],
              response: "Crohn’s disease causes inflammation of the digestive tract. It can affect any part of the GI tract from mouth to anus. Symptoms include abdominal pain, diarrhea, fatigue, weight loss, and malnutrition."),
        Entry(patterns: ["flare","flare up","what causes flare"],
              response: "Flare-ups in Crohn's disease can be triggered by various factors including certain foods (dairy, spicy, or high-fiber foods), stress, missed medications, infections, and NSAIDs. Keep logging your symptoms and food consistently!"),
        Entry(patterns: ["risk","why is my risk","risk high","risk score"],
              response: "Your risk score is calculated based on: recent symptom severity (35%), trigger food exposure (25%), symptom trends over 7 days (20%), historical patterns (10%), and natural language analysis (10%)."),
        Entry(patterns: ["diet","what should i eat","food","eat"],
              response: "During flare-ups, try bland low-fiber foods like white rice, bananas, toast, and cooked vegetables. Avoid dairy, spicy foods, alcohol, caffeine, and high-fiber foods. Track how foods affect you to identify your personal triggers."),
        Entry(patterns: ["stress","anxiety","mental","sleep"],
              response: "Stress is a well-known trigger for Crohn's flare-ups. Consider deep breathing, meditation, gentle exercise, and maintaining a regular sleep schedule."),
        Entry(patterns: ["medication","medicine","treatment"],
              response: "I'm not qualified to advise on specific medications. Please consult your gastroenterologist. I can help you track how symptoms respond over time."),
        Entry(patterns: ["prevention","prevent","avoid flare","reduce risk"],
              response: "Prevention Mode activates when risk is moderate or high. It shows foods to avoid based on your trigger history, safer alternatives, and behavioral tips.\n\nAsk me \"What happens if I eat [food]?\" to simulate impact on your risk score!"),
        Entry(patterns: ["help","what can you do","features"],
              response: "I can help you:\n• Explain your flare risk score\n• Simulate scenarios — \"What if I eat dairy?\"\n• Provide prevention recommendations\n• Suggest dietary considerations\n• Explain symptom trends\n• Answer Crohn's management questions"),
        Entry(patterns: ["tip","advice","suggest","recommend"],
              response: "Daily management tips:\n• Log symptoms at the same time each day\n• Track foods within 30 min of eating\n• Stay hydrated — 8 glasses of water daily\n• Note stress levels alongside symptoms\n• Review weekly trends every Sunday"),
    ]

    static let defaultResponse = "I'm here to help you manage your Crohn's disease. I can answer questions about symptoms, risk score, diet recommendations, and general management. Try asking \"What happens if I eat [food]?\" to simulate flare risk impact!"

    static func isScenarioQuery(_ input: String) -> Bool {
        let lower = input.lowercased()
        return lower.contains("what if") ||
               lower.contains("what happens") ||
               lower.contains("what would happen") ||
               lower.contains("should i eat") ||
               lower.contains("can i eat") ||
               (lower.contains("if i") && (lower.contains("eat") || lower.contains("drink") || lower.contains("skip")))
    }

    static func getResponse(_ input: String) -> String {
        let lower = input.lowercased()
        for entry in entries {
            for pattern in entry.patterns {
                if lower.contains(pattern) { return entry.response }
            }
        }
        return defaultResponse
    }
}
