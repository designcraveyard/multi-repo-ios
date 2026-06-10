// Config.swift — Supabase credentials accessor.
// Reads from Secrets.swift (compiled in) with env var override.
import Foundation

enum SupabaseConfig {
    // Accept both `SUPABASE_URL` and the web-style `NEXT_PUBLIC_SUPABASE_URL`
    // so the same env var names work across the Xcode scheme and `.env.local`.
    static let url = URL(string:
        ProcessInfo.processInfo.environment["SUPABASE_URL"]
        ?? ProcessInfo.processInfo.environment["NEXT_PUBLIC_SUPABASE_URL"]
        ?? Secrets.supabaseURL
    )!
    static let anonKey: String =
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? ProcessInfo.processInfo.environment["NEXT_PUBLIC_SUPABASE_ANON_KEY"]
        ?? Secrets.supabaseAnonKey
}
