//
//  ProfileModel.swift
//  multi-repo-ios
//
//  Matches `public.profiles` table in Supabase.
//

import Foundation

struct ProfileModel: Codable, Identifiable, Sendable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
