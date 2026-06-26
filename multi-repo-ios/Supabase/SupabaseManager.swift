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

    /// Project base URL — exposed for building Edge Function endpoints
    /// (`{supabaseURL}/functions/v1/<slug>`), used by Transform/TranscribeService.
    let supabaseURL: URL

    private init() {
        supabaseURL = SupabaseConfig.url
        client = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
    }
}
