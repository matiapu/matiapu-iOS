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
    private(set) var userLocationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var selectedPost: Post?
    var detailPost: Post?

    private let postRepository: any PostRepository
    private let coordinateResolver = RegionCoordinateResolver()
    private var locationService: LocationCaptureService?
    private var hasCenteredOnUserLocation = false

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    func loadInitialCenter(from authRepository: any AuthRepository) async {
        await requestUserLocationAndCenter()

        guard !hasCenteredOnUserLocation else { return }
        guard let profile = try? await authRepository.fetchCurrentUser() else { return }
        await updateCenter(forRegisteredArea: profile.registeredArea)
    }

    func requestUserLocationAndCenter() async {
        let service = locationService ?? LocationCaptureService()
        locationService = service
        service.onLocationUpdate = { [weak self] location in
            guard let self, !self.hasCenteredOnUserLocation else { return }
            self.centerOnUserLocation(location.coordinate)
        }
        service.prepareForCapture()
        userLocationAuthorizationStatus = service.authorizationStatus

        if let coordinate = await service.waitForLocation(timeout: 8) {
            centerOnUserLocation(coordinate)
        }
    }

    func centerOnUserLocation(_ coordinate: CLLocationCoordinate2D? = nil) {
        let target = coordinate ?? locationService?.currentCoordinate
        guard let target else { return }
        hasCenteredOnUserLocation = true
        mapCenter = target
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
            errorMessage = "投稿データの読み込みに失敗しました。しばらくしてから再度お試しください。"
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
