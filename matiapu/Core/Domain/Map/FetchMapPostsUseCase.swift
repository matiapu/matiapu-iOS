//
//  FetchMapPostsUseCase.swift
//  matiapu
//

import Foundation

struct FetchMapPostsUseCase: Sendable {
    private let postRepository: any PostRepository

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    func execute(filter: MapFilter?, scope: MapMunicipalityScope?) async throws -> [Post] {
        let fetched = try await postRepository.fetchPosts(filter: filter, municipality: nil)
        return MapMunicipalityFilter.posts(
            fetched,
            municipality: scope?.name,
            boundary: scope?.boundary
        )
    }

    func shouldDisplay(
        post: Post,
        filter: MapFilter?,
        scope: MapMunicipalityScope?
    ) -> Bool {
        guard post.location != nil else { return false }
        guard filter == nil || filter?.matches(post: post) == true else { return false }

        return !MapMunicipalityFilter.posts(
            [post],
            municipality: scope?.name,
            boundary: scope?.boundary
        ).isEmpty
    }
}
