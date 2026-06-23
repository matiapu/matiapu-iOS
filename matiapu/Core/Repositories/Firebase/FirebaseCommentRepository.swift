//
//  CommentRepository.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

protocol CommentRepository: Sendable {
    func createComment(_ input: CreateCommentInput) async throws -> Comment
    func getComment(commentId: String) async throws -> Comment
    func updateComment(commentId: String, contentText: String) async throws
    func deleteComment(commentId: String) async throws
    func getCommentsForPost(postId: String, options: CommentListOptions) async throws -> [Comment]
    func getRepliesForComment(commentId: String) async throws -> [Comment]
    func getThreadComments(rootCommentId: String) async throws -> [Comment]
}

final class FirebaseCommentRepository: CommentRepository, @unchecked Sendable {
    private let db = Firestore.firestore()

    func createComment(_ input: CreateCommentInput) async throws -> Comment {
        let documentRef = db.collection(FirestoreCollections.comments).document()
        let payload: [String: Any] = [
            "post_id": input.postID,
            "parent_id": input.parentID as Any,
            "root_id": input.rootID as Any,
            "author_uid": input.authorUID,
            "content_text": input.contentText,
            "created_at": FirestoreDateCodec.timestamp(),
        ]
        try await documentRef.setData(payload)
        return Comment(
            id: documentRef.documentID,
            postID: input.postID,
            parentID: input.parentID,
            rootID: input.rootID,
            authorUID: input.authorUID,
            contentText: input.contentText,
            createdAt: .now
        )
    }

    func getComment(commentId: String) async throws -> Comment {
        let snapshot = try await db.collection(FirestoreCollections.comments).document(commentId).getDocument()
        guard let data = snapshot.data(), let comment = mapComment(id: snapshot.documentID, data: data) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return comment
    }

    func updateComment(commentId: String, contentText: String) async throws {
        try await db.collection(FirestoreCollections.comments).document(commentId).updateData([
            "content_text": contentText,
        ])
    }

    func deleteComment(commentId: String) async throws {
        try await db.collection(FirestoreCollections.comments).document(commentId).delete()
    }

    func getCommentsForPost(postId: String, options: CommentListOptions) async throws -> [Comment] {
        var query: Query = db.collection(FirestoreCollections.comments)
            .whereField("post_id", isEqualTo: postId)
            .order(by: "created_at", descending: true)

        if let limit = options.limit {
            query = query.limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        let comments = snapshot.documents.compactMap { mapComment(id: $0.documentID, data: $0.data()) }
        if options.rootOnly {
            return comments.filter { $0.parentID == nil }
        }
        return comments
    }

    func getRepliesForComment(commentId: String) async throws -> [Comment] {
        let snapshot = try await db.collection(FirestoreCollections.comments)
            .whereField("parent_id", isEqualTo: commentId)
            .order(by: "created_at", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { mapComment(id: $0.documentID, data: $0.data()) }
    }

    func getThreadComments(rootCommentId: String) async throws -> [Comment] {
        let snapshot = try await db.collection(FirestoreCollections.comments)
            .whereField("root_id", isEqualTo: rootCommentId)
            .order(by: "created_at", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { mapComment(id: $0.documentID, data: $0.data()) }
    }

    private func mapComment(id: String, data: [String: Any]) -> Comment? {
        guard
            let postID = data["post_id"] as? String,
            let authorUID = data["author_uid"] as? String,
            let contentText = data["content_text"] as? String
        else {
            return nil
        }

        return Comment(
            id: id,
            postID: postID,
            parentID: data["parent_id"] as? String,
            rootID: data["root_id"] as? String,
            authorUID: authorUID,
            contentText: contentText,
            createdAt: FirestoreDateCodec.date(from: data["created_at"]) ?? .now
        )
    }
}
