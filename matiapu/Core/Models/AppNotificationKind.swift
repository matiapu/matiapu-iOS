//
//  AppNotificationKind.swift
//  matiapu
//

import Foundation

enum AppNotificationKind: String, Codable, Hashable, Sendable {
    case announcement
    case message
    case match

    var label: String {
        switch self {
        case .announcement:
            return "お知らせ"
        case .message:
            return "メッセージ"
        case .match:
            return "マッチ"
        }
    }

    var systemImageName: String {
        switch self {
        case .announcement:
            return "bell.fill"
        case .message:
            return "bubble.left.fill"
        case .match:
            return "heart.fill"
        }
    }
}
