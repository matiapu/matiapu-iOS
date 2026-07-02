//
//  UserPublicProfile.swift
//  matiapu
//

import Foundation

struct UserPublicProfile: Sendable, Hashable {
    let id: String
    let displayName: String
    let profileImageURL: String?

    static let fallbackDisplayName = "ユーザー"
}
