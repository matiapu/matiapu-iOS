//
//  ChatViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    private(set) var conversations: [ChatConversation] = []
    private(set) var messages: [ChatMessage] = []
    private(set) var isLoadingConversations = false
    private(set) var isLoadingMessages = false
    var draftMessage = ""

    private let chatRepository: any ChatRepository

    init(chatRepository: any ChatRepository) {
        self.chatRepository = chatRepository
    }

    func loadConversations() async {
        isLoadingConversations = true
        defer { isLoadingConversations = false }
        conversations = (try? await chatRepository.fetchConversations()) ?? []
    }

    func loadMessages(for conversationId: String) async {
        isLoadingMessages = true
        defer { isLoadingMessages = false }
        messages = (try? await chatRepository.fetchMessages(conversationId: conversationId)) ?? []
    }

    func sendMessage(conversationId: String) async {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        draftMessage = ""
        _ = try? await chatRepository.sendMessage(conversationId: conversationId, text: trimmed)
        await loadMessages(for: conversationId)
        await loadConversations()
    }
}

#if DEBUG
extension ChatViewModel {
    static var preview: ChatViewModel {
        let viewModel = ChatViewModel(chatRepository: MockChatRepository())
        viewModel.conversations = [
            ChatConversation(
                id: "chat-1",
                partnerId: "leg-2",
                partnerName: "田中 太郎",
                lastMessage: "マッチしました！メッセージを送ってみましょう。",
                updatedAt: .now,
                unreadCount: 1
            ),
        ]
        return viewModel
    }
}
#endif
