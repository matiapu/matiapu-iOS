//
//  AppLogoView.swift
//  matiapu
//

import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = AppSize.authLogoSize
    var showsGlow = false

    var body: some View {
        ZStack {
            if showsGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.authPrimaryAction.opacity(0.2),
                                AppColors.authPrimaryAction.opacity(0.04),
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.65
                        )
                    )
                    .frame(width: size, height: size)
            }

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        }
        .accessibilityLabel("マチアプ")
    }
}

struct AppBrandMark: View {
    var iconSize: CGFloat = AppSize.authNavLogoSize

    var body: some View {
        HStack(spacing: 8) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous))

            Text("マチアプ")
                .font(AppTypography.authBrandNav)
                .foregroundStyle(AppColors.authBrand)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("マチアプ")
    }
}

#Preview {
    VStack(spacing: 24) {
        AppLogoView()
        AppBrandMark()
    }
    .padding()
    .background(AppColors.authBackground)
}
