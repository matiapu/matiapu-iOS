//
//  SignUpView.swift
//  matiapu
//

import SwiftUI

struct SignUpView: View {
    @Bindable var viewModel: AuthViewModel
    var onLogin: () -> Void

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    var body: some View {
        AuthScreenLayout(showsTopBar: false) {
            ScrollView {
                VStack(spacing: AppSpacing.authSectionSpacing) {
                    AuthLogoHeader()

                    AuthCard(
                        padding: AppSpacing.authCardPaddingSignUp,
                        contentGap: AppSpacing.authSignUpCardContentGap
                    ) {
                        AuthCardHeader(
                            title: "アカウント作成",
                            subtitle: "必要事項を入力して登録を完了してください",
                            titleFont: AppTypography.authSignUpTitle
                        )

                        VStack(spacing: AppSpacing.authFieldSpacing) {
                            AuthTextField(
                                title: "お名前",
                                text: $displayName,
                                prompt: "山田 太郎",
                                textContentType: .name
                            )

                            AuthTextField(
                                title: "メールアドレス",
                                text: $email,
                                prompt: "example@mail.com",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )

                            AuthTextField(
                                title: "パスワード",
                                text: $password,
                                prompt: "8文字以上の英数字",
                                isSecure: !isPasswordVisible,
                                textContentType: .newPassword
                            ) {
                                Button {
                                    isPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundStyle(AppColors.authIconMuted)
                                }
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            AuthErrorBanner(message: errorMessage)
                        }

                        AuthPrimaryButton(
                            title: "登録する",
                            style: .signUp,
                            isLoading: viewModel.isProcessing
                        ) {
                            Task {
                                await viewModel.signUp(
                                    displayName: displayName,
                                    email: email,
                                    password: password
                                )
                            }
                        }

                        AuthDivider()

                        VStack(spacing: AppSpacing.authSocialSpacing) {
                            AuthSocialButton(style: .google, title: "Googleでサインアップ") {
                                Task { await viewModel.signInWithGoogle() }
                            }

                            AppleSignInButton(viewModel: viewModel)
                        }

                        AuthInlineLink(
                            prefix: "すでにアカウントをお持ちですか？",
                            linkTitle: "ログインはこちら",
                            action: onLogin
                        )
                    }

                    AuthFooterLinks()
                }
                .padding(.horizontal, AppSpacing.authHorizontal)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    SignUpView(viewModel: .preview, onLogin: {})
}
