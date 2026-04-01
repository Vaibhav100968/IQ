import Foundation

// ── MLService — thin URLSession wrapper around the FastAPI backend ─────────────
@MainActor
final class MLService {
    static let shared = MLService()
    private init() {}

    private let base = IQConfig.backendURL

    // ── /predict ─────────────────────────────────────────────────────────────
    func predict(userId: String, features: MLFeatures) async throws -> MLPrediction {
        let body: [String: Any] = [
            "user_id": userId,
            "features": features.dictionary,
        ]
        return try await post(path: "/predict", body: body)
    }

    // ── /simulate ────────────────────────────────────────────────────────────
    func simulate(userId: String, features: MLFeatures, changes: [String: Double]) async throws -> MLSimulateResult {
        let body: [String: Any] = [
            "user_id": userId,
            "features": features.dictionary,
            "changes": changes,
        ]
        return try await post(path: "/simulate", body: body)
    }

    // ── /log ─────────────────────────────────────────────────────────────────
    func logEntry(userId: String, features: MLFeatures, flare: Int = 0) async throws {
        let body: [String: Any] = [
            "user_id": userId,
            "log": features.dictionary,
            "flare": flare,
        ]
        let _: EmptyResponse = try await post(path: "/log", body: body)
    }

    // ── Generic POST ──────────────────────────────────────────────────────────
    private func post<T: Decodable>(path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: base + path) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 20

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MLService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct EmptyResponse: Decodable {}
