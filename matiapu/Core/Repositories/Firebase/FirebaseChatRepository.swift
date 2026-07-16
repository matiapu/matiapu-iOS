//
//  FirebaseChatRepository.swift
//  matiapu
//

@preconcurrency import FirebaseFirestore
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
        let partnerIDs = rooms.compactMap { $0.partnerID(currentUID: uid) }
        let profiles = await fetchPartnerProfiles(partnerIDs)

        return rooms.compactMap { room in
            guard let partnerID = room.partnerID(currentUID: uid) else { return nil }
            let profile = profiles[partnerID]
            return room.conversation(
                currentUID: uid,
                partnerName: profile?.displayName ?? UserPublicProfile.fallbackDisplayName,
                partnerProfileImageURL: profile?.profileImageURL
            )
        }
        .sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        return try await chatService.fetchMessages(roomID: conversationId, currentUID: uid)
    }

    func observeMessages(
        conversationId: String,
        onUpdate: @escaping @Sendable ([ChatMessage]) -> Void
    ) async throws -> ChatMessageObservation {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        return chatService.observeMessages(
            roomID: conversationId,
            currentUID: uid,
            onUpdate: onUpdate
        )
    }

    func observeRoom(
        conversationId: String,
        onUpdate: @escaping @Sendable (ChatRoom) -> Void
    ) async throws -> ChatMessageObservation {
        _ = try await FirebaseAuthSession.ensureSignedIn()
        return chatService.observeRoom(roomID: conversationId, onUpdate: onUpdate)
    }

    func markConversationAsRead(conversationId: String) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let readAt = Date.now
        try await chatService.markRoomAsRead(roomID: conversationId, userID: uid, readAt: readAt)
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

    private func fetchPartnerProfiles(_ partnerIDs: [String]) async -> [String: UserPublicProfile] {
        let uniqueIDs = Array(Set(partnerIDs))
        guard !uniqueIDs.isEmpty else { return [:] }

        return await withTaskGroup(of: (String, UserPublicProfile?).self) { group in
            for partnerID in uniqueIDs {
                group.addTask {
                    (partnerID, await self.partnerProfile(for: partnerID))
                }
            }

            var profiles: [String: UserPublicProfile] = [:]
            profiles.reserveCapacity(uniqueIDs.count)
            for await (partnerID, profile) in group {
                if let profile {
                    profiles[partnerID] = profile
                }
            }
            return profiles
        }
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
