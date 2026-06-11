//
//  AuthRepository.swift
//  matiapu
//

import Foundation

protocol AuthRepository: Sendable {
    func fetchCurrentUser() async throws -> UserProfile
    func signOut() async throws
}

struct MockAuthRepository: AuthRepository {
    func fetchCurrentUser() async throws -> UserProfile {
        UserProfile(displayName: "ユーザー名", registeredArea: "東京都 調布市")
    }

    func signOut() async throws {}
}
