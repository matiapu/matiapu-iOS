//
//  SettingsUseCases.swift
//  matiapu
//

import Foundation

struct FetchNotificationsUseCase: Sendable {
    private let notificationRepository: any NotificationRepository

    init(notificationRepository: any NotificationRepository) {
        self.notificationRepository = notificationRepository
    }

    func execute() async throws -> [AppNotification] {
        try await notificationRepository.fetchNotifications()
    }

    func unreadCount(in notifications: [AppNotification]) -> Int {
        notifications.filter { !$0.isRead }.count
    }

    func markAsRead(notificationId: String) async throws {
        try await notificationRepository.markAsRead(notificationId: notificationId)
    }
}

struct FetchLikedPostsUseCase: Sendable {
    private let postRepository: any PostRepository

    init(postRepository: any PostRepository) {
        self.postRepository = postRepository
    }

    func execute() async throws -> [Post] {
        try await postRepository.fetchLikedPosts()
    }
}

struct SearchPostalCodeUseCase: Sendable {
    nonisolated init() {}

    func execute(postalCode: String) async throws -> [PostalCodeArea] {
        try await PostalCodeLookup.search(postalCode: postalCode)
    }
}
