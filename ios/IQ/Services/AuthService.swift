import Foundation
import AuthenticationServices

// ── AuthService — Supabase Auth via URLSession + Apple Sign-In + Guest ─────────
@MainActor
final class AuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {

    static let shared = AuthService()

    @Published var userId: String = ""
    @Published var isGuest: Bool = false
    @Published var isAuthenticated: Bool = false

    private let supabaseURL  = IQConfig.supabaseURL
    private let anonKey      = IQConfig.supabaseAnonKey
    private let guestKey     = "iq_guest_user_id"
    private let sessionKey   = "iq_supabase_user_id"

    override private init() {
        super.init()
        restoreSession()
    }

    // ── Restore existing session on app launch ────────────────────────────────
    private func restoreSession() {
        if let saved = UserDefaults.standard.string(forKey: sessionKey), !saved.isEmpty {
            userId = saved
            isAuthenticated = true
            isGuest = false
        } else if let guest = UserDefaults.standard.string(forKey: guestKey) {
            userId = guest
            isGuest = true
            isAuthenticated = true
        }
    }

    // ── Email + Password Sign-Up ──────────────────────────────────────────────
    func signUp(email: String, password: String) async throws {
        let uid = try await supabaseAuth(
            path: "/auth/v1/signup",
            body: ["email": email, "password": password]
        )
        persist(userId: uid, guest: false)
    }

    // ── Email + Password Sign-In ──────────────────────────────────────────────
    func signIn(email: String, password: String) async throws {
        let uid = try await supabaseAuth(
            path: "/auth/v1/token?grant_type=password",
            body: ["email": email, "password": password]
        )
        persist(userId: uid, guest: false)
    }

    // ── Google OAuth via ASWebAuthenticationSession ────────────────────────────
    func signInWithGoogle() async throws {
        let authorizeURL = "\(supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(IQConfig.oauthCallbackScheme)://auth/callback"
        guard let url = URL(string: authorizeURL) else { throw URLError(.badURL) }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: IQConfig.oauthCallbackScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                // Parse access_token from fragment or query: iqapp://auth/callback#access_token=...
                guard let cbURL = callbackURL,
                      let fragment = cbURL.fragment ?? cbURL.query else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                var params: [String: String] = [:]
                for pair in fragment.components(separatedBy: "&") {
                    let kv = pair.components(separatedBy: "=")
                    if kv.count == 2 { params[kv[0]] = kv[1] }
                }
                // Supabase returns the user id in `user_id` or we decode the JWT sub
                if let uid = params["user_id"] ?? self.jwtSub(from: params["access_token"]) {
                    Task { @MainActor in
                        self.persist(userId: uid, guest: false)
                        continuation.resume()
                    }
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    // ── Guest Mode ────────────────────────────────────────────────────────────
    func continueAsGuest() {
        let gid = UserDefaults.standard.string(forKey: guestKey) ?? UUID().uuidString
        UserDefaults.standard.set(gid, forKey: guestKey)
        persist(userId: gid, guest: true)
    }

    // ── Sign Out ──────────────────────────────────────────────────────────────
    func signOut() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        userId = ""
        isGuest = false
        isAuthenticated = false
    }

    // ── ASWebAuthenticationPresentationContextProviding ───────────────────────
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }

    // ── Private helpers ───────────────────────────────────────────────────────
    private func persist(userId uid: String, guest: Bool) {
        userId = uid
        isGuest = guest
        isAuthenticated = true
        if !guest {
            UserDefaults.standard.set(uid, forKey: sessionKey)
        }
    }

    private func supabaseAuth(path: String, body: [String: String]) async throws -> String {
        guard let url = URL(string: supabaseURL + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Auth error"
            throw NSError(domain: "AuthService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        // Sign-in returns { user: { id: "..." } }
        if let user = json["user"] as? [String: Any],
           let id = user["id"] as? String {
            return id
        }
        // Sign-up (with email confirmation ON) returns { id: "..." } at root
        if let id = json["id"] as? String {
            return id
        }
        throw URLError(.userAuthenticationRequired)
    }

    /// Decode JWT payload and extract `sub` (user id)
    private func jwtSub(from token: String?) -> String? {
        guard let token else { return nil }
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        var base64 = parts[1]
        let rem = base64.count % 4
        if rem > 0 { base64 += String(repeating: "=", count: 4 - rem) }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else { return nil }
        return sub
    }
}
