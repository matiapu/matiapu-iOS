//
//  ChatUseCases.swift
//  matiapu
//

import Foundation

struct FetchConversationsUseCase: Sendable {
    private let chatRepository: any ChatRepository

    init(chatRepository: any ChatRepository) {
        self.chatRepository = chatRepository
    }

    func execute() async throws -> [ChatConversation] {
        try await chatRepository.fetchConversations()
    }
}

struct ChatRoomUseCase: Sendable {
    private let chatRepository: any ChatRepository

    init(chatRepository: any ChatRepository) {
        self.chatRepository = chatRepository
    }

    func loadMessages(conversationId: String) async throws -> [ChatMessage] {
        try await chatRepository.fetchMessages(conversationId: conversationId)
    }

    func observeMessages(
        conversationId: String,
        onUpdate: @escaping @Sendable ([ChatMessage]) -> Void
    ) async throws -> ChatMessageObservation {
        try await chatRepository.observeMessages(conversationId: conversationId, onUpdate: onUpdate)
    }

    func observeRoom(
        conversationId: String,
        onUpdate: @escaping @Sendable (ChatRoom) -> Void
    ) async throws -> ChatMessageObservation {
        try await chatRepository.observeRoom(conversationId: conversationId, onUpdate: onUpdate)
    }

    func markAsRead(conversationId: String) async throws {
        try await chatRepository.markConversationAsRead(conversationId: conversationId)
    }

    func sendMessage(conversationId: String, text: String) async throws -> ChatMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ChatRepositoryError.emptyMessage
        }
        return try await chatRepository.sendMessage(conversationId: conversationId, text: trimmed)
    }
}
