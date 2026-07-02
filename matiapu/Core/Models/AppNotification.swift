//
//  AppNotification.swift
//  matiapu
//

import Foundation

struct AppNotification: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let kind: AppNotificationKind
    let title: String
    let body: String
    let publishedAt: Date
    let isRead: Bool
    /// チャットルーム ID など、通知タップ時の遷移先
    let relatedID: String?

    init(
        id: String,
        kind: AppNotificationKind = .announcement,
        title: String,
        body: String,
        publishedAt: Date,
        isRead: Bool,
        relatedID: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.publishedAt = publishedAt
        self.isRead = isRead
        self.relatedID = relatedID
    }
}
