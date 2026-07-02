//
//  FirebaseMatchRepository.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirebaseMatchRepository: MatchRepository, @unchecked Sendable {
    private let matchService: FirestoreMatchService
    private let db = Firestore.firestore()

    init(matchService: FirestoreMatchService) {
        self.matchService = matchService
    }

    func recordLegislatorLike(legislatorId: String, post: Post) async throws -> MatchResult? {
        guard let citizenUserId = post.authorUserId else { return nil }
        let politicianName = try await politicianName(for: legislatorId)
        return try await matchService.handlePoliticianLike(
            politicianUID: legislatorId,
            userUID: citizenUserId,
            politicianName: politicianName
        )
    }

    func recordCitizenLike(
        citizenUserId: String,
        legislatorId: String,
        legislatorName: String
    ) async throws -> MatchResult? {
        try await matchService.handleUserLike(
            userUID: citizenUserId,
            politicianUID: legislatorId,
            politicianName: legislatorName
        )
    }

    func recordCitizenBad(citizenUserId: String, legislatorId: String) async throws {
        try await matchService.handleUserBad(userUID: citizenUserId, politicianUID: legislatorId)
    }

    private func politicianName(for politicianUID: String) async throws -> String {
        let snapshot = try await db.collection(FirestoreCollections.users).document(politicianUID).getDocument()
        guard let data = snapshot.data() else { return "議員" }
        return FirestoreUserMapper.profile(from: data, uid: politicianUID).displayName
    }
}
