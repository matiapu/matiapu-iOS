//
//  LegislatorProfileRegistrationView.swift
//  matiapu
//

import SwiftUI

struct LegislatorProfileRegistrationView: View {
    @Bindable var viewModel: ProfileRegistrationViewModel
    let onBack: () -> Void

    var body: some View {
        ProfileRegistrationLayout(role: .legislator, currentStep: 2, onBack: onBack) {
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
                title: "政党",
                text: $viewModel.politicalParty,
                prompt: "例：未来創造党",
                isRequired: true,
                maxLength: 50,
                showsCounter: true
            )

            ProfileTextEditor(
                title: "公約・活動方針",
                text: $viewModel.manifesto,
                prompt: "掲げる公約や具体的な活動方針を50文字以上で入力してください。",
                isRequired: true,
                minLength: 50,
                maxLength: 2000
            )

            ProfileAddressFormSection(title: "活動地域", address: $viewModel.address)

            Text("入力された情報はプライバシーポリシーに基づき適切に管理されます。")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.authSubtitle)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            ProfileNextButton(title: "次へ進む", isLoading: viewModel.isProcessing) {
                Task { await viewModel.submit() }
            }
        }
    }
}

#Preview {
    LegislatorProfileRegistrationView(
        viewModel: ProfileRegistrationViewModel(
            completeProfile: CompleteProfileUseCase(authRepository: MockAuthRepository()),
            role: .legislator
        ),
        onBack: {}
    )
}
