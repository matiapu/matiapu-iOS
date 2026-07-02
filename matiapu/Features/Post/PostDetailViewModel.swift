//
//  PostDetailViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class PostDetailViewModel {
    private(set) var rootComments: [Comment] = []
    private(set) var repliesByRootID: [String: [Comment]] = [:]
    private(set) var isLoading = false
    private(set) var isSubmitting = false
    var expandedRootIDs: Set<String> = []
    var replyingTo: Comment?
    var errorMessage: String?

    let post: Post
    private let loadPostComments: LoadPostCommentsUseCase
    private let submitPostComment: SubmitPostCommentUseCase

    init(
        post: Post,
        loadPostComments: LoadPostCommentsUseCase,
        submitPostComment: SubmitPostCommentUseCase
    ) {
        self.post = post
        self.loadPostComments = loadPostComments
        self.submitPostComment = submitPostComment
    }

    func loadComments() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let bundle = try await loadPostComments.execute(postID: post.id)
            rootComments = bundle.rootComments
            repliesByRootID = bundle.repliesByRootID
        } catch {
            rootComments = []
            repliesByRootID = [:]
            errorMessage = "コメントの読み込みに失敗しました。"
        }
    }

    func replyCount(for rootComment: Comment) -> Int {
        repliesByRootID[rootComment.id]?.count ?? 0
    }

    func replies(for rootComment: Comment) -> [Comment] {
        repliesByRootID[rootComment.id] ?? []
    }

    func isExpanded(_ rootComment: Comment) -> Bool {
        expandedRootIDs.contains(rootComment.id)
    }

    func toggleReplies(for rootComment: Comment) {
        if expandedRootIDs.contains(rootComment.id) {
            expandedRootIDs.remove(rootComment.id)
        } else {
            expandedRootIDs.insert(rootComment.id)
        }
    }

    func startReply(to comment: Comment) {
        replyingTo = comment
    }

    func cancelReply() {
        replyingTo = nil
    }

    func submitComment(text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let comment = try await submitPostComment.execute(
                postID: post.id,
                content: trimmed,
                replyingTo: replyingTo
            )

            if let replyingTo {
                let rootID = replyingTo.threadRootID
                var replies = repliesByRootID[rootID] ?? []
                replies.append(comment)
                repliesByRootID[rootID] = replies
                expandedRootIDs.insert(rootID)
                self.replyingTo = nil
            } else {
                rootComments.insert(comment, at: 0)
            }
            return true
        } catch {
            errorMessage = "コメントの投稿に失敗しました。"
            return false
        }
    }
}
