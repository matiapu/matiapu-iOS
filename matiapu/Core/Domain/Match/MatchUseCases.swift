//
//  MatchUseCases.swift
//  matiapu
//

import Foundation

struct FetchMatchCandidatesUseCase: Sendable {
    private let postRepository: any PostRepository

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    func execute() async throws -> [Post] {
        try await postRepository.fetchMatchCandidates()
    }
}

enum MatchSwipeOutcome: Sendable {
    case none
    case matched(ChatConversation)
}

struct ProcessMatchSwipeUseCase: Sendable {
    private let postRepository: any PostRepository
    private let matchRepository: any MatchRepository
    private let manageAccount: ManageAccountUseCase

    init(
        postRepository: any PostRepository,
        matchRepository: any MatchRepository,
        manageAccount: ManageAccountUseCase
    ) {
        self.postRepository = postRepository
        self.matchRepository = matchRepository
        self.manageAccount = manageAccount
    }

    func execute(post: Post, action: PostSwipeAction) async throws -> MatchSwipeOutcome {
        try await postRepository.recordSwipe(postId: post.id, action: action)

        guard let legislatorId = post.legislatorId else { return .none }

        let citizenId = (try? await manageAccount.fetchCurrentUser())?.id ?? MockMatching.demoCitizenId

        switch action {
        case .empathy:
            guard let result = try? await matchRepository.recordCitizenLike(
                citizenUserId: citizenId,
                legislatorId: legislatorId,
                legislatorName: post.authorName
            ) else {
                return .none
            }

            if case .matched(let conversation) = result {
                return .matched(conversation)
            }
            return .none

        case .skip:
            try? await matchRepository.recordCitizenBad(
                citizenUserId: citizenId,
                legislatorId: legislatorId
            )
            return .none
        }
    }
}
