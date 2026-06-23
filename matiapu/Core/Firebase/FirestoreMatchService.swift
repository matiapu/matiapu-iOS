//
//  FirestoreMatchService.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirestoreMatchService: @unchecked Sendable {
    private let db = Firestore.firestore()
    private let chatService: FirestoreChatService

    init(chatService: FirestoreChatService) {
        self.chatService = chatService
    }

    static func matchDocumentID(userUID: String, politicianUID: String) -> String {
        "\(userUID)_\(politicianUID)"
    }

    func handleUserLike(
        userUID: String,
        politicianUID: String,
        politicianName: String
    ) async throws -> MatchResult {
        try await applyAction(
            userUID: userUID,
            politicianUID: politicianUID,
            politicianName: politicianName,
            actor: .user,
            action: .like
        )
    }

    func handlePoliticianLike(
        politicianUID: String,
        userUID: String,
        politicianName: String
    ) async throws -> MatchResult {
        try await applyAction(
            userUID: userUID,
            politicianUID: politicianUID,
            politicianName: politicianName,
            actor: .politician,
            action: .like
        )
    }

    func handleUserBad(userUID: String, politicianUID: String) async throws {
        try await deleteMatch(userUID: userUID, politicianUID: politicianUID)
    }

    func handlePoliticianBad(politicianUID: String, userUID: String) async throws {
        try await deleteMatch(userUID: userUID, politicianUID: politicianUID)
    }

    private enum Actor {
        case user
        case politician
    }

    private func applyAction(
        userUID: String,
        politicianUID: String,
        politicianName: String,
        actor: Actor,
        action: FirestoreMatchAction
    ) async throws -> MatchResult {
        let documentID = Self.matchDocumentID(userUID: userUID, politicianUID: politicianUID)
        let documentRef = db.collection(FirestoreCollections.matches).document(documentID)
        let snapshot = try await documentRef.getDocument()
        let now = FirestoreDateCodec.timestamp()

        var data = snapshot.data() ?? [
            FirestoreFields.Match.userUID: userUID,
            FirestoreFields.Match.politicianUID: politicianUID,
            FirestoreFields.Match.userAction: FirestoreMatchAction.none.rawValue,
            FirestoreFields.Match.politicianAction: FirestoreMatchAction.none.rawValue,
            FirestoreFields.Match.status: FirestoreMatchStatus.pending.rawValue,
            FirestoreFields.Match.createdAt: now,
        ]

        switch actor {
        case .user:
            data[FirestoreFields.Match.userAction] = action.rawValue
        case .politician:
            data[FirestoreFields.Match.politicianAction] = action.rawValue
        }
        data[FirestoreFields.Match.updatedAt] = now

        let userAction = data[FirestoreFields.Match.userAction] as? String ?? FirestoreMatchAction.none.rawValue
        let politicianAction = data[FirestoreFields.Match.politicianAction] as? String ?? FirestoreMatchAction.none.rawValue

        if
            userAction == FirestoreMatchAction.like.rawValue,
            politicianAction == FirestoreMatchAction.like.rawValue
        {
            data[FirestoreFields.Match.status] = FirestoreMatchStatus.matched.rawValue
            data[FirestoreFields.Match.matchedAt] = now
            try await documentRef.setData(data, merge: true)

            let conversation = try await chatService.createMatchedConversation(
                currentUID: userUID,
                partnerID: politicianUID,
                partnerName: politicianName
            )
            return .matched(conversation)
        }

        data[FirestoreFields.Match.status] = FirestoreMatchStatus.pending.rawValue
        try await documentRef.setData(data, merge: true)
        return .pending
    }

    private func deleteMatch(userUID: String, politicianUID: String) async throws {
        let documentID = Self.matchDocumentID(userUID: userUID, politicianUID: politicianUID)
        try await db.collection(FirestoreCollections.matches).document(documentID).delete()
    }
}
