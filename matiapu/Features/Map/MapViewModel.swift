//
//  MapViewModel.swift
//  matiapu
//

import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class MapViewModel {
    private(set) var selectedFilter: MapFilter?
    private(set) var posts: [Post] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var mapCenter: CLLocationCoordinate2D = MapConstants.defaultCenter
    var selectedPost: Post?
    var detailPost: Post?

    private let postRepository: any PostRepository
    private let coordinateResolver = RegionCoordinateResolver()

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    func loadInitialCenter(from authRepository: any AuthRepository) async {
        guard let profile = try? await authRepository.fetchCurrentUser() else { return }
        await updateCenter(forRegisteredArea: profile.registeredArea)
    }

    func updateCenter(forRegisteredArea area: String) async {
        guard let coordinate = await coordinateResolver.coordinate(for: area) else { return }
        mapCenter = coordinate
    }

    func selectFilter(_ filter: MapFilter?) {
        selectedFilter = filter
        selectedPost = nil
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

    func selectPost(_ post: Post) {
        selectedPost = post
    }

    func dismissSelectedPost() {
        selectedPost = nil
    }

    func openDetail() {
        guard let selectedPost else { return }
        detailPost = selectedPost
        self.selectedPost = nil
    }
}
