//
//  NotificationsViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class NotificationsViewModel {
    private(set) var notifications: [AppNotification] = []
    private(set) var isLoading = false

    private let notificationRepository: any NotificationRepository

    init(notificationRepository: any NotificationRepository) {
        self.notificationRepository = notificationRepository
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }
        notifications = (try? await notificationRepository.fetchNotifications()) ?? []
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        try? await notificationRepository.markAsRead(notificationId: notification.id)
        await loadNotifications()
    }

    func notification(id: String) -> AppNotification? {
        notifications.first { $0.id == id }
    }
}

#if DEBUG
extension NotificationsViewModel {
    static var preview: NotificationsViewModel {
        let viewModel = NotificationsViewModel(notificationRepository: MockNotificationRepository())
        viewModel.notifications = [
            AppNotification(
                id: "preview-1",
                title: "アプリをご利用いただきありがとうございます",
                body: "matiapuへようこそ。",
                publishedAt: .now,
                isRead: false
            ),
        ]
        return viewModel
    }
}
#endif
