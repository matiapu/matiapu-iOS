//
//  AccountSettingsView.swift
//  matiapu
//

import SwiftUI

struct AccountSettingsView: View {
    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsCardSpacing) {
                    NavigationLink(value: SettingsDestination.profileImageEdit) {
                        SettingsMenuRow(title: "ユーザーアイコン変更")
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.usernameEdit) {
                        SettingsMenuRow(title: "ユーザー名変更")
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.emailPasswordEdit) {
                        SettingsMenuRow(title: "メールアドレス・パスワード変更")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
}
