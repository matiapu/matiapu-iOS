//
//  ChatRoomView.swift
//  matiapu
//

import SwiftUI

struct ChatRoomView: View {
    let conversation: ChatConversation
    @Bindable var viewModel: ChatViewModel
    @State private var draftMessage = ""

    var body: some View {
        ChatScreenLayout {
            VStack(spacing: 0) {
                messageList
                ChatInputBar(text: $draftMessage) {
                    sendDraftMessage()
                }
            }
        }
        .navigationTitle(conversation.partnerName)
        .task(id: conversation.id) {
            await viewModel.loadMessages(for: conversation.id)
        }
        .onDisappear {
            viewModel.clearOpenedConversation()
        }
    }

    private var messageList: some View {
        let messages = viewModel.messages(for: conversation.id)
        let sections = ChatMessageGrouper.sections(from: messages)

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if viewModel.isLoadingMessages(for: conversation.id) {
                        ProgressView()
                            .tint(AppColors.onImageText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                    } else if messages.isEmpty {
                        ContentUnavailableView(
                            "メッセージはありません",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("最初のメッセージを送ってみましょう")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                    } else {
                        ForEach(sections) { section in
                            ChatDateSeparator(label: section.dateLabel)

                            ForEach(section.messages) { message in
                                messageRow(message)
                                    .id(message.id)
                            }
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.createPostField)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .onChange(of: messages.count) {
                guard let lastMessage = messages.last else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        if message.isFromCurrentUser {
            ChatOutgoingMessageRow(message: message)
        } else {
            ChatIncomingMessageRow(message: message)
        }
    }

    private func sendDraftMessage() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let message = draftMessage
        draftMessage = ""
        Task {
            await viewModel.sendMessage(conversationId: conversation.id, text: message)
        }
    }
}

#Preview {
    NavigationStack {
        ChatRoomView(
            conversation: ChatConversation(
                id: "chat-1",
                partnerId: "leg-2",
                partnerName: "ブリティッシュブルー",
                lastMessage: "こんばんにゃー",
                updatedAt: .now,
                unreadCount: 0
            ),
            viewModel: .roomPreview
        )
    }
}
