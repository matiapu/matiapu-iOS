//
//  FirestoreLikeService.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirestoreLikeService: @unchecked Sendable {
    private let db = Firestore.firestore()

    static func likeDocumentID(postID: String, userID: String) -> String {
        "\(postID)_\(userID)"
    }

    func likePost(postID: String, userID: String) async throws {
        let documentID = Self.likeDocumentID(postID: postID, userID: userID)
        try await db.collection(FirestoreCollections.likes).document(documentID).setData([
            FirestoreFields.Like.postID: postID,
            FirestoreFields.Like.userID: userID,
            FirestoreFields.Like.createdAt: FirestoreDateCodec.timestamp(),
        ])
    }

    func unlikePost(postID: String, userID: String) async throws {
        let documentID = Self.likeDocumentID(postID: postID, userID: userID)
        try await db.collection(FirestoreCollections.likes).document(documentID).delete()
    }

    func hasLikedPost(postID: String, userID: String) async throws -> Bool {
        let documentID = Self.likeDocumentID(postID: postID, userID: userID)
        let snapshot = try await db.collection(FirestoreCollections.likes).document(documentID).getDocument()
        return snapshot.exists
    }

    func likedPostIDs(for userID: String) async throws -> [String] {
        let snapshot = try await db.collection(FirestoreCollections.likes)
            .whereField(FirestoreFields.Like.userID, isEqualTo: userID)
            .getDocuments()
        return snapshot.documents.compactMap { $0.data()[FirestoreFields.Like.postID] as? String }
    }

    func likeCounts(for postIDs: [String]) async throws -> [String: Int] {
        guard !postIDs.isEmpty else { return [:] }

        var counts = Dictionary(uniqueKeysWithValues: postIDs.map { ($0, 0) })
        let chunkSize = 10

        var index = postIDs.startIndex
        while index < postIDs.endIndex {
            let end = postIDs.index(index, offsetBy: chunkSize, limitedBy: postIDs.endIndex) ?? postIDs.endIndex
            let chunk = Array(postIDs[index..<end])
            index = end

            let snapshot = try await db.collection(FirestoreCollections.likes)
                .whereField(FirestoreFields.Like.postID, in: chunk)
                .getDocuments()

            for document in snapshot.documents {
                guard let postID = document.data()[FirestoreFields.Like.postID] as? String else { continue }
                counts[postID, default: 0] += 1
            }
        }

        return counts
    }
}
