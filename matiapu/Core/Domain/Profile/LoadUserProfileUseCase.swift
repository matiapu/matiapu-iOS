//
//  LoadUserProfileUseCase.swift
//  matiapu
//

import Foundation

struct UserProfileSnapshot: Sendable {
    let profile: UserProfile
    let posts: [Post]
}

struct LoadUserProfileUseCase: Sendable {
    private let manageAccount: ManageAccountUseCase
    private let postRepository: any PostRepository

    init(manageAccount: ManageAccountUseCase, postRepository: any PostRepository) {
        self.manageAccount = manageAccount
        self.postRepository = postRepository
    }

    func execute(forceRefresh: Bool = false) async throws -> UserProfileSnapshot {
        let profile = try await manageAccount.fetchCurrentUser(forceRefresh: forceRefresh)
        let posts = (try? await postRepository.fetchUserPosts()) ?? []
        return UserProfileSnapshot(profile: profile, posts: posts)
    }
}
