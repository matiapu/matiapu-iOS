//
//  ChatView.swift
//  matiapu
//

import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChatScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsCardSpacing) {
                    if viewModel.isLoadingConversations && viewModel.conversations.isEmpty {
                        ProgressView()
                            .tint(AppColors.onImageText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                    } else if viewModel.conversations.isEmpty {
                        ContentUnavailableView(
                            "チャットはありません",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("マッチした相手とチャットを始めましょう")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                    } else {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink {
                                ChatRoomView(
                                    conversation: conversation,
                                    viewModel: viewModel
                                )
                            } label: {
                                conversationRow(conversation)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.createPostField)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("チャット")
        .navigationDestination(item: $viewModel.conversationToOpen) { conversation in
            ChatRoomView(
                conversation: conversation,
                viewModel: viewModel
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.onImageText)
                }
            }
        }
        .task {
            await viewModel.loadConversations()
        }
    }

    private func conversationRow(_ conversation: ChatConversation) -> some View {
        SettingsCard {
            HStack(spacing: AppSpacing.settingsProfileCardSpacing) {
                ProfileAvatarView(
                    imageURL: conversation.partnerProfileImageURL,
                    size: AppSize.settingsProfileCardAvatar
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.partnerName)
                        .font(AppTypography.settingsMenuTitle)
                        .foregroundStyle(AppColors.settingsCardText)
                        .lineLimit(1)

                    Text(conversation.lastMessage)
                        .font(AppTypography.createPostField)
                        .foregroundStyle(AppColors.settingsChevron)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(conversation.updatedAt, format: .dateTime.month().day())
                        .font(AppTypography.settingsSortButton)
                        .foregroundStyle(AppColors.settingsChevron)

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(AppTypography.settingsSortButton)
                            .foregroundStyle(AppColors.onTagText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AppColors.postTag)
                            )
                    }
                }
            }
            .padding(AppSpacing.settingsProfileCardPadding)
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(viewModel: .preview)
    }
}
