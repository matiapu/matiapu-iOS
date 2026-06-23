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
}
