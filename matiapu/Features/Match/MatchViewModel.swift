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
    private let fetchMatchCandidates: FetchMatchCandidatesUseCase
    private let processMatchSwipe: ProcessMatchSwipeUseCase

    init(useCases: AppUseCases, initialQueue: [Post]? = nil) {
        self.fetchMatchCandidates = useCases.fetchMatchCandidates
        self.processMatchSwipe = useCases.processMatchSwipe
        if let initialQueue {
            swipeQueue = PostSwipeQueue(candidates: initialQueue)
            currentPost = swipeQueue.current
        }
    }

    func loadPosts() async {
        guard currentPost == nil, swipeQueue.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let candidates = (try? await fetchMatchCandidates.execute()) ?? []
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
                guard let outcome = try? await processMatchSwipe.execute(
                    post: swipedPost,
                    action: action
                ) else { return }

                if case .matched(let conversation) = outcome {
                    matchedPartnerName = conversation.partnerName
                    showMatchAlert = true
                    await onMatched?(conversation)
                }
            }
        }
        currentPost = swipeQueue.current
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
            useCases: AppUseCases.make(from: .live),
            initialQueue: PostPreviewData.matchCandidates
        )
    }
}
#endif
