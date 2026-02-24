// Config.swift — Supabase credentials
// Set SUPABASE_URL and SUPABASE_ANON_KEY in Xcode scheme environment variables.
// Never commit real credentials to source control.
import Foundation

enum SupabaseConfig {
    static let url = URL(string:
        ProcessInfo.processInfo.environment["SUPABASE_URL"]
        ?? "https://your-project-ref.supabase.co"
    )!
    static let anonKey: String =
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? "your-anon-key-here"
}
