//
//  SettingsView.swift
//  matiapu
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsCardSpacing) {
                    NavigationLink(value: SettingsDestination.accountSettings) {
                        profileCard
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.regionSelection) {
                        SettingsMenuRow(
                            title: viewModel.profile?.registeredArea ?? "地域名",
                            showsChevron: false
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.likedPosts) {
                        SettingsMenuRow(title: "いいねした投稿", showsChevron: false)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.notifications) {
                        notificationsRow
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.qaList) {
                        SettingsMenuRow(title: "よくある質問", showsChevron: false)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.signOutConfirmation) {
                        SettingsMenuRow(title: "ログアウト", showsChevron: false)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.deleteAccountConfirmation) {
                        SettingsMenuRow(
                            title: "アカウント削除",
                            showsChevron: false,
                            titleColor: .red
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    private var profileCard: some View {
        SettingsCard {
            HStack(spacing: AppSpacing.settingsProfileCardSpacing) {
                ProfileAvatarView(
                    imageURL: viewModel.profile?.profileImageURL,
                    size: AppSize.settingsProfileCardAvatar,
                    userID: viewModel.profile?.id
                )

                Text(viewModel.profile?.displayName ?? "ユーザー名ユーザー名")
                    .font(AppTypography.settingsCardTitle)
                    .foregroundStyle(AppColors.settingsCardText)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.settingsProfileCardPadding)
            .frame(minHeight: AppSize.settingsMenuRowMinHeight)
        }
    }

    private var notificationsRow: some View {
        SettingsCard {
            ZStack(alignment: .bottomTrailing) {
                Text("通知")
                    .font(AppTypography.settingsMenuTitle)
                    .foregroundStyle(AppColors.settingsCardText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if viewModel.unreadNotificationCount > 0 {
                    Text("\(viewModel.unreadNotificationCount)")
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
            .padding(.horizontal, AppSpacing.settingsHorizontal)
            .padding(.vertical, AppSpacing.settingsMenuRowVertical)
            .frame(minHeight: AppSize.settingsMenuRowMinHeight)
        }
    }
}
