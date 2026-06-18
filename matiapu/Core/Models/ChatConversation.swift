//
//  ChatConversation.swift
//  matiapu
//

import Foundation

struct ChatConversation: Identifiable, Hashable {
    let id: String
    let partnerId: String
    let partnerName: String
    let lastMessage: String
    let updatedAt: Date
    let unreadCount: Int
}
