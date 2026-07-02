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

    private let fetchNotifications: FetchNotificationsUseCase

    init(fetchNotifications: FetchNotificationsUseCase) {
        self.fetchNotifications = fetchNotifications
    }

    var unreadCount: Int {
        fetchNotifications.unreadCount(in: notifications)
    }

    func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }
        notifications = (try? await fetchNotifications.execute()) ?? []
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        try? await fetchNotifications.markAsRead(notificationId: notification.id)
        await loadNotifications()
    }

    func notification(id: String) -> AppNotification? {
        notifications.first { $0.id == id }
    }
}

#if DEBUG
extension NotificationsViewModel {
    static var preview: NotificationsViewModel {
        let viewModel = NotificationsViewModel(
            fetchNotifications: FetchNotificationsUseCase(
                notificationRepository: MockNotificationRepository()
            )
        )
        viewModel.notifications = [
            AppNotification(
                id: "preview-1",
                kind: .announcement,
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
