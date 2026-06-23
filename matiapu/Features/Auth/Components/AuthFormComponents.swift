//
//  AuthFormComponents.swift
//  matiapu
//

import SwiftUI

struct AuthCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.authCardPaddingLogin
    var contentGap: CGFloat = AppSpacing.authCardContentGap
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: contentGap) {
            content()
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.authCard, style: .continuous)
                .fill(AppColors.authCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.authCard, style: .continuous)
                .stroke(AppColors.authCardBorder, lineWidth: 1)
        )
    }
}

struct AuthCardHeader: View {
    let title: String
    let subtitle: String
    var titleFont: Font = AppTypography.authTitle

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(titleFont)
                .foregroundStyle(AppColors.authHeading)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(subtitle)
                .font(AppTypography.authSubtitle)
                .foregroundStyle(AppColors.authSubtitle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var prompt: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var trailingAccessory: AnyView?

    init(
        title: String,
        text: Binding<String>,
        prompt: String,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        @ViewBuilder trailingAccessory: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self._text = text
        self.prompt = prompt
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.trailingAccessory = AnyView(trailingAccessory())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(AppTypography.authFieldLabel)
                    .foregroundStyle(AppColors.authLabel)
                    .kerning(0.6)
            }

            HStack(spacing: 12) {
                Group {
                    if isSecure {
                        SecureField("", text: $text, prompt: fieldPrompt)
                    } else {
                        TextField("", text: $text, prompt: fieldPrompt)
                    }
                }
                .font(AppTypography.authField)
                .foregroundStyle(AppColors.authHeading)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                trailingAccessory
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.authInputBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppColors.authInputBorder, lineWidth: 1)
            )
        }
    }

    private var fieldPrompt: Text {
        Text(prompt).foregroundStyle(AppColors.authPlaceholder)
    }
}

struct AuthPrimaryButton: View {
    enum Style {
        case login
        case signUp
        case verification
    }

    let title: String
    var style: Style = .login
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(AppTypography.authPrimaryButton)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonBackground)
            .shadow(
                color: style == .signUp ? .black.opacity(0.05) : .clear,
                radius: 1,
                y: 1
            )
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .verification:
            RoundedRectangle(cornerRadius: AppRadius.authVerificationButton, style: .continuous)
                .fill(backgroundColor)
        case .login, .signUp:
            Capsule(style: .continuous)
                .fill(backgroundColor)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .login, .verification:
            AppColors.authPrimaryAction
        case .signUp:
            AppColors.authPrimary
        }
    }
}

struct AuthDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(AppColors.authDivider)
                .frame(height: 1)
            Text("または")
                .font(AppTypography.authDividerLabel)
                .kerning(0.5)
                .foregroundStyle(AppColors.authFooterText)
            Rectangle()
                .fill(AppColors.authDivider)
                .frame(height: 1)
        }
    }
}

struct AuthSocialButton: View {
    enum Style {
        case google
        case apple
    }

    let style: Style
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                Text(title)
                    .font(AppTypography.authSocialButton)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: style == .google ? 1 : 0)
            )
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch style {
        case .google:
            Text("G")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .yellow, .green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .apple:
            Image(systemName: "apple.logo")
                .font(.system(size: 18, weight: .semibold))
        }
    }

    private var backgroundColor: Color {
        style == .apple ? .black : .white
    }

    private var foregroundColor: Color {
        style == .apple ? .white : AppColors.authHeading
    }

    private var borderColor: Color {
        style == .google ? AppColors.authSocialBorder : .clear
    }
}

struct AuthInlineLink: View {
    let prefix: String
    let linkTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.authDivider)
                .frame(height: 1)
                .padding(.bottom, AppSpacing.authInlineLinkTop)

            HStack(spacing: 4) {
                Text(prefix)
                    .foregroundStyle(AppColors.authSubtitle)
                Button(action: action) {
                    Text(linkTitle)
                        .foregroundStyle(AppColors.authPrimaryAction)
                }
            }
            .font(AppTypography.authLink)
            .frame(maxWidth: .infinity)
        }
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(AppTypography.authFooter)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
