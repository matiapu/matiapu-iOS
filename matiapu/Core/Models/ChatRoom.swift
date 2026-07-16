//
//  ChatRoom.swift
//  matiapu
//

import Foundation

/// Firestore `chat_rooms` ドキュメントに対応するモデル
struct ChatRoom: Identifiable, Sendable {
    let id: String
    let userIDs: [String]
    let createdAt: Date
    let lastMessageAt: Date
    let lastMessageText: String?
    let lastMessageIV: String?
    let lastMessageSenderID: String?
    /// ユーザーごとの最終既読時刻
    let lastReadAtByUserID: [String: Date]

    nonisolated func partnerID(currentUID: String) -> String? {
        userIDs.first { $0 != currentUID }
    }

    nonisolated func lastReadAt(for userID: String) -> Date? {
        lastReadAtByUserID[userID]
    }

    nonisolated func unreadCount(for currentUID: String) -> Int {
        guard let senderID = lastMessageSenderID, senderID != currentUID, senderID != "system" else {
            return 0
        }
        guard let myReadAt = lastReadAt(for: currentUID) else {
            return 1
        }
        return lastMessageAt > myReadAt ? 1 : 0
    }

    nonisolated func decryptedLastMessage() -> String? {
        guard
            let lastMessageText,
            let lastMessageIV,
            !lastMessageText.isEmpty,
            !lastMessageIV.isEmpty
        else {
            return nil
        }

        return ChatCrypto.decryptMessage(
            encryptedContent: lastMessageText,
            iv: lastMessageIV,
            roomID: id
        )
    }

    nonisolated func conversation(
        currentUID: String,
        partnerName: String,
        partnerProfileImageURL: String? = nil,
        unreadCount: Int? = nil
    ) -> ChatConversation? {
        guard let partnerID = partnerID(currentUID: currentUID) else { return nil }

        return ChatConversation(
            id: id,
            partnerId: partnerID,
            partnerName: partnerName,
            partnerProfileImageURL: partnerProfileImageURL,
            lastMessage: decryptedLastMessage() ?? "",
            updatedAt: lastMessageAt,
            unreadCount: unreadCount ?? self.unreadCount(for: currentUID)
        )
    }
}
