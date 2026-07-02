//
//  ProfileRegistrationCompleteView.swift
//  matiapu
//

import SwiftUI

struct ProfileRegistrationCompleteView: View {
    let onContinue: () -> Void

    var body: some View {
        AuthScreenLayout {
            VStack(spacing: AppSpacing.authSectionSpacing) {
                RegistrationStepIndicator(currentStep: 3)

                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(AppColors.authPrimaryAction)

                    Text("プロフィール登録が完了しました")
                        .font(AppTypography.authTitle)
                        .foregroundStyle(AppColors.authHeading)
                        .multilineTextAlignment(.center)

                    Text("マチアプへようこそ。さっそく地域の投稿を見てみましょう。")
                        .font(AppTypography.authBody)
                        .foregroundStyle(AppColors.authSubtitle)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.authHorizontal)

                Spacer()

                ProfileNextButton(title: "はじめる", action: onContinue)
                    .padding(.horizontal, AppSpacing.authHorizontal)
                    .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    ProfileRegistrationCompleteView(onContinue: {})
}
