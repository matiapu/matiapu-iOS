//
//  NotificationRepository.swift
//  matiapu
//

import Foundation

protocol NotificationRepository: Sendable {
    func fetchNotifications() async throws -> [AppNotification]
    func markAsRead(notificationId: String) async throws
}

final class MockNotificationRepository: NotificationRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var notifications: [AppNotification] = [
        AppNotification(
            id: "notification-1",
            title: "アプリをご利用いただきありがとうございます",
            body: "matiapuへようこそ。地域の投稿を地図から確認したり、自分の地域を設定して活動を始めましょう。",
            publishedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 1).date ?? .now,
            isRead: false
        ),
        AppNotification(
            id: "notification-2",
            title: "地域設定機能を追加しました",
            body: "設定画面から登録地域を変更できます。郵便番号検索や都道府県・市区町村から選べます。",
            publishedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 10).date ?? .now,
            isRead: false
        ),
        AppNotification(
            id: "notification-3",
            title: "メンテナンスのお知らせ",
            body: "6月20日 2:00〜4:00にメンテナンスを実施します。作業中は一部機能がご利用いただけない場合があります。",
            publishedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 15).date ?? .now,
            isRead: true
        ),
    ]

    func fetchNotifications() async throws -> [AppNotification] {
        locked { notifications.sorted { $0.publishedAt > $1.publishedAt } }
    }

    func markAsRead(notificationId: String) async throws {
        locked {
            guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else { return }
            let current = notifications[index]
            notifications[index] = AppNotification(
                id: current.id,
                title: current.title,
                body: current.body,
                publishedAt: current.publishedAt,
                isRead: true
            )
        }
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
