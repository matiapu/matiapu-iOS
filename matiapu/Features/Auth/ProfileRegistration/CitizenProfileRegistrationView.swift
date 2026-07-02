//
//  CitizenProfileRegistrationView.swift
//  matiapu
//

import SwiftUI

struct CitizenProfileRegistrationView: View {
    @Bindable var viewModel: ProfileRegistrationViewModel

    private let years = (1940...2010).map(String.init)
    private let months = (1...12).map(String.init)
    private let days = (1...31).map(String.init)

    var body: some View {
        ProfileRegistrationLayout(role: .citizen, currentStep: 2) {
            ProfileImagePickerSection(selectedImage: $viewModel.profileImage)

            HStack(spacing: 12) {
                ProfileTextField(title: "姓", text: $viewModel.lastName, prompt: "山田", isRequired: true)
                ProfileTextField(title: "名", text: $viewModel.firstName, prompt: "太郎", isRequired: true)
            }

            HStack(spacing: 12) {
                ProfileTextField(title: "セイ", text: $viewModel.lastNameKana, prompt: "ヤマダ", isRequired: true)
                ProfileTextField(title: "メイ", text: $viewModel.firstNameKana, prompt: "タロウ", isRequired: true)
            }

            ProfileTextField(
                title: "メールアドレス",
                text: .constant(viewModel.email),
                prompt: viewModel.email,
                isReadOnly: true,
                showsLock: true,
                helperText: "メールアドレスは変更できません。"
            )

            ProfileTextField(
                title: "ニックネーム",
                text: $viewModel.nickname,
                prompt: "表示名",
                isRequired: true,
                helperText: "公開される名前です。後で変更可能です。"
            )

            birthDateSection

            ProfileAddressFormSection(title: "現住所", address: $viewModel.address)

            ProfilePrivacyNotice(
                text: "住所情報は本人確認およびマッチング精度向上のためにのみ使用され、他のユーザーに公開されることはありません。"
            )

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            ProfileNextButton(title: "次へ進む", isLoading: viewModel.isProcessing) {
                Task { await viewModel.submit() }
            }
        }
    }

    private var birthDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileFieldLabel(title: "生年月日", isRequired: true)

            HStack(spacing: 8) {
                pickerMenu(title: viewModel.birthYear, suffix: "年", options: years) {
                    viewModel.birthYear = $0
                }
                pickerMenu(title: viewModel.birthMonth, suffix: "月", options: months) {
                    viewModel.birthMonth = $0
                }
                pickerMenu(title: viewModel.birthDay, suffix: "日", options: days) {
                    viewModel.birthDay = $0
                }
            }

            Text("※生年月日は後で変更できません。")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.authSubtitle)
        }
    }

    private func pickerMenu(
        title: String,
        suffix: String,
        options: [String],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button("\(option)\(suffix)") { onSelect(option) }
            }
        } label: {
            HStack {
                Text("\(title)\(suffix)")
                    .font(AppTypography.authField)
                    .foregroundStyle(AppColors.authHeading)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
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
}

#Preview {
    CitizenProfileRegistrationView(viewModel: .preview)
}
