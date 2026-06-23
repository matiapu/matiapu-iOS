//
//  FirestoreChatService.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirestoreChatService: @unchecked Sendable {
    private let db = Firestore.firestore()

    func getOrCreateChatRoom(uid1: String, uid2: String) async throws -> String {
        let roomID = ChatCrypto.chatRoomID(uid1: uid1, uid2: uid2)
        let roomRef = db.collection(FirestoreCollections.chatRooms).document(roomID)
        let snapshot = try await roomRef.getDocument()

        if snapshot.exists {
            return roomID
        }

        try await roomRef.setData([
            FirestoreFields.ChatRoom.userIDs: [uid1, uid2].sorted(),
            FirestoreFields.ChatRoom.createdAt: FirestoreDateCodec.timestamp(),
            FirestoreFields.ChatRoom.lastMessageAt: FirestoreDateCodec.timestamp(),
        ])
        return roomID
    }

    func sendSystemNotification(roomID: String, text: String) async throws {
        let encrypted = try ChatCrypto.encrypt(text: text, roomID: roomID)
        let messageRef = db
            .collection(FirestoreCollections.chatRooms)
            .document(roomID)
            .collection(FirestoreCollections.messages)
            .document()

        try await messageRef.setData([
            FirestoreFields.ChatMessage.senderID: "system",
            FirestoreFields.ChatMessage.recipientID: "system",
            FirestoreFields.ChatMessage.encryptedContent: encrypted.encryptedContent,
            FirestoreFields.ChatMessage.iv: encrypted.iv,
            FirestoreFields.ChatMessage.createdAt: FirestoreDateCodec.timestamp(),
            FirestoreFields.ChatMessage.isSystem: true,
        ])

        try await db.collection(FirestoreCollections.chatRooms).document(roomID).updateData([
            FirestoreFields.ChatRoom.lastMessageAt: FirestoreDateCodec.timestamp(),
            FirestoreFields.ChatRoom.lastMessageText: encrypted.encryptedContent,
            FirestoreFields.ChatRoom.lastMessageIV: encrypted.iv,
        ])
    }

    func sendMessage(
        roomID: String,
        senderID: String,
        recipientID: String,
        text: String
    ) async throws -> ChatMessage {
        let encrypted = try ChatCrypto.encrypt(text: text, roomID: roomID)
        let messageRef = db
            .collection(FirestoreCollections.chatRooms)
            .document(roomID)
            .collection(FirestoreCollections.messages)
            .document()

        let sentAt = Date.now
        try await messageRef.setData([
            FirestoreFields.ChatMessage.senderID: senderID,
            FirestoreFields.ChatMessage.recipientID: recipientID,
            FirestoreFields.ChatMessage.encryptedContent: encrypted.encryptedContent,
            FirestoreFields.ChatMessage.iv: encrypted.iv,
            FirestoreFields.ChatMessage.createdAt: FirestoreDateCodec.timestamp(from: sentAt),
            FirestoreFields.ChatMessage.isSystem: false,
        ])

        try await db.collection(FirestoreCollections.chatRooms).document(roomID).updateData([
            FirestoreFields.ChatRoom.lastMessageAt: FirestoreDateCodec.timestamp(from: sentAt),
            FirestoreFields.ChatRoom.lastMessageText: encrypted.encryptedContent,
            FirestoreFields.ChatRoom.lastMessageIV: encrypted.iv,
        ])

        return ChatMessage(
            id: messageRef.documentID,
            conversationId: roomID,
            text: text,
            isFromCurrentUser: true,
            sentAt: sentAt
        )
    }

    func fetchRooms(for userID: String) async throws -> [QueryDocumentSnapshot] {
        let snapshot = try await db.collection(FirestoreCollections.chatRooms)
            .whereField(FirestoreFields.ChatRoom.userIDs, arrayContains: userID)
            .order(by: FirestoreFields.ChatRoom.lastMessageAt, descending: true)
            .getDocuments()
        return snapshot.documents
    }

    func fetchMessages(roomID: String) async throws -> [ChatMessage] {
        let uid = FirebaseAuthSession.currentUID
        let snapshot = try await db.collection(FirestoreCollections.chatRooms)
            .document(roomID)
            .collection(FirestoreCollections.messages)
            .order(by: FirestoreFields.ChatMessage.createdAt, descending: false)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try mapMessage(document: document, roomID: roomID, currentUID: uid)
        }
    }

    func existingRoomID(partnerID: String, currentUID: String) async throws -> String? {
        let roomID = ChatCrypto.chatRoomID(uid1: currentUID, uid2: partnerID)
        let snapshot = try await db.collection(FirestoreCollections.chatRooms).document(roomID).getDocument()
        return snapshot.exists ? roomID : nil
    }

    func createMatchedConversation(
        currentUID: String,
        partnerID: String,
        partnerName: String
    ) async throws -> ChatConversation {
        let roomID = try await getOrCreateChatRoom(uid1: currentUID, uid2: partnerID)
        let matchMessage = "マッチしました！メッセージを送ってみましょう。"
        try await sendSystemNotification(roomID: roomID, text: matchMessage)

        return ChatConversation(
            id: roomID,
            partnerId: partnerID,
            partnerName: partnerName,
            lastMessage: matchMessage,
            updatedAt: .now,
            unreadCount: 1
        )
    }

    func mapConversation(
        document: QueryDocumentSnapshot,
        currentUID: String,
        partnerNameResolver: (String) async throws -> String
    ) async throws -> ChatConversation? {
        let data = document.data()
        guard let userIDs = data[FirestoreFields.ChatRoom.userIDs] as? [String] else {
            return nil
        }

        let partnerID = userIDs.first { $0 != currentUID } ?? ""
        guard !partnerID.isEmpty else { return nil }

        let partnerName = try await partnerNameResolver(partnerID)
        let updatedAt = FirestoreDateCodec.date(from: data[FirestoreFields.ChatRoom.lastMessageAt]) ?? .now

        let lastMessage: String
        if
            let encrypted = data[FirestoreFields.ChatRoom.lastMessageText] as? String,
            let iv = data[FirestoreFields.ChatRoom.lastMessageIV] as? String,
            !encrypted.isEmpty,
            !iv.isEmpty
        {
            lastMessage = (try? ChatCrypto.decrypt(
                encryptedContent: encrypted,
                iv: iv,
                roomID: document.documentID
            )) ?? "新しいメッセージ"
        } else {
            lastMessage = ""
        }

        return ChatConversation(
            id: document.documentID,
            partnerId: partnerID,
            partnerName: partnerName,
            lastMessage: lastMessage,
            updatedAt: updatedAt,
            unreadCount: 0
        )
    }

    private func mapMessage(
        document: QueryDocumentSnapshot,
        roomID: String,
        currentUID: String?
    ) throws -> ChatMessage? {
        let data = document.data()
        guard
            let encrypted = data[FirestoreFields.ChatMessage.encryptedContent] as? String,
            let iv = data[FirestoreFields.ChatMessage.iv] as? String
        else {
            return nil
        }

        let text = try ChatCrypto.decrypt(
            encryptedContent: encrypted,
            iv: iv,
            roomID: roomID
        )
        let senderID = data[FirestoreFields.ChatMessage.senderID] as? String ?? ""
        let sentAt = FirestoreDateCodec.date(from: data[FirestoreFields.ChatMessage.createdAt]) ?? .now

        return ChatMessage(
            id: document.documentID,
            conversationId: roomID,
            text: text,
            isFromCurrentUser: senderID == currentUID,
            sentAt: sentAt
        )
    }
}
