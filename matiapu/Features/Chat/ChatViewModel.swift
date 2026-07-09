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
    private(set) var messagesByConversationID: [String: [ChatMessage]] = [:]
    private(set) var isLoadingConversations = false
    private(set) var isLoadingMessages = false
    var conversationToOpen: ChatConversation?
    var errorMessage: String?

    private let fetchConversations: FetchConversationsUseCase
    private let chatRoom: ChatRoomUseCase
    private var messagesObservation: ChatMessageObservation?

    var onConversationVisibilityChanged: ((String?) -> Void)?

    init(useCases: AppUseCases) {
        self.fetchConversations = useCases.fetchConversations
        self.chatRoom = useCases.chatRoom
    }

    func messages(for conversationID: String) -> [ChatMessage] {
        messagesByConversationID[conversationID] ?? []
    }

    func isLoadingMessages(for conversationID: String) -> Bool {
        isLoadingMessages && messages(for: conversationID).isEmpty
    }

    func loadConversations() async {
        isLoadingConversations = true
        errorMessage = nil
        defer { isLoadingConversations = false }

        do {
            conversations = try await fetchConversations.execute()
        } catch let error as FirebaseRepositoryError where error == .notAuthenticated {
            conversations = []
            errorMessage = error.localizedDescription
        } catch {
            conversations = []
            errorMessage = "チャット一覧の読み込みに失敗しました。"
        }
    }

    func startObservingMessages(for conversationID: String) async {
        stopObservingMessages()
        onConversationVisibilityChanged?(conversationID)

        guard ChatCrypto.isSaltConfigured else {
            messagesByConversationID[conversationID] = []
            errorMessage = "チャット暗号化の設定（CHAT_SALT）が未設定です。Secrets.xcconfig に Web アプリと同じ値を設定してください。"
            return
        }

        isLoadingMessages = true
        errorMessage = nil

        do {
            messagesObservation = try await chatRoom.observeMessages(conversationId: conversationID) { messages in
                Task { @MainActor [weak self] in
                    self?.applyMessages(messages, conversationID: conversationID)
                }
            }
        } catch {
            messagesByConversationID[conversationID] = []
            isLoadingMessages = false
            errorMessage = "メッセージの読み込みに失敗しました。"
        }
    }

    func stopObservingMessages() {
        messagesObservation?.stop()
        messagesObservation = nil
        onConversationVisibilityChanged?(nil)
    }

    func loadMessages(for conversationID: String) async {
        await startObservingMessages(for: conversationID)
    }

    private func applyMessages(_ messages: [ChatMessage], conversationID: String) {
        messagesByConversationID[conversationID] = messages
        isLoadingMessages = false

        if let lastMessage = messages.last,
           !ChatCrypto.isUndecryptableDisplayText(lastMessage.text) {
            upsertConversationPreview(
                conversationId: conversationID,
                lastMessage: lastMessage.text,
                updatedAt: lastMessage.sentAt
            )
        }

        let undecryptableCount = messages.filter { ChatCrypto.isUndecryptableDisplayText($0.text) }.count
        if undecryptableCount > 0 {
            if undecryptableCount == messages.count {
                errorMessage = "メッセージを復号できませんでした。Secrets.xcconfig の CHAT_SALT が Web アプリの NEXT_PUBLIC_CHAT_SALT と一致しているか確認してください。"
            } else {
                errorMessage = "一部のメッセージを復号できませんでした。アプリ更新前に送信されたメッセージは表示できない場合があります。"
            }
        } else {
            errorMessage = nil
        }
    }

    func sendMessage(conversationId: String, text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let message = try await chatRoom.sendMessage(conversationId: conversationId, text: trimmed)
            upsertConversationPreview(
                conversationId: conversationId,
                lastMessage: trimmed,
                updatedAt: message.sentAt
            )
            await loadConversations()
        } catch {
            errorMessage = "メッセージの送信に失敗しました。"
        }
    }

    func handleMatch(_ conversation: ChatConversation) async {
        upsertConversation(conversation)
        conversationToOpen = conversation
        await loadConversations()
    }

    func clearOpenedConversation() {
        conversationToOpen = nil
    }

    private func upsertConversation(_ conversation: ChatConversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        conversations.sort { $0.updatedAt > $1.updatedAt }
    }

    private func upsertConversationPreview(
        conversationId: String,
        lastMessage: String,
        updatedAt: Date
    ) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        let current = conversations[index]
        conversations[index] = ChatConversation(
            id: current.id,
            partnerId: current.partnerId,
            partnerName: current.partnerName,
            partnerProfileImageURL: current.partnerProfileImageURL,
            lastMessage: lastMessage,
            updatedAt: updatedAt,
            unreadCount: current.unreadCount
        )
        conversations.sort { $0.updatedAt > $1.updatedAt }
    }
}

#if DEBUG
extension ChatViewModel {
    static var preview: ChatViewModel {
        let viewModel = ChatViewModel(useCases: AppUseCases.make(from: .live))
        viewModel.conversations = [
            ChatConversation(
                id: "chat-1",
                partnerId: "leg-2",
                partnerName: "田中 太郎",
                partnerProfileImageURL: nil,
                lastMessage: "マッチしました！メッセージを送ってみましょう。",
                updatedAt: .now,
                unreadCount: 1
            ),
        ]
        return viewModel
    }

    static var roomPreview: ChatViewModel {
        let viewModel = ChatViewModel(useCases: AppUseCases.make(from: .live))
        let conversationID = "chat-1"
        viewModel.conversations = [
            ChatConversation(
                id: conversationID,
                partnerId: "leg-2",
                partnerName: "ブリティッシュブルー",
                partnerProfileImageURL: nil,
                lastMessage: "こんばんにゃー",
                updatedAt: .now,
                unreadCount: 0
            ),
        ]
        viewModel.messagesByConversationID[conversationID] = [
            ChatMessage(
                id: "1",
                conversationId: conversationID,
                text: "こんばんにゃー🐈‍⬛",
                isFromCurrentUser: false,
                sentAt: Calendar.current.date(bySettingHour: 11, minute: 48, second: 0, of: .now) ?? .now
            ),
            ChatMessage(
                id: "2",
                conversationId: conversationID,
                text: "こんにちわん🐕",
                isFromCurrentUser: true,
                sentAt: Calendar.current.date(bySettingHour: 13, minute: 6, second: 0, of: .now) ?? .now
            ),
        ]
        return viewModel
    }
}
#endif
