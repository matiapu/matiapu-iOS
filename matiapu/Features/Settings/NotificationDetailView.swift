//
//  NotificationDetailView.swift
//  matiapu
//

import SwiftUI

struct NotificationDetailView: View {
    let notificationId: String
    @Bindable var viewModel: NotificationsViewModel

    private var notification: AppNotification? {
        viewModel.notification(id: notificationId)
    }

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                if let notification {
                    VStack(spacing: AppSpacing.settingsSectionSpacing) {
                        detailCard(notification)
                    }
                    .padding(.horizontal, AppSpacing.settingsHorizontal)
                    .padding(.top, AppSpacing.settingsContentTop)
                    .padding(.bottom, AppSpacing.settingsTabBarInset)
                } else {
                    ContentUnavailableView(
                        "お知らせが見つかりません",
                        systemImage: "bell.slash"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                }
            }
            .scrollIndicators(.hidden)
        }
        .task(id: notificationId) {
            guard let notification else { return }
            await viewModel.markAsRead(notification)
        }
    }

    private func detailCard(_ notification: AppNotification) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppSpacing.settingsSectionSpacing) {
                Text(notification.title)
                    .font(AppTypography.settingsHeaderTitle)
                    .foregroundStyle(AppColors.settingsCardText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(notification.publishedAt, format: .dateTime.year().month().day())
                    .font(AppTypography.settingsSortButton)
                    .foregroundStyle(AppColors.settingsChevron)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(notification.body)
                    .font(AppTypography.createPostField)
                    .foregroundStyle(AppColors.settingsCardText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.settingsHeaderCardPadding)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationDetailView(
            notificationId: "preview-1",
            viewModel: .preview
        )
    }
}
