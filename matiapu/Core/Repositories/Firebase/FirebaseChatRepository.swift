//
//  FirebaseChatRepository.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirebaseChatRepository: ChatRepository, @unchecked Sendable {
    private let chatService: FirestoreChatService
    private let authRepository: any AuthRepository
    private let db = Firestore.firestore()

    init(chatService: FirestoreChatService, authRepository: any AuthRepository) {
        self.chatService = chatService
        self.authRepository = authRepository
    }

    func fetchConversations() async throws -> [ChatConversation] {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let documents = try await chatService.fetchRooms(for: uid)

        var conversations: [ChatConversation] = []
        conversations.reserveCapacity(documents.count)

        for document in documents {
            guard let conversation = try await chatService.mapConversation(
                document: document,
                currentUID: uid,
                partnerNameResolver: { [weak self] partnerID in
                    guard let self else { return "ユーザー" }
                    return try await self.partnerName(for: partnerID)
                }
            ) else {
                continue
            }
            conversations.append(conversation)
        }

        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        try await chatService.fetchMessages(roomID: conversationId)
    }

    func sendMessage(conversationId: String, text: String) async throws -> ChatMessage {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let roomSnapshot = try await db.collection(FirestoreCollections.chatRooms)
            .document(conversationId)
            .getDocument()

        guard
            let userIDs = roomSnapshot.data()?[FirestoreFields.ChatRoom.userIDs] as? [String],
            let recipientID = userIDs.first(where: { $0 != uid })
        else {
            throw FirebaseRepositoryError.invalidData
        }

        return try await chatService.sendMessage(
            roomID: conversationId,
            senderID: uid,
            recipientID: recipientID,
            text: text
        )
    }

    private func partnerName(for partnerID: String) async throws -> String {
        let snapshot = try await db.collection(FirestoreCollections.users).document(partnerID).getDocument()
        guard let data = snapshot.data() else { return "ユーザー" }
        return FirestoreUserMapper.profile(from: data, uid: partnerID).displayName
    }
}
