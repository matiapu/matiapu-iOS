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
    private(set) var unreadNotificationCount = 0

    private let authRepository: any AuthRepository
    private let notificationRepository: any NotificationRepository

    var onRegisteredAreaUpdated: ((String) -> Void)?

    init(
        authRepository: any AuthRepository,
        notificationRepository: any NotificationRepository
    ) {
        self.authRepository = authRepository
        self.notificationRepository = notificationRepository
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        profile = try? await authRepository.fetchCurrentUser()
        await loadUnreadNotificationCount()
    }

    func loadUnreadNotificationCount() async {
        let notifications = (try? await notificationRepository.fetchNotifications()) ?? []
        unreadNotificationCount = notifications.filter { !$0.isRead }.count
    }

    func updateDisplayName(_ name: String) async throws {
        try await authRepository.updateDisplayName(name)
        await loadProfile()
    }

    func updateRegisteredArea(_ area: String) async throws {
        try await authRepository.updateRegisteredArea(area)
        await loadProfile()
        onRegisteredAreaUpdated?(area)
    }

    func updateEmail(_ email: String) async throws {
        try await authRepository.updateEmail(email)
        await loadProfile()
    }

    func updatePassword(_ password: String) async throws {
        try await authRepository.updatePassword(password)
    }
}

#if DEBUG
extension SettingsViewModel {
    static var preview: SettingsViewModel {
        let viewModel = SettingsViewModel(
            authRepository: MockAuthRepository(),
            notificationRepository: MockNotificationRepository()
        )
        viewModel.profile = UserProfile(
            displayName: "ユーザー名ユーザー名",
            registeredArea: "新宿区",
            email: "user@example.com"
        )
        return viewModel
    }
}
#endif
