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
    private(set) var shelters: [Shelter] = []
    private(set) var disasters: [Disaster] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var mapCenter: CLLocationCoordinate2D?
    private(set) var centerErrorMessage: String?
    private(set) var municipalityScope: MapMunicipalityScope?
    var selectedPost: Post?
    var selectedShelter: Shelter?
    var detailPost: Post?

    private let resolveMunicipalityScope: ResolveMunicipalityScopeUseCase
    private let fetchMapPosts: FetchMapPostsUseCase
    private let fetchMapOverlays: FetchMapOverlaysUseCase
    private let authRepository: any AuthRepository

    init(useCases: AppUseCases, authRepository: any AuthRepository) {
        self.resolveMunicipalityScope = useCases.resolveMunicipalityScope
        self.fetchMapPosts = useCases.fetchMapPosts
        self.fetchMapOverlays = useCases.fetchMapOverlays
        self.authRepository = authRepository
    }

    /// ユーザーが設定した登録地域を地図の中心に据える。
    func loadInitialCenter() async {
        centerErrorMessage = nil
        await loadMunicipalityScope(force: true)

        guard let scope = municipalityScope else {
            centerErrorMessage = registeredAreaErrorMessage()
            mapCenter = nil
            return
        }

        mapCenter = scope.center
    }

    func reloadMunicipalityScope() async {
        municipalityScope = nil
        await loadMunicipalityScope()
        if let scope = municipalityScope {
            mapCenter = scope.center
            centerErrorMessage = nil
        }
        await loadPosts()
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

        await loadMunicipalityScope()

        async let postsTask: Void = loadPostMarkers()
        async let overlaysTask: Void = loadMapOverlays()
        _ = await (postsTask, overlaysTask)
    }

    func insertCreatedPost(_ post: Post) {
        guard fetchMapPosts.shouldDisplay(
            post: post,
            filter: selectedFilter,
            scope: municipalityScope
        ) else { return }
        guard !posts.contains(where: { $0.id == post.id }) else { return }

        posts.insert(post, at: 0)
        if let location = post.location {
            mapCenter = location.coordinate
            centerErrorMessage = nil
        }
    }

    private func loadMunicipalityScope(force: Bool = false) async {
        if !force, municipalityScope != nil { return }
        municipalityScope = await resolveMunicipalityScope.execute()
    }

    /// スコープを解決できなかった理由に応じたエラーメッセージを返す。
    private func registeredAreaErrorMessage() -> String {
        guard let profile = authRepository.cachedCurrentUser() else {
            return "登録地域を取得できませんでした。"
        }
        let area = profile.registeredArea.trimmingCharacters(in: .whitespacesAndNewlines)
        if area.isEmpty {
            return "登録地域が設定されていません。"
        }
        return "登録地域の位置情報を取得できませんでした。"
    }

    private func loadPostMarkers() async {
        do {
            posts = try await fetchMapPosts.execute(
                filter: selectedFilter,
                scope: municipalityScope
            )
        } catch {
            posts = []
            errorMessage = "投稿データの読み込みに失敗しました。しばらくしてから再度お試しください。"
        }
    }

    private func loadMapOverlays() async {
        let overlays = await fetchMapOverlays.execute(scope: municipalityScope)
        shelters = overlays.shelters
        disasters = overlays.disasters
    }

    func selectPost(_ post: Post) {
        selectedPost = post
        selectedShelter = nil
    }

    func dismissSelectedPost() {
        selectedPost = nil
    }

    func dismissMapSelection() {
        selectedPost = nil
        selectedShelter = nil
    }

    func selectShelter(_ shelter: Shelter) {
        selectedShelter = shelter
        selectedPost = nil
    }

    func dismissSelectedShelter() {
        selectedShelter = nil
    }

    func openDetail() {
        guard let selectedPost else { return }
        detailPost = selectedPost
        self.selectedPost = nil
    }
}
