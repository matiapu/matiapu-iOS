//
//  FirestoreAnnouncementMapper.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestoreAnnouncementMapper {
    static func announcement(from document: QueryDocumentSnapshot, isRead: Bool) -> AppNotification? {
        announcement(from: document.data(), id: document.documentID, isRead: isRead)
    }

    static func announcement(from data: [String: Any], id: String, isRead: Bool) -> AppNotification? {
        guard
            let title = stringValue(from: data, keys: [FirestoreFields.Announcement.title, "title"]),
            let body = stringValue(from: data, keys: [FirestoreFields.Announcement.body, "body"])
        else {
            return nil
        }

        let publishedAt = FirestoreDateCodec.date(from: data[FirestoreFields.Announcement.publishedAt])
            ?? FirestoreDateCodec.date(from: data["publishedAt"])
            ?? .now

        return AppNotification(
            id: "announcement-\(id)",
            kind: .announcement,
            title: title,
            body: body,
            publishedAt: publishedAt,
            isRead: isRead,
            relatedID: id
        )
    }

    private static func stringValue(from data: [String: Any], keys: [String]) -> String? {
        for key in keys {
            guard let value = data[key] as? String else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }
}
