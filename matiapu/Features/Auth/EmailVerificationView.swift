//
//  EmailVerificationView.swift
//  matiapu
//

import SwiftUI

struct EmailVerificationView: View {
    @Bindable var viewModel: AuthViewModel
    let displayName: String

    @Environment(\.scenePhase) private var scenePhase
    @State private var didSendSuccess = false

    var body: some View {
        AuthScreenLayout(showsTopBar: false) {
            ScrollView {
                VStack(spacing: AppSpacing.authSectionSpacing) {
                    AuthLogoHeader()

                    AuthCard(
                        padding: AppSpacing.authCardPaddingSignUp,
                        contentGap: AppSpacing.authSignUpCardContentGap
                    ) {
                        VStack(spacing: 12) {
                            Text("こんにちは、\(displayName)さん")
                                .font(AppTypography.authGreeting)
                                .foregroundStyle(AppColors.authHeading)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)

                            Text("登録したメールアドレスに届いた認証メールのリンクをタップしてください。リンクはブラウザで開きます。認証後、この画面に戻って「認証状態を確認する」を押してください。届かない場合は迷惑メールフォルダもご確認ください。")
                                .font(AppTypography.authBody)
                                .foregroundStyle(AppColors.authSubtitle)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        AuthPrimaryButton(
                            title: "認証状態を確認する",
                            style: .verification,
                            isLoading: viewModel.isProcessing
                        ) {
                            Task {
                                let verified = await viewModel.verifyEmail()
                                if !verified, viewModel.errorMessage == nil {
                                    viewModel.errorMessage = "まだメール認証が完了していません。メール内のリンクを開いてから再度お試しください。"
                                }
                            }
                        }

                        VStack(spacing: 16) {
                            Text("リンクを開いたあと、下のボタンで認証状態を確認できます。")
                                .font(AppTypography.authBody)
                                .foregroundStyle(AppColors.authPrimary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)

                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                Text("有効期限: 10分間")
                                    .font(AppTypography.authSubtitle)
                            }
                            .foregroundStyle(AppColors.authSubtitle)
                        }

                        Button("認証メールを再送信") {
                            Task {
                                didSendSuccess = await viewModel.resendVerificationEmail()
                            }
                        }
                        .font(AppTypography.authLink)
                        .foregroundStyle(AppColors.authPrimaryAction)

                        if didSendSuccess {
                            Text("認証メールを再送信しました。")
                                .font(AppTypography.authFooter)
                                .foregroundStyle(AppColors.authPrimaryAction)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            AuthErrorBanner(message: errorMessage)
                        }

                        Button("別のアカウントでログイン") {
                            Task { await viewModel.signOut() }
                        }
                        .font(AppTypography.authLink)
                        .foregroundStyle(AppColors.authSubtitle)
                    }

                    VStack(spacing: AppSpacing.authSectionSpacing) {
                        Rectangle()
                            .fill(AppColors.authSocialBorder)
                            .frame(height: 1)

                        Text("心当たりがない場合は、このメールを破棄してください。第三者に認証リンクを教えないようご注意ください。")
                            .font(AppTypography.authFooter)
                            .foregroundStyle(AppColors.authSubtitle)
                            .opacity(0.7)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, AppSpacing.authHorizontal)

                    AuthFooterLinks()
                }
                .padding(.horizontal, AppSpacing.authHorizontal)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { _ = await viewModel.verifyEmail() }
        }
    }
}
