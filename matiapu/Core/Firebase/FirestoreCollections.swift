//
//  FirestoreCollections.swift
//  matiapu
//

import Foundation

enum FirestoreCollections {
    static let users = "users"
    static let posts = "posts"
    static let comments = "comments"
    static let shelters = "shelters"
    static let disasters = "disasters"
    static let likes = "likes"
    static let chatRooms = "chat_rooms"
    static let messages = "messages"
    static let qaQuestions = "qa_questions"
    static let answers = "answers"
    static let matches = "matches"
}

enum FirestoreFields {
    enum User {
        static let uid = "uid"
        static let email = "email"
        static let lastName = "lastName"
        static let firstName = "firstName"
        static let lastNameKana = "lastNameKana"
        static let firstNameKana = "firstNameKana"
        static let nickname = "nickname"
        static let birthDate = "birthDate"
        static let address = "address"
        static let profileImage = "profileImage"
        static let isVerified = "isVerified"
        static let isProfileCompleted = "isProfileCompleted"
        static let isRegistered = "isRegistered"
        static let role = "role"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    enum Post {
        static let authorUID = "author_uid"
        static let userBadge = "user_badge"
        static let contentText = "content_text"
        static let imageURL = "image_url"
        static let geoLocation = "geo_location"
        static let status = "status"
        static let createdAt = "created_at"
        static let title = "title"
        static let tag = "tag"
        static let authorDisplayName = "author_display_name"
    }

    enum Like {
        static let postID = "post_id"
        static let userID = "user_id"
        static let createdAt = "created_at"
    }

    enum Match {
        static let userUID = "user_uid"
        static let politicianUID = "politician_uid"
        static let userAction = "user_action"
        static let politicianAction = "politician_action"
        static let status = "status"
        static let matchedAt = "matched_at"
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
    }

    enum ChatRoom {
        static let userIDs = "user_ids"
        static let createdAt = "created_at"
        static let lastMessageAt = "last_message_at"
        static let lastMessageText = "last_message_text"
        static let lastMessageIV = "last_message_iv"
    }

    enum ChatMessage {
        static let senderID = "sender_id"
        static let recipientID = "recipient_id"
        static let encryptedContent = "encrypted_content"
        static let iv = "iv"
        static let createdAt = "created_at"
        static let isSystem = "is_system"
    }
}

enum FirestorePostStatus {
    static let publicStatus = "Public"
    static let privateStatus = "Private"
    static let draft = "Draft"
}

enum FirestoreMatchAction: String {
    case like
    case bad
    case none
}

enum FirestoreMatchStatus: String {
    case pending
    case matched
}
