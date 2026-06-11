//
//  MapViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class MapViewModel {
    private(set) var selectedFilter: MapFilter?
    private(set) var posts: [Post] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let postRepository: any PostRepository

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    func selectFilter(_ filter: MapFilter?) {
        selectedFilter = filter
        Task { await loadPosts() }
    }

    func loadPosts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            posts = try await postRepository.fetchPosts(filter: selectedFilter)
        } catch {
            posts = []
            errorMessage = "位置情報の読み込みに失敗しました。ページを再度読み込んでください。"
        }
    }
}
