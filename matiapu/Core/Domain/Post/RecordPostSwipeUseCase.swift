//
//  RecordPostSwipeUseCase.swift
//  matiapu
//

import Foundation

struct RecordPostSwipeUseCase: Sendable {
    private let postRepository: any PostRepository
    private let matchRepository: any MatchRepository
    private let authRepository: any AuthRepository

    init(
        postRepository: any PostRepository,
        matchRepository: any MatchRepository,
        authRepository: any AuthRepository
    ) {
        self.postRepository = postRepository
        self.matchRepository = matchRepository
        self.authRepository = authRepository
    }

    func execute(post: Post, action: PostSwipeAction) async throws -> MatchSwipeOutcome {
        try await postRepository.recordSwipe(postId: post.id, action: action)

        guard action == .empathy else { return .none }

        let legislatorId = (try? await authRepository.fetchCurrentUser())?.id
            ?? MockMatching.demoLegislatorId
        guard
            let result = try? await matchRepository.recordLegislatorLike(
                legislatorId: legislatorId,
                post: post
            ),
            case .matched(let conversation) = result
        else {
            return .none
        }

        return .matched(conversation)
    }
}
