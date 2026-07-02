//
//  FirestoreChatMessageMapper.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestoreChatMessageMapper {
    static let undecryptableMessageText = "（メッセージを表示できません）"

    static func message(
        from document: QueryDocumentSnapshot,
        roomID: String,
        currentUID: String?
    ) -> ChatMessage? {
        message(from: document.data(), documentID: document.documentID, roomID: roomID, currentUID: currentUID)
    }

    static func message(
        from data: [String: Any],
        documentID: String,
        roomID: String,
        currentUID: String?
    ) -> ChatMessage? {
        guard let resolved = resolveMessageText(from: data, roomID: roomID) else { return nil }

        let senderID = stringValue(
            from: data,
            keys: [
                FirestoreFields.ChatMessage.senderID,
                "senderId",
            ]
        ) ?? ""
        let sentAt = FirestoreDateCodec.date(from: data[FirestoreFields.ChatMessage.createdAt])
            ?? FirestoreDateCodec.date(from: data["createdAt"])
            ?? .now

        return ChatMessage(
            id: documentID,
            conversationId: roomID,
            text: resolved.text,
            isFromCurrentUser: senderID == currentUID,
            sentAt: sentAt
        )
    }

    static func writeData(
        senderID: String,
        recipientID: String,
        encryptedContent: String,
        iv: String,
        sentAt: Date = .now,
        isSystem: Bool
    ) -> [String: Any] {
        [
            FirestoreFields.ChatMessage.senderID: senderID,
            FirestoreFields.ChatMessage.recipientID: recipientID,
            FirestoreFields.ChatMessage.encryptedContent: encryptedContent,
            FirestoreFields.ChatMessage.iv: iv,
            FirestoreFields.ChatMessage.createdAt: FirestoreDateCodec.timestamp(from: sentAt),
            FirestoreFields.ChatMessage.isSystem: isSystem,
        ]
    }

    private struct ResolvedMessageText {
        let text: String
    }

    private static func resolveMessageText(from data: [String: Any], roomID: String) -> ResolvedMessageText? {
        let encrypted = encodedStringValue(
            from: data,
            keys: [
                FirestoreFields.ChatMessage.encryptedContent,
                "encryptedContent",
            ]
        )
        let iv = encodedStringValue(
            from: data,
            keys: [
                FirestoreFields.ChatMessage.iv,
                "last_message_iv",
                "lastMessageIV",
            ]
        )

        if let encrypted, let iv {
            if let decrypted = try? ChatCrypto.decrypt(
                encryptedContent: encrypted,
                iv: iv,
                roomID: roomID
            ) {
                return ResolvedMessageText(text: decrypted)
            }
            return ResolvedMessageText(text: undecryptableMessageText)
        }

        if let plaintext = stringValue(
            from: data,
            keys: [
                "text",
                "content",
                "content_text",
                "message",
            ]
        ) {
            return ResolvedMessageText(text: plaintext)
        }

        return nil
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

    private static func encodedStringValue(from data: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = data[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }

            if let value = data[key] as? Data, !value.isEmpty {
                return value.base64EncodedString()
            }
        }
        return nil
    }
}
