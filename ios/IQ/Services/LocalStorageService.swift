import Foundation

// ── LocalStorageService — mirrors browser localStorage keys ───────────────
class LocalStorageService {
    static let shared = LocalStorageService()
    private let defaults = UserDefaults.standard

    // Keys (match STORAGE_KEYS in constants.ts)
    private enum Keys {
        static let symptoms  = "iq_symptom_entries"
        static let foods     = "iq_food_entries"
        static let profile   = "iq_user_profile"
        static let chat      = "iq_chat_history"
    }

    // ── Symptoms ──────────────────────────────────────────────────────────
    func loadSymptoms() -> [SymptomEntry] {
        decode([SymptomEntry].self, forKey: Keys.symptoms) ?? []
    }
    func saveSymptoms(_ entries: [SymptomEntry]) {
        encode(entries, forKey: Keys.symptoms)
    }

    // ── Food ──────────────────────────────────────────────────────────────
    func loadFoods() -> [FoodEntry] {
        decode([FoodEntry].self, forKey: Keys.foods) ?? []
    }
    func saveFoods(_ entries: [FoodEntry]) {
        encode(entries, forKey: Keys.foods)
    }

    // ── Profile ───────────────────────────────────────────────────────────
    func loadProfile() -> UserProfile? {
        decode(UserProfile.self, forKey: Keys.profile)
    }
    func saveProfile(_ profile: UserProfile) {
        encode(profile, forKey: Keys.profile)
    }

    // ── Chat ──────────────────────────────────────────────────────────────
    func loadChat() -> [ChatMessage] {
        decode([ChatMessage].self, forKey: Keys.chat) ?? []
    }
    func saveChat(_ messages: [ChatMessage]) {
        encode(messages, forKey: Keys.chat)
    }

    // ── Generic helpers ───────────────────────────────────────────────────
    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
