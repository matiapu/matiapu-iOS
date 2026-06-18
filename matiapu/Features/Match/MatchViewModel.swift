//
//  MatchViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class MatchViewModel {
    private(set) var currentPost: Post?
    var detailPost: Post?
    var isChatPresented = false
    var showMatchAlert = false
    var matchedPartnerName: String?
    private(set) var isLoading = false

    var onMatched: ((ChatConversation) async -> Void)?

    private var swipeQueue = PostSwipeQueue()
    private let postRepository: any PostRepository
    private let matchRepository: any MatchRepository
    private let authRepository: any AuthRepository

    init(
        postRepository: any PostRepository,
        matchRepository: any MatchRepository,
        authRepository: any AuthRepository,
        initialQueue: [Post]? = nil
    ) {
        self.postRepository = postRepository
        self.matchRepository = matchRepository
        self.authRepository = authRepository
        if let initialQueue {
            swipeQueue = PostSwipeQueue(candidates: initialQueue)
            currentPost = swipeQueue.current
        }
    }

    func loadPosts() async {
        guard currentPost == nil, swipeQueue.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let candidates = (try? await postRepository.fetchMatchCandidates()) ?? []
        swipeQueue = PostSwipeQueue(candidates: candidates)
        currentPost = swipeQueue.current
    }

    func openDetail() {
        detailPost = currentPost
    }

    func openChat() {
        isChatPresented = true
    }

    func dismissChat() {
        isChatPresented = false
    }

    func dismissMatchAlert() {
        showMatchAlert = false
        matchedPartnerName = nil
    }

    func openChatAfterMatch() {
        dismissMatchAlert()
        isChatPresented = true
    }

    func handleSwipe(_ action: PostSwipeAction) {
        guard let post = currentPost else { return }

        detailPost = nil
        let swipedPost = post
        if swipeQueue.advance(with: action) != nil {
            Task {
                try? await postRepository.recordSwipe(postId: swipedPost.id, action: action)
                if action == .empathy, let legislatorId = swipedPost.legislatorId {
                    await processCitizenLike(
                        legislatorId: legislatorId,
                        legislatorName: swipedPost.authorName
                    )
                }
            }
        }
        currentPost = swipeQueue.current
    }

    private func processCitizenLike(legislatorId: String, legislatorName: String) async {
        let citizenId = (try? await authRepository.fetchCurrentUser())?.id ?? MockMatching.demoCitizenId
        guard let result = try? await matchRepository.recordCitizenLike(
            citizenUserId: citizenId,
            legislatorId: legislatorId,
            legislatorName: legislatorName
        ) else {
            return
        }

        if case .matched(let conversation) = result {
            matchedPartnerName = conversation.partnerName
            showMatchAlert = true
            await onMatched?(conversation)
        }
    }

    func swipeRight() {
        handleSwipe(.empathy)
    }

    func swipeLeft() {
        handleSwipe(.skip)
    }
}

#if DEBUG
extension MatchViewModel {
    static var preview: MatchViewModel {
        MatchViewModel(
            postRepository: MockPostRepository(),
            matchRepository: MockMatchRepository(chatRepository: MockChatRepository()),
            authRepository: MockAuthRepository(),
            initialQueue: PostPreviewData.matchCandidates
        )
    }
}
#endif
