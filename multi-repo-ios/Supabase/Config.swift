// Config.swift — Supabase credentials accessor.
// Reads from Secrets.swift (compiled in) with env var override.
import Foundation

enum SupabaseConfig {
    static let url = URL(string:
        ProcessInfo.processInfo.environment["SUPABASE_URL"]
        ?? Secrets.supabaseURL
    )!
    static let anonKey: String =
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? Secrets.supabaseAnonKey
}
