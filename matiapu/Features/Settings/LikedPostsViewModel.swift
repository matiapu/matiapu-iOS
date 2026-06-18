//
//  LikedPostsViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class LikedPostsViewModel {
    private(set) var posts: [Post] = []
    private(set) var isLoading = false
    var searchText = ""
    var sortOrder: LikedPostSortOrder = .newestFirst

    private let postRepository: any PostRepository

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    var filteredPosts: [Post] {
        let sorted = posts.sorted { lhs, rhs in
            switch sortOrder {
            case .newestFirst:
                return lhs.postedAt > rhs.postedAt
            case .oldestFirst:
                return lhs.postedAt < rhs.postedAt
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.contains(query)
                || $0.body.contains(query)
                || $0.authorName.contains(query)
                || $0.tag.contains(query)
        }
    }

    func loadPosts() async {
        isLoading = true
        defer { isLoading = false }
        posts = (try? await postRepository.fetchLikedPosts()) ?? []
    }
}

#if DEBUG
extension LikedPostsViewModel {
    static var preview: LikedPostsViewModel {
        let viewModel = LikedPostsViewModel(postRepository: MockPostRepository())
        viewModel.posts = PostPreviewData.likedPosts
        return viewModel
    }
}
#endif
