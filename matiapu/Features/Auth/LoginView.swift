//
//  LoginView.swift
//  matiapu
//

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    var onSignUp: () -> Void
    var onForgotPassword: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    var body: some View {
        AuthScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.authSectionSpacing) {
                    AuthCard {
                        AuthCardHeader(
                            title: "ログイン",
                            subtitle: "アカウント情報を入力してください"
                        )

                        AuthTextField(
                            title: "メールアドレス",
                            text: $email,
                            prompt: "example@secureauth.com",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("パスワード")
                                    .font(AppTypography.authFieldLabel)
                                    .foregroundStyle(AppColors.authLabel)
                                    .kerning(0.6)
                                Spacer()
                                Button("パスワードをお忘れの方", action: onForgotPassword)
                                    .font(AppTypography.authLink)
                                    .foregroundStyle(AppColors.authPrimaryAction)
                            }

                            AuthTextField(
                                title: "",
                                text: $password,
                                prompt: "••••••••",
                                isSecure: !isPasswordVisible,
                                textContentType: .password
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
                            title: "ログイン",
                            style: .login,
                            isLoading: viewModel.isProcessing
                        ) {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                            }
                        }
                        .padding(.top, 8)

                        AuthDivider()

                        VStack(spacing: AppSpacing.authSocialSpacing) {
                            AuthSocialButton(style: .google, title: "Googleでログイン") {
                                Task { await viewModel.signInWithGoogle() }
                            }

                            AppleSignInButton(viewModel: viewModel)
                        }

                        AuthInlineLink(
                            prefix: "アカウントをお持ちでないですか？",
                            linkTitle: "新規登録はこちら",
                            action: onSignUp
                        )
                    }

                    AuthFooterLinks()
                }
                .padding(.horizontal, AppSpacing.authHorizontal)
                .padding(.top, AppSpacing.authLoginContentTop)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    LoginView(viewModel: .preview, onSignUp: {}, onForgotPassword: {})
}
