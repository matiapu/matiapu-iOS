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
    private(set) var isLoading = false

    private var swipeQueue = PostSwipeQueue()
    private let postRepository: any PostRepository

    init(
        postRepository: any PostRepository,
        initialQueue: [Post]? = nil
    ) {
        self.postRepository = postRepository
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

    func handleSwipe(_ action: PostSwipeAction) {
        guard let post = currentPost else { return }

        if swipeQueue.advance(with: action) != nil {
            Task {
                try? await postRepository.recordSwipe(postId: post.id, action: action)
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
            postRepository: MockPostRepository(),
            initialQueue: PostPreviewData.matchCandidates
        )
    }
}
#endif
