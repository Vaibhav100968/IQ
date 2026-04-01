import Foundation

// ── IQConfig — fill in your credentials before building ────────────────────
enum IQConfig {
    // Backend API (run `python server.py` from backend/)
    // Simulator uses localhost; physical device uses your Mac's local IP.
    // Update localIP if your Mac's IP changes (run `ifconfig en0` to check).
    private static let localIP = "YOUR_LOCAL_IP"

    static var backendURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8000"
        #else
        return "http://\(localIP):8000"
        #endif
    }

    // Supabase project credentials (Settings → API in your Supabase dashboard)
    static let supabaseURL  = "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    // Google OAuth client ID (from console.cloud.google.com → Credentials → iOS app)
    static let googleClientID = "YOUR_GOOGLE_CLIENT_ID"

    // Custom URL scheme registered in Info.plist (for OAuth callbacks)
    static let oauthCallbackScheme = "iqapp"
}
