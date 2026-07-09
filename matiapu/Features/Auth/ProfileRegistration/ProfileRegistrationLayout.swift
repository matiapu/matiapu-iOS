//
//  ProfileRegistrationLayout.swift
//  matiapu
//

import SwiftUI

struct ProfileRegistrationLayout<Content: View>: View {
    let role: UserRole
    let currentStep: Int
    var onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        AuthScreenLayout(onBack: onBack) {
            VStack(spacing: 0) {
                RegistrationStepIndicator(currentStep: currentStep)

                ScrollView {
                    VStack(spacing: AppSpacing.authSectionSpacing) {
                        VStack(spacing: 8) {
                            Text(role.profileRegistrationTitle)
                                .font(AppTypography.authTitle)
                                .foregroundStyle(AppColors.authHeading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(role.profileRegistrationSubtitle)
                                .font(AppTypography.authSubtitle)
                                .foregroundStyle(AppColors.authSubtitle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        content()

                        AuthFooterLinks()
                    }
                    .padding(.horizontal, AppSpacing.authHorizontal)
                    .padding(.bottom, 48)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
