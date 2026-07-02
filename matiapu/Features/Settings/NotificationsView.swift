//
//  NotificationsView.swift
//  matiapu
//

import SwiftUI

struct NotificationsView: View {
    @Bindable var viewModel: NotificationsViewModel

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsSectionSpacing) {
                    headerCard
                    notificationList
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.loadNotifications()
        }
    }

    private var headerCard: some View {
        SettingsCard {
            Text("通知")
                .font(AppTypography.settingsHeaderTitle)
                .foregroundStyle(AppColors.settingsCardText)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.settingsHeaderCardPadding)
        }
    }

    @ViewBuilder
    private var notificationList: some View {
        if viewModel.isLoading && viewModel.notifications.isEmpty {
            ProgressView()
                .tint(AppColors.onImageText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.profileGridLoadingVertical)
        } else if viewModel.notifications.isEmpty {
            ContentUnavailableView(
                "通知はありません",
                systemImage: "bell.slash",
                description: Text("お知らせ・メッセージ・マッチの通知がここに表示されます")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.profileGridLoadingVertical)
        } else {
            LazyVStack(spacing: AppSpacing.settingsCardSpacing) {
                ForEach(viewModel.notifications) { notification in
                    NavigationLink(
                        value: SettingsDestination.notificationDetail(notificationId: notification.id)
                    ) {
                        notificationCard(notification)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func notificationCard(_ notification: AppNotification) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
                notificationKindBadge(notification.kind)

                HStack(alignment: .top, spacing: 8) {
                    Text(notification.title)
                        .font(AppTypography.settingsMenuTitle)
                        .foregroundStyle(AppColors.settingsCardText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !notification.isRead {
                        Circle()
                            .fill(AppColors.postTag)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                    }
                }

                Text(notification.body)
                    .font(AppTypography.createPostField)
                    .foregroundStyle(AppColors.settingsChevron)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                HStack {
                    Text(notification.publishedAt, format: .dateTime.year().month().day())
                        .font(AppTypography.settingsSortButton)
                        .foregroundStyle(AppColors.settingsChevron)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.settingsChevron)
                }
            }
            .padding(AppSpacing.settingsProfileCardPadding)
        }
    }

    private func notificationKindBadge(_ kind: AppNotificationKind) -> some View {
        Label(kind.label, systemImage: kind.systemImageName)
            .font(AppTypography.settingsSortButton)
            .foregroundStyle(AppColors.postTag)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.postTag.opacity(0.15))
            )
            .padding(.top, 2)
    }
}

#Preview {
    NavigationStack {
        NotificationsView(viewModel: .preview)
    }
}
