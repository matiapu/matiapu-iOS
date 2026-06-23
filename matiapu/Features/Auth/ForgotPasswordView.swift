//
//  ForgotPasswordView.swift
//  matiapu
//

import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var viewModel: AuthViewModel
    var onBack: () -> Void

    @State private var email = ""
    @State private var didSend = false

    var body: some View {
        AuthScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.authSectionSpacing) {
                    AuthCard {
                        AuthCardHeader(
                            title: "パスワード再設定",
                            subtitle: "登録済みのメールアドレスを入力してください。再設定用のリンクを送信します。"
                        )

                        AuthTextField(
                            title: "メールアドレス",
                            text: $email,
                            prompt: "example@mail.com",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        if let errorMessage = viewModel.errorMessage {
                            AuthErrorBanner(message: errorMessage)
                        }

                        if didSend {
                            Text("パスワード再設定メールを送信しました。")
                                .font(AppTypography.authFooter)
                                .foregroundStyle(AppColors.authPrimaryAction)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        AuthPrimaryButton(
                            title: "送信する",
                            style: .login,
                            isLoading: viewModel.isProcessing
                        ) {
                            Task {
                                didSend = await viewModel.sendPasswordReset(email: email)
                            }
                        }
                        .padding(.top, 8)

                        Button("ログインに戻る", action: onBack)
                            .font(AppTypography.authLink)
                            .foregroundStyle(AppColors.authPrimaryAction)
                            .frame(maxWidth: .infinity)
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
    ForgotPasswordView(viewModel: .preview, onBack: {})
}
