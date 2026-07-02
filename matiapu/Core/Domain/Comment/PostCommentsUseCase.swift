//
//  PostCommentsUseCase.swift
//  matiapu
//

import Foundation

struct LoadPostCommentsUseCase: Sendable {
    private let commentRepository: any CommentRepository
    private let authRepository: any AuthRepository

    init(commentRepository: any CommentRepository, authRepository: any AuthRepository) {
        self.commentRepository = commentRepository
        self.authRepository = authRepository
    }

    func execute(postID: String) async throws -> PostCommentsBundle {
        let allComments = try await commentRepository.getCommentsForPost(
            postId: postID,
            options: CommentListOptions(limit: 200)
        )
        let enriched = await enrichComments(allComments)

        let rootComments = enriched
            .filter(\.isRoot)
            .sorted { $0.createdAt > $1.createdAt }

        var repliesByRootID: [String: [Comment]] = [:]
        for reply in enriched where !reply.isRoot {
            let rootID = reply.threadRootID
            repliesByRootID[rootID, default: []].append(reply)
        }
        for rootID in repliesByRootID.keys {
            repliesByRootID[rootID]?.sort { $0.createdAt < $1.createdAt }
        }

        return PostCommentsBundle(
            rootComments: rootComments,
            repliesByRootID: repliesByRootID
        )
    }

    private func enrichComments(_ comments: [Comment]) async -> [Comment] {
        let authorIDs = Array(Set(comments.map(\.authorUID)))
        guard !authorIDs.isEmpty else { return comments }

        let profiles = (try? await authRepository.fetchPublicProfiles(userIDs: authorIDs)) ?? [:]
        return comments.map { comment in
            guard let profile = profiles[comment.authorUID] else { return comment }
            return comment.withAuthor(profile)
        }
    }
}

struct SubmitPostCommentUseCase: Sendable {
    private let commentRepository: any CommentRepository
    private let authRepository: any AuthRepository

    init(
        commentRepository: any CommentRepository,
        authRepository: any AuthRepository
    ) {
        self.commentRepository = commentRepository
        self.authRepository = authRepository
    }

    func execute(
        postID: String,
        content: String,
        replyingTo parent: Comment? = nil
    ) async throws -> Comment {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw PostCommentsUseCaseError.emptyContent
        }

        let user = try await authRepository.fetchCurrentUser()
        let input = CreateCommentInput(
            postID: postID,
            parentID: parent?.id,
            rootID: parent?.threadRootID,
            authorUID: user.id,
            contentText: trimmed
        )
        let comment = try await commentRepository.createComment(input)
        return comment.withAuthor(user.publicProfile)
    }
}

enum PostCommentsUseCaseError: LocalizedError {
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "コメントを入力してください。"
        }
    }
}
