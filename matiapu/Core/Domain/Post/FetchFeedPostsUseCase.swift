//
//  FetchFeedPostsUseCase.swift
//  matiapu
//

import Foundation

struct FetchFeedPostsUseCase: Sendable {
    private let postRepository: any PostRepository
    private let authRepository: any AuthRepository

    init(postRepository: any PostRepository, authRepository: any AuthRepository) {
        self.postRepository = postRepository
        self.authRepository = authRepository
    }

    func execute() async throws -> [Post] {
        async let postsTask = postRepository.fetchFeedPosts()
        async let profileTask = authRepository.fetchCurrentUser()

        let posts = try await postsTask
        let profile = try await profileTask
        let likeCounts = try await postRepository.fetchLikeCounts(for: posts.map(\.id))

        return FeedPostRanking.rankedPosts(
            posts: posts,
            currentUserID: profile.id,
            registeredArea: profile.registeredArea,
            likeCounts: likeCounts
        )
    }
}
