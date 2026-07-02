//
//  FirebaseNotificationRepository.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirebaseNotificationRepository: NotificationRepository, @unchecked Sendable {
    private let db = Firestore.firestore()
    private let inboxStore: LocalNotificationInboxStore

    init(inboxStore: LocalNotificationInboxStore = .shared) {
        self.inboxStore = inboxStore
    }

    func fetchNotifications() async throws -> [AppNotification] {
        let snapshot = try await db.collection(FirestoreCollections.announcements)
            .order(by: FirestoreFields.Announcement.publishedAt, descending: true)
            .limit(to: 50)
            .getDocuments()

        let announcements = snapshot.documents.compactMap { document in
            FirestoreAnnouncementMapper.announcement(
                from: document,
                isRead: inboxStore.isRead(notificationId: "announcement-\(document.documentID)")
            )
        }

        let localItems = inboxStore.fetchAll()
        return (announcements + localItems)
            .sorted { $0.publishedAt > $1.publishedAt }
    }

    func markAsRead(notificationId: String) async throws {
        inboxStore.markAsRead(notificationId: notificationId)
    }
}
