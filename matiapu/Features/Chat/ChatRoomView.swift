//
//  ChatRoomView.swift
//  matiapu
//

import SwiftUI

struct ChatRoomView: View {
    let conversation: ChatConversation
    @Bindable var viewModel: ChatViewModel

    var body: some View {
        ChatScreenLayout {
            VStack(spacing: 0) {
                messageList
                messageInputBar
            }
        }
        .navigationTitle(conversation.partnerName)
        .task(id: conversation.id) {
            await viewModel.loadMessages(for: conversation.id)
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.settingsCardSpacing) {
                    if viewModel.isLoadingMessages && viewModel.messages.isEmpty {
                        ProgressView()
                            .tint(AppColors.onImageText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                    } else {
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsSectionSpacing)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.count) {
                guard let lastMessage = viewModel.messages.last else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(AppTypography.createPostField)
                    .foregroundStyle(
                        message.isFromCurrentUser ? AppColors.onTagText : AppColors.settingsCardText
                    )
                    .multilineTextAlignment(message.isFromCurrentUser ? .trailing : .leading)
                    .padding(.horizontal, AppSpacing.settingsHorizontal)
                    .padding(.vertical, AppSpacing.settingsSortButtonVertical)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.settingsCard, style: .continuous)
                            .fill(
                                message.isFromCurrentUser
                                    ? AppColors.postTag
                                    : AppColors.settingsCardBackground
                            )
                    )

                Text(message.sentAt, format: .dateTime.hour().minute())
                    .font(AppTypography.settingsSortButton)
                    .foregroundStyle(AppColors.onImageText.opacity(0.8))
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 48)
            }
        }
    }

    private var messageInputBar: some View {
        HStack(spacing: AppSpacing.settingsProfileCardSpacing) {
            TextField("", text: $viewModel.draftMessage, prompt: inputPrompt)
                .font(AppTypography.settingsEditField)
                .foregroundStyle(AppColors.settingsCardText)
                .padding(.horizontal, AppSpacing.createPostFieldHorizontal)
                .frame(height: AppSize.createPostTitleFieldHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.settingsCardBackground)
                )

            Button {
                Task { await viewModel.sendMessage(conversationId: conversation.id) }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(AppTypography.fabIcon)
                    .foregroundStyle(AppColors.onTagText)
                    .frame(width: AppSize.fab, height: AppSize.fab)
                    .background(
                        Circle()
                            .fill(AppColors.postTag)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, AppSpacing.settingsHorizontal)
        .padding(.vertical, AppSpacing.settingsContentTop)
        .padding(.bottom, AppSpacing.screenTop)
    }

    private var inputPrompt: Text {
        Text("メッセージを入力")
            .font(AppTypography.settingsEditField)
            .foregroundStyle(AppColors.settingsSearchPlaceholder)
    }
}

#Preview {
    NavigationStack {
        ChatRoomView(
            conversation: ChatConversation(
                id: "chat-1",
                partnerId: "leg-2",
                partnerName: "田中 太郎",
                lastMessage: "マッチしました！",
                updatedAt: .now,
                unreadCount: 0
            ),
            viewModel: .preview
        )
    }
}
