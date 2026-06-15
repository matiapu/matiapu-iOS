//
//  AuthRepository.swift
//  matiapu
//

import Foundation

protocol AuthRepository: Sendable {
    func fetchCurrentUser() async throws -> UserProfile
    func fetchUserPosts() async throws -> [ProfilePostItem]
    func signOut() async throws
}

struct MockAuthRepository: AuthRepository {
    func fetchCurrentUser() async throws -> UserProfile {
        UserProfile(
            displayName: "ユーザー名ユーザー名",
            registeredArea: "東京都新宿区"
        )
    }

    func fetchUserPosts() async throws -> [ProfilePostItem] {
        (1...12).map { index in
            ProfilePostItem(
                id: "profile-post-\(index)",
                imageName: MockImages.postImage(at: index - 1)
            )
        }
    }

    func signOut() async throws {}
}
