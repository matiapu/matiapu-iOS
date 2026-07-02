//
//  AccountTypeSelectionView.swift
//  matiapu
//

import SwiftUI

struct AccountTypeSelectionView: View {
    @Bindable var viewModel: ProfileRegistrationViewModel
    let onSelected: () -> Void

    var body: some View {
        ProfileRegistrationLayout(role: viewModel.role, currentStep: 2) {
            VStack(spacing: 12) {
                Text("アカウント種別を選択してください")
                    .font(AppTypography.authBody)
                    .foregroundStyle(AppColors.authSubtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(UserRole.allCases) { role in
                    Button {
                        Task {
                            await viewModel.updateRole(role)
                            onSelected()
                        }
                    } label: {
                        HStack {
                            Text(role.title)
                                .font(AppTypography.authField)
                                .foregroundStyle(AppColors.authHeading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(AppColors.authIconMuted)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
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
            }
        }
    }
}
