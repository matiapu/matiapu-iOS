//
//  AuthScreenLayout.swift
//  matiapu
//

import SwiftUI

struct AuthScreenLayout<Content: View>: View {
    let showsTopBar: Bool
    @ViewBuilder let content: () -> Content

    init(showsTopBar: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.showsTopBar = showsTopBar
        self.content = content
    }

    var body: some View {
        ZStack {
            AppColors.authBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if showsTopBar {
                    AuthTopBar()
                }
                content()
            }
        }
    }
}

struct AuthTopBar: View {
    var body: some View {
        HStack {
            AppBrandMark()

            Spacer()

            Button(action: {}) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.authSubtitle)
            }
            .accessibilityLabel("ヘルプ")
        }
        .padding(.horizontal, AppSpacing.authHorizontal)
        .frame(height: 64)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.authCardBorder)
                .frame(height: 1)
        }
    }
}

struct AuthLogoHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            AppLogoView(size: AppSize.authLogoSize, showsGlow: false)

            Text("マチアプ")
                .font(AppTypography.authBrandTagline)
                .kerning(2.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.authBrand)
        }
        .padding(.top, AppSpacing.authSignUpHeaderTop)
        .padding(.bottom, 8)
    }
}

struct AuthFooterLinks: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 24) {
                footerLink("サポート")
                footerLink("プライバシーポリシー")
                footerLink("利用規約")
            }

            Text("© 2024 matiapu")
                .font(AppTypography.authFooter)
                .kerning(1)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.authFooterText)
        }
        .padding(.top, AppSpacing.authFooterTop)
        .padding(.bottom, 24)
    }

    private func footerLink(_ title: String) -> some View {
        Button(action: {}) {
            Text(title)
                .font(AppTypography.authFooter)
                .foregroundStyle(AppColors.authFooterText)
        }
    }
}

#Preview {
    AuthScreenLayout {
        VStack {
            AuthLogoHeader()
            Spacer()
            AuthFooterLinks()
        }
    }
}
