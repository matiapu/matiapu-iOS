//
//  SettingsViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private(set) var profile: UserProfile?
    private(set) var isLoading = false
    private(set) var isDeletingAccount = false
    private(set) var unreadNotificationCount = 0
    var deleteAccountError: String?

    private let manageAccount: ManageAccountUseCase
    private let fetchNotifications: FetchNotificationsUseCase

    init(useCases: AppUseCases) {
        self.manageAccount = useCases.manageAccount
        self.fetchNotifications = useCases.fetchNotifications
        profile = useCases.manageAccount.cachedCurrentUser()
    }

    func syncProfileFromCache() {
        if let cached = manageAccount.cachedCurrentUser() {
            profile = cached
        }
    }

    func loadProfile(forceRefresh: Bool = false) async {
        syncProfileFromCache()
        if profile == nil {
            isLoading = true
        }
        defer { isLoading = false }
        if let fetched = try? await manageAccount.fetchCurrentUser(forceRefresh: forceRefresh) {
            profile = fetched
        }
        await loadUnreadNotificationCount()
    }

    func loadUnreadNotificationCount() async {
        let notifications = (try? await fetchNotifications.execute()) ?? []
        unreadNotificationCount = fetchNotifications.unreadCount(in: notifications)
    }

    func updateDisplayName(_ name: String) async throws {
        try await manageAccount.updateDisplayName(name)
        syncProfileFromCache()
    }

    func updateRegisteredArea(_ area: String) async throws {
        try await manageAccount.updateRegisteredArea(area)
        syncProfileFromCache()

        // オンラインのうちに境界データを永続化し、オフラインでも地図の枠を出せるようにする
        Task.detached(priority: .utility) {
            await MunicipalityBoundaryLoader.shared.prefetchBoundary(municipalityName: area)
        }
    }

    func updateEmail(_ email: String) async throws {
        try await manageAccount.updateEmail(email)
        syncProfileFromCache()
    }

    func updatePassword(_ password: String) async throws {
        try await manageAccount.updatePassword(password)
    }

    func deleteAccount() async -> Bool {
        isDeletingAccount = true
        deleteAccountError = nil
        defer { isDeletingAccount = false }

        do {
            try await manageAccount.deleteAccount()
            return true
        } catch let error as AuthError {
            deleteAccountError = error.errorDescription
            return false
        } catch {
            deleteAccountError = error.localizedDescription
            return false
        }
    }
}

#if DEBUG
extension SettingsViewModel {
    static var preview: SettingsViewModel {
        let viewModel = SettingsViewModel(useCases: AppUseCases.make(from: .live))
        viewModel.profile = UserProfile(
            displayName: "ユーザー名ユーザー名",
            registeredArea: PreviewMockRegion.municipalityName,
            email: "user@example.com"
        )
        return viewModel
    }
}
#endif
