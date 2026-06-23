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
    let contentText: String
    let createdAt: Date
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
