//
//  ProfileImageEditView.swift
//  matiapu
//

import SwiftUI
import UIKit

struct ProfileImageEditView: View {
    @Bindable var viewModel: SettingsViewModel
    var onSaved: () -> Void = {}

    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.createPostSectionSpacing) {
                    ProfileImagePickerSection(
                        selectedImage: $selectedImage,
                        currentImageURL: viewModel.profile?.profileImageURL,
                        currentUserID: viewModel.profile?.id,
                        title: "ユーザーアイコン",
                        subtitle: "チャットやプロフィールに表示されます"
                    )
                    .padding(.top, AppSpacing.settingsContentTop)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.createPostField)
                            .foregroundStyle(.red)
                    }

                    saveButton
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            Text("保存")
                .font(AppTypography.createPostSubmit)
                .foregroundStyle(AppColors.onTagText)
                .frame(maxWidth: .infinity)
                .frame(height: AppSize.createPostSubmitHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.postTag)
                )
        }
        .buttonStyle(.plain)
        .disabled(isSaving || selectedImage == nil)
        .opacity(isSaving || selectedImage == nil ? 0.6 : 1)
    }

    private func save() async {
        guard let selectedImage else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await viewModel.updateProfileImage(selectedImage)
            onSaved()
        } catch {
            errorMessage = "保存に失敗しました。もう一度お試しください。"
        }
    }
}
