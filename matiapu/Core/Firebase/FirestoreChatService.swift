//
//  FirestoreChatService.swift
//  matiapu
//

@preconcurrency import FirebaseFirestore
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

        try await roomRef.setData(FirestoreChatRoomMapper.creationData(uid1: uid1, uid2: uid2))
        return roomID
    }

    func sendSystemNotification(roomID: String, text: String) async throws {
        let encrypted = try ChatCrypto.encrypt(text: text, roomID: roomID)
        let messageRef = db
            .collection(FirestoreCollections.chatRooms)
            .document(roomID)
            .collection(FirestoreCollections.messages)
            .document()

        try await messageRef.setData(
            FirestoreChatMessageMapper.writeData(
                senderID: "system",
                recipientID: "system",
                encryptedContent: encrypted.encryptedContent,
                iv: encrypted.iv,
                isSystem: true
            )
        )

        try await db.collection(FirestoreCollections.chatRooms).document(roomID).updateData(
            FirestoreChatRoomMapper.lastMessageUpdate(
                encryptedContent: encrypted.encryptedContent,
                iv: encrypted.iv,
                senderID: "system"
            )
        )
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
        try await messageRef.setData(
            FirestoreChatMessageMapper.writeData(
                senderID: senderID,
                recipientID: recipientID,
                encryptedContent: encrypted.encryptedContent,
                iv: encrypted.iv,
                sentAt: sentAt,
                isSystem: false
            )
        )

        try await db.collection(FirestoreCollections.chatRooms).document(roomID).updateData(
            FirestoreChatRoomMapper.lastMessageUpdate(
                encryptedContent: encrypted.encryptedContent,
                iv: encrypted.iv,
                senderID: senderID,
                sentAt: sentAt
            )
        )

        return ChatMessage(
            id: messageRef.documentID,
            conversationId: roomID,
            text: text,
            isFromCurrentUser: true,
            sentAt: sentAt
        )
    }

    func fetchRooms(for userID: String) async throws -> [ChatRoom] {
        let snapshot = try await db.collection(FirestoreCollections.chatRooms)
            .whereField(FirestoreFields.ChatRoom.userIDs, arrayContains: userID)
            .getDocuments()

        return snapshot.documents
            .compactMap(FirestoreChatRoomMapper.room(from:))
            .sorted { $0.lastMessageAt > $1.lastMessageAt }
    }

    func fetchMessages(roomID: String, currentUID: String) async throws -> [ChatMessage] {
        let snapshot = try await messagesQuery(roomID: roomID).getDocuments()
        return mapMessages(from: snapshot.documents, roomID: roomID, currentUID: currentUID)
    }

    func observeMessages(
        roomID: String,
        currentUID: String,
        onUpdate: @escaping @Sendable ([ChatMessage]) -> Void
    ) -> ChatMessageObservation {
        let registration = messagesQuery(roomID: roomID).addSnapshotListener { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let messages = self.mapMessages(
                from: documents,
                roomID: roomID,
                currentUID: currentUID
            )
            onUpdate(messages)
        }
        return ChatMessageObservation {
            registration.remove()
        }
    }

    private func messagesQuery(roomID: String) -> Query {
        db.collection(FirestoreCollections.chatRooms)
            .document(roomID)
            .collection(FirestoreCollections.messages)
            .order(by: FirestoreFields.ChatMessage.createdAt)
    }

    private func mapMessages(
        from documents: [QueryDocumentSnapshot],
        roomID: String,
        currentUID: String
    ) -> [ChatMessage] {
        documents.compactMap { document in
            FirestoreChatMessageMapper.message(
                from: document,
                roomID: roomID,
                currentUID: currentUID
            )
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

        let profile = await partnerProfile(for: partnerID)

        return ChatConversation(
            id: roomID,
            partnerId: partnerID,
            partnerName: profile?.displayName ?? partnerName,
            partnerProfileImageURL: profile?.profileImageURL,
            lastMessage: matchMessage,
            updatedAt: .now,
            unreadCount: 1
        )
    }

    private func partnerProfile(for partnerID: String) async -> UserPublicProfile? {
        do {
            let snapshot = try await db.collection(FirestoreCollections.users).document(partnerID).getDocument()
            guard let data = snapshot.data() else { return nil }
            return FirestoreUserPublicProfileMapper.map(from: data, uid: partnerID)
        } catch {
            return nil
        }
    }
}
