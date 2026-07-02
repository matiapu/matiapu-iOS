//
//  MockCommentRepository.swift
//  matiapu
//

import Foundation

final class MockCommentRepository: CommentRepository, @unchecked Sendable {
    private var comments: [Comment] = []
    private let lock = NSLock()

    func createComment(_ input: CreateCommentInput) async throws -> Comment {
        let comment = Comment(
            id: UUID().uuidString,
            postID: input.postID,
            parentID: input.parentID,
            rootID: input.rootID,
            authorUID: input.authorUID,
            contentText: input.contentText,
            createdAt: .now
        )
        locked { comments.append(comment) }
        return comment
    }

    func getComment(commentId: String) async throws -> Comment {
        guard let comment = locked({ comments.first { $0.id == commentId } }) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return comment
    }

    func updateComment(commentId: String, contentText: String) async throws {
        locked {
            guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }
            let existing = comments[index]
            comments[index] = Comment(
                id: existing.id,
                postID: existing.postID,
                parentID: existing.parentID,
                rootID: existing.rootID,
                authorUID: existing.authorUID,
                contentText: contentText,
                createdAt: existing.createdAt
            )
        }
    }

    func deleteComment(commentId: String) async throws {
        locked { comments.removeAll { $0.id == commentId } }
    }

    func getCommentsForPost(postId: String, options: CommentListOptions) async throws -> [Comment] {
        let filtered = locked {
            comments
                .filter { $0.postID == postId }
                .sorted { $0.createdAt > $1.createdAt }
        }
        if options.rootOnly {
            return filtered.filter { $0.parentID == nil }
        }
        if let limit = options.limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    func getRepliesForComment(commentId: String) async throws -> [Comment] {
        locked {
            comments
                .filter { $0.parentID == commentId }
                .sorted { $0.createdAt < $1.createdAt }
        }
    }

    func getThreadComments(rootCommentId: String) async throws -> [Comment] {
        locked {
            comments
                .filter { $0.rootID == rootCommentId }
                .sorted { $0.createdAt < $1.createdAt }
        }
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
