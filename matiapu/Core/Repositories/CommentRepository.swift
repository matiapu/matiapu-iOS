//
//  CommentRepository.swift
//  matiapu
//

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
