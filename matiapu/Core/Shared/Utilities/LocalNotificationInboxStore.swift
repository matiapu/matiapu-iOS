//
//  LocalNotificationInboxStore.swift
//  matiapu
//

import Foundation

/// マッチ・メッセージ通知を端末内に保持するストア
final class LocalNotificationInboxStore: @unchecked Sendable {
    static let shared = LocalNotificationInboxStore()

    private let lock = NSLock()
    private let defaults: UserDefaults
    private let inboxKey = "notification_inbox"
    private let readIDsKey = "notification_read_ids"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchAll() -> [AppNotification] {
        locked {
            let inbox = loadInbox()
            let readIDs = loadReadIDs()
            return inbox
                .map { notification in
                    AppNotification(
                        id: notification.id,
                        kind: notification.kind,
                        title: notification.title,
                        body: notification.body,
                        publishedAt: notification.publishedAt,
                        isRead: readIDs.contains(notification.id) || notification.isRead,
                        relatedID: notification.relatedID
                    )
                }
                .sorted { $0.publishedAt > $1.publishedAt }
        }
    }

    func append(_ notification: AppNotification) {
        locked {
            var inbox = loadInbox()
            guard !inbox.contains(where: { $0.id == notification.id }) else { return }
            inbox.append(notification)
            saveInbox(inbox)
        }
    }

    func markAsRead(notificationId: String) {
        locked {
            var readIDs = loadReadIDs()
            readIDs.insert(notificationId)
            saveReadIDs(readIDs)
        }
    }

    func isRead(notificationId: String) -> Bool {
        locked { loadReadIDs().contains(notificationId) }
    }

    private func loadInbox() -> [AppNotification] {
        guard
            let data = defaults.data(forKey: inboxKey),
            let inbox = try? JSONDecoder().decode([AppNotification].self, from: data)
        else {
            return []
        }
        return inbox
    }

    private func saveInbox(_ inbox: [AppNotification]) {
        guard let data = try? JSONEncoder().encode(inbox) else { return }
        defaults.set(data, forKey: inboxKey)
    }

    private func loadReadIDs() -> Set<String> {
        Set(defaults.stringArray(forKey: readIDsKey) ?? [])
    }

    private func saveReadIDs(_ ids: Set<String>) {
        defaults.set(Array(ids), forKey: readIDsKey)
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
