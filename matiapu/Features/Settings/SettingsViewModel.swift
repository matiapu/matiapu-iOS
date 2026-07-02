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
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        profile = try? await manageAccount.fetchCurrentUser()
        await loadUnreadNotificationCount()
    }

    func loadUnreadNotificationCount() async {
        let notifications = (try? await fetchNotifications.execute()) ?? []
        unreadNotificationCount = fetchNotifications.unreadCount(in: notifications)
    }

    func updateDisplayName(_ name: String) async throws {
        try await manageAccount.updateDisplayName(name)
        await loadProfile()
    }

    func updateRegisteredArea(_ area: String) async throws {
        try await manageAccount.updateRegisteredArea(area)
        await loadProfile()
    }

    func updateEmail(_ email: String) async throws {
        try await manageAccount.updateEmail(email)
        await loadProfile()
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
