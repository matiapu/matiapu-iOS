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
    private let inboxStore: LocalNotificationInboxStore
    private var announcements: [AppNotification] = [
        AppNotification(
            id: "notification-1",
            kind: .announcement,
            title: "アプリをご利用いただきありがとうございます",
            body: "matiapuへようこそ。地域の投稿を地図から確認したり、自分の地域を設定して活動を始めましょう。",
            publishedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 1).date ?? .now,
            isRead: false
        ),
        AppNotification(
            id: "notification-2",
            kind: .announcement,
            title: "地域設定機能を追加しました",
            body: "設定画面から登録地域を変更できます。郵便番号検索や都道府県・市区町村から選べます。",
            publishedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 10).date ?? .now,
            isRead: false
        ),
        AppNotification(
            id: "notification-3",
            kind: .announcement,
            title: "メンテナンスのお知らせ",
            body: "6月20日 2:00〜4:00にメンテナンスを実施します。作業中は一部機能がご利用いただけない場合があります。",
            publishedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 15).date ?? .now,
            isRead: true
        ),
    ]

    init(inboxStore: LocalNotificationInboxStore = .shared) {
        self.inboxStore = inboxStore
    }

    func fetchNotifications() async throws -> [AppNotification] {
        locked {
            let localItems = inboxStore.fetchAll()
            return (announcements + localItems)
                .sorted { $0.publishedAt > $1.publishedAt }
        }
    }

    func markAsRead(notificationId: String) async throws {
        locked {
            if let index = announcements.firstIndex(where: { $0.id == notificationId }) {
                let current = announcements[index]
                announcements[index] = AppNotification(
                    id: current.id,
                    kind: current.kind,
                    title: current.title,
                    body: current.body,
                    publishedAt: current.publishedAt,
                    isRead: true,
                    relatedID: current.relatedID
                )
            }
        }
        inboxStore.markAsRead(notificationId: notificationId)
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
