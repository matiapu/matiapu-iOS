//
//  FirestoreChatRoomMapper.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestoreChatRoomMapper {
    static func room(from document: DocumentSnapshot) -> ChatRoom? {
        guard document.exists, let data = document.data() else { return nil }
        return room(from: data, id: document.documentID)
    }

    static func room(from document: QueryDocumentSnapshot) -> ChatRoom? {
        room(from: document.data(), id: document.documentID)
    }

    static func room(from data: [String: Any], id: String) -> ChatRoom? {
        guard let userIDs = userIDs(from: data) else {
            return nil
        }

        return ChatRoom(
            id: id,
            userIDs: userIDs,
            createdAt: FirestoreDateCodec.date(from: data[FirestoreFields.ChatRoom.createdAt]) ?? .now,
            lastMessageAt: FirestoreDateCodec.date(from: data[FirestoreFields.ChatRoom.lastMessageAt]) ?? .now,
            lastMessageText: data[FirestoreFields.ChatRoom.lastMessageText] as? String,
            lastMessageIV: data[FirestoreFields.ChatRoom.lastMessageIV] as? String,
            lastMessageSenderID: data[FirestoreFields.ChatRoom.lastMessageSenderID] as? String
                ?? data["lastMessageSenderId"] as? String,
            lastReadAtByUserID: lastReadAtByUserID(from: data)
        )
    }

    private static func lastReadAtByUserID(from data: [String: Any]) -> [String: Date] {
        let raw = data[FirestoreFields.ChatRoom.lastReadAt] as? [String: Any]
            ?? data["lastReadAt"] as? [String: Any]
            ?? [:]

        var result: [String: Date] = [:]
        result.reserveCapacity(raw.count)
        for (userID, value) in raw {
            let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let date = FirestoreDateCodec.date(from: value) else { continue }
            result[trimmed] = date
        }
        return result
    }

    private static func userIDs(from data: [String: Any]) -> [String]? {
        let candidates: [[String]?] = [
            data[FirestoreFields.ChatRoom.userIDs] as? [String],
            data["userIds"] as? [String],
        ]

        for case let ids? in candidates {
            let normalized = ids
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if normalized.count >= 2 {
                return Array(normalized.prefix(2))
            }
        }
        return nil
    }

    static func creationData(uid1: String, uid2: String, createdAt: Date = .now) -> [String: Any] {
        [
            FirestoreFields.ChatRoom.userIDs: [uid1, uid2].sorted(),
            FirestoreFields.ChatRoom.createdAt: FirestoreDateCodec.timestamp(from: createdAt),
            FirestoreFields.ChatRoom.lastMessageAt: FirestoreDateCodec.timestamp(from: createdAt),
        ]
    }

    static func lastMessageUpdate(
        encryptedContent: String,
        iv: String,
        senderID: String,
        sentAt: Date = .now
    ) -> [String: Any] {
        [
            FirestoreFields.ChatRoom.lastMessageAt: FirestoreDateCodec.timestamp(from: sentAt),
            FirestoreFields.ChatRoom.lastMessageText: encryptedContent,
            FirestoreFields.ChatRoom.lastMessageIV: iv,
            FirestoreFields.ChatRoom.lastMessageSenderID: senderID,
        ]
    }

    static func lastReadAtUpdate(userID: String, readAt: Date = .now) -> [String: Any] {
        [
            "\(FirestoreFields.ChatRoom.lastReadAt).\(userID)": FirestoreDateCodec.timestamp(from: readAt),
        ]
    }
}
