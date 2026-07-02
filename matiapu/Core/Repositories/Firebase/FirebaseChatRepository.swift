//
//  FirebaseChatRepository.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirebaseChatRepository: ChatRepository, @unchecked Sendable {
    private let chatService: FirestoreChatService
    private let db = Firestore.firestore()

    init(chatService: FirestoreChatService) {
        self.chatService = chatService
    }

    func fetchConversations() async throws -> [ChatConversation] {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let rooms = try await chatService.fetchRooms(for: uid)

        return await withTaskGroup(of: ChatConversation?.self) { group in
            for room in rooms {
                group.addTask {
                    guard let partnerID = room.partnerID(currentUID: uid) else { return nil }
                    let partnerName = await self.partnerName(for: partnerID)
                    return room.conversation(currentUID: uid, partnerName: partnerName)
                }
            }

            var conversations: [ChatConversation] = []
            conversations.reserveCapacity(rooms.count)
            for await conversation in group {
                if let conversation {
                    conversations.append(conversation)
                }
            }
            return conversations.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        return try await chatService.fetchMessages(roomID: conversationId, currentUID: uid)
    }

    func sendMessage(conversationId: String, text: String) async throws -> ChatMessage {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let roomSnapshot = try await db.collection(FirestoreCollections.chatRooms)
            .document(conversationId)
            .getDocument()

        guard
            let room = FirestoreChatRoomMapper.room(from: roomSnapshot),
            let recipientID = room.partnerID(currentUID: uid)
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

    private func partnerName(for partnerID: String) async -> String {
        do {
            let snapshot = try await db.collection(FirestoreCollections.users).document(partnerID).getDocument()
            guard let data = snapshot.data() else { return UserPublicProfile.fallbackDisplayName }
            return FirestoreUserPublicProfileMapper.map(from: data, uid: partnerID).displayName
        } catch {
            return UserPublicProfile.fallbackDisplayName
        }
    }
}
