//
//  ChatMessage.swift
//  matiapu
//

import Foundation

struct ChatMessage: Identifiable, Hashable {
    let id: String
    let conversationId: String
    let text: String
    let isFromCurrentUser: Bool
    let sentAt: Date
}
