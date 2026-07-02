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

    func execute() async throws -> UserProfileSnapshot {
        async let profileTask = manageAccount.fetchCurrentUser()
        async let postsTask = postRepository.fetchUserPosts()
        return UserProfileSnapshot(
            profile: try await profileTask,
            posts: try await postsTask
        )
    }
}
