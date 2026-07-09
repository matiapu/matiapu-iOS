//
//  StoreProfileRegistrationView.swift
//  matiapu
//

import SwiftUI

struct StoreProfileRegistrationView: View {
    @Bindable var viewModel: ProfileRegistrationViewModel
    let onBack: () -> Void

    var body: some View {
        ProfileRegistrationLayout(role: .store, currentStep: 2, onBack: onBack) {
            ProfileImagePickerSection(selectedImage: $viewModel.profileImage)

            ProfileTextField(
                title: "店舗名",
                text: $viewModel.storeName,
                prompt: "例：カフェ・マチアプ 渋谷店",
                isRequired: true,
                maxLength: 50,
                showsCounter: true
            )

            ProfileTextEditor(
                title: "店舗紹介",
                text: $viewModel.storeDescription,
                prompt: "お店のこだわりや特徴、提供している体験について50文字以上で詳しく記入してください。",
                isRequired: true,
                minLength: 50,
                maxLength: 2000
            )

            ProfileTextField(
                title: "店舗電話番号",
                text: $viewModel.phoneNumber,
                prompt: "例：0312345678",
                isRequired: true,
                keyboardType: .numberPad,
                helperText: "半角数字・ハイフンなし（15桁以内）"
            )

            ProfileAddressFormSection(title: "所在地", address: $viewModel.address)

            ProfileTextField(
                title: "ログインID（メールアドレス）",
                text: .constant(viewModel.email),
                prompt: viewModel.email,
                isReadOnly: true,
                showsLock: true,
                helperText: "登録後はIDを変更できません。"
            )

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
    StoreProfileRegistrationView(
        viewModel: ProfileRegistrationViewModel(
            completeProfile: CompleteProfileUseCase(authRepository: MockAuthRepository()),
            role: .store
        ),
        onBack: {}
    )
}
