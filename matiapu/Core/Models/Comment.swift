//
//  Comment.swift
//  matiapu
//

import Foundation

struct Comment: Identifiable, Hashable {
    let id: String
    let postID: String
    let parentID: String?
    let rootID: String?
    let authorUID: String
    let authorDisplayName: String
    let authorProfileImageURL: String?
    let contentText: String
    let createdAt: Date

    init(
        id: String,
        postID: String,
        parentID: String?,
        rootID: String?,
        authorUID: String,
        authorDisplayName: String = UserPublicProfile.fallbackDisplayName,
        authorProfileImageURL: String? = nil,
        contentText: String,
        createdAt: Date
    ) {
        self.id = id
        self.postID = postID
        self.parentID = parentID
        self.rootID = rootID
        self.authorUID = authorUID
        self.authorDisplayName = authorDisplayName
        self.authorProfileImageURL = authorProfileImageURL
        self.contentText = contentText
        self.createdAt = createdAt
    }

    func withAuthor(_ profile: UserPublicProfile) -> Comment {
        Comment(
            id: id,
            postID: postID,
            parentID: parentID,
            rootID: rootID,
            authorUID: authorUID,
            authorDisplayName: profile.displayName,
            authorProfileImageURL: profile.profileImageURL,
            contentText: contentText,
            createdAt: createdAt
        )
    }

    var isRoot: Bool {
        parentID == nil
    }

    var threadRootID: String {
        rootID ?? id
    }
}

struct PostCommentsBundle: Sendable {
    let rootComments: [Comment]
    let repliesByRootID: [String: [Comment]]

    func replyCount(for rootID: String) -> Int {
        repliesByRootID[rootID]?.count ?? 0
    }
}

struct CreateCommentInput: Sendable {
    let postID: String
    let parentID: String?
    let rootID: String?
    let authorUID: String
    let contentText: String
}

struct CommentListOptions: Sendable {
    var rootOnly = false
    var limit: Int?
}
