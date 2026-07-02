//
//  ChatRepository.swift
//  matiapu
//

import Foundation

enum ChatRepositoryError: LocalizedError {
    case emptyMessage

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "メッセージを入力してください。"
        }
    }
}

protocol ChatRepository: Sendable {
    func fetchConversations() async throws -> [ChatConversation]
    func fetchMessages(conversationId: String) async throws -> [ChatMessage]
    func sendMessage(conversationId: String, text: String) async throws -> ChatMessage
}

final class MockChatRepository: ChatRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var conversations: [ChatConversation] = []
    private var messagesByConversation: [String: [ChatMessage]] = [:]

    func fetchConversations() async throws -> [ChatConversation] {
        locked { conversations.sorted { $0.updatedAt > $1.updatedAt } }
    }

    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        locked {
            (messagesByConversation[conversationId] ?? []).sorted { $0.sentAt < $1.sentAt }
        }
    }

    func sendMessage(conversationId: String, text: String) async throws -> ChatMessage {
        locked {
            let message = ChatMessage(
                id: UUID().uuidString,
                conversationId: conversationId,
                text: text,
                isFromCurrentUser: true,
                sentAt: .now
            )
            messagesByConversation[conversationId, default: []].append(message)

            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                let current = conversations[index]
                conversations[index] = ChatConversation(
                    id: current.id,
                    partnerId: current.partnerId,
                    partnerName: current.partnerName,
                    lastMessage: text,
                    updatedAt: .now,
                    unreadCount: 0
                )
            }

            return message
        }
    }

    func existingConversation(partnerId: String) -> ChatConversation? {
        locked { conversations.first { $0.partnerId == partnerId } }
    }

    func createMatchedConversation(partnerId: String, partnerName: String) -> ChatConversation {
        locked {
            let conversationId = "chat-\(partnerId)"
            let matchMessage = "マッチしました！メッセージを送ってみましょう。"
            let systemMessage = ChatMessage(
                id: "match-\(conversationId)",
                conversationId: conversationId,
                text: matchMessage,
                isFromCurrentUser: false,
                sentAt: .now
            )

            let conversation = ChatConversation(
                id: conversationId,
                partnerId: partnerId,
                partnerName: partnerName,
                lastMessage: matchMessage,
                updatedAt: .now,
                unreadCount: 1
            )

            conversations.append(conversation)
            messagesByConversation[conversationId] = [systemMessage]
            return conversation
        }
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
