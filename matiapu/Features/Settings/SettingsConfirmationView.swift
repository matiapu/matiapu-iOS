//
//  SettingsConfirmationView.swift
//  matiapu
//

import SwiftUI

struct SettingsConfirmationView: View {
    let title: String
    let message: String
    let confirmTitle: String
    let isDestructive: Bool
    var isProcessing = false
    var errorMessage: String?
    let onConfirm: () async -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsSectionSpacing) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
                            Text(title)
                                .font(AppTypography.settingsHeaderTitle)
                                .foregroundStyle(AppColors.settingsCardText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(message)
                                .font(AppTypography.cardBody)
                                .foregroundStyle(AppColors.settingsCardText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppSpacing.settingsHeaderCardPadding)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.createPostField)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    confirmButton
                    cancelButton
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var confirmButton: some View {
        Button {
            Task { await onConfirm() }
        } label: {
            ZStack {
                if isProcessing {
                    ProgressView()
                        .tint(isDestructive ? .white : AppColors.onTagText)
                } else {
                    Text(confirmTitle)
                        .font(AppTypography.createPostSubmit)
                }
            }
            .foregroundStyle(isDestructive ? Color.white : AppColors.onTagText)
            .frame(maxWidth: .infinity)
            .frame(height: AppSize.createPostSubmitHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(isDestructive ? Color.red : AppColors.postTag)
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.7 : 1)
    }

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("キャンセル")
                .font(AppTypography.createPostSubmit)
                .foregroundStyle(AppColors.settingsCardText)
                .frame(maxWidth: .infinity)
                .frame(height: AppSize.createPostSubmitHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.settingsCardBackground)
                )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }
}

#Preview("Sign Out") {
    NavigationStack {
        SettingsConfirmationView(
            title: "ログアウト",
            message: "ログアウトしますか？",
            confirmTitle: "ログアウトする",
            isDestructive: false,
            onConfirm: {}
        )
    }
}

#Preview("Delete Account") {
    NavigationStack {
        SettingsConfirmationView(
            title: "アカウント削除",
            message: "アカウントを削除すると、プロフィールや投稿データは復元できません。本当に削除しますか？",
            confirmTitle: "アカウントを削除する",
            isDestructive: true,
            onConfirm: {}
        )
    }
}
