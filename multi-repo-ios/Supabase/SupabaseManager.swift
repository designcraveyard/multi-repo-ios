//
//  SupabaseManager.swift
//  multi-repo-ios
//
//  Singleton Supabase client. Reads credentials from Xcode scheme
//  environment variables (SUPABASE_URL, SUPABASE_ANON_KEY).
//

import Foundation
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let url = URL(string: urlString),
              let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        else {
            fatalError(
                """
                Missing Supabase credentials. Set SUPABASE_URL and SUPABASE_ANON_KEY \
                in your Xcode scheme environment variables.
                """
            )
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
