//
//  FirestoreChatMessageMapper.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestoreChatMessageMapper {
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
                "sender_id",
            ]
        ) ?? ""
        let sentAt = FirestoreDateCodec.date(from: data[FirestoreFields.ChatMessage.createdAt])
            ?? FirestoreDateCodec.date(from: data["createdAt"])
            ?? FirestoreDateCodec.date(from: data["created_at"])
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
                "encrypted_content",
            ]
        )
        let iv = encodedStringValue(
            from: data,
            keys: [
                FirestoreFields.ChatMessage.iv,
                "iv",
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

            if let plaintext = plaintextValue(from: data) {
                return ResolvedMessageText(text: plaintext)
            }

            return ResolvedMessageText(text: ChatCrypto.undecryptableMessageText)
        }

        if let plaintext = plaintextValue(from: data) {
            return ResolvedMessageText(text: plaintext)
        }

        return nil
    }

    private static func plaintextValue(from data: [String: Any]) -> String? {
        stringValue(
            from: data,
            keys: [
                "text",
                "content",
                "content_text",
                "message",
                "body",
            ]
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
