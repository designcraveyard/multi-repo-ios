//
//  SupabaseManager.swift
//  multi-repo-ios
//
//  Singleton Supabase client. Reads credentials from Secrets.swift,
//  with optional override from Xcode scheme environment variables.
//

import Foundation
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // Prefer env vars (Xcode scheme) if set, fall back to compiled-in Secrets
        let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? Secrets.supabaseURL
        let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? Secrets.supabaseAnonKey

        guard let url = URL(string: urlString) else {
            fatalError("Invalid SUPABASE_URL: \(urlString)")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
