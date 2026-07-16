//
//  EmailPasswordEditView.swift
//  matiapu
//

import SwiftUI

struct EmailPasswordEditView: View {
  @Bindable var viewModel: SettingsViewModel
  var onSaved: () -> Void = {}

  @State private var email = ""
  @State private var password = ""
  @State private var isSaving = false
  @State private var errorMessage: String?

  var body: some View {
    SettingsScreenLayout {
      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.createPostSectionSpacing) {
          fieldSection(
            title: "メールアドレス",
            text: $email,
            prompt: "新しいメールアドレス"
          )

          fieldSection(
            title: "パスワード",
            text: $password,
            prompt: "新しいパスワード",
            isSecure: true
          )

          if let errorMessage {
            Text(errorMessage)
              .font(AppTypography.createPostField)
              .foregroundStyle(.red)
          }

          saveButton
        }
        .padding(.horizontal, AppSpacing.settingsHorizontal)
        .padding(.top, AppSpacing.settingsContentTop)
        .padding(.bottom, AppSpacing.settingsTabBarInset)
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .onAppear {
      email = viewModel.profile?.email ?? ""
    }
  }

  private func fieldSection(
    title: String,
    text: Binding<String>,
    prompt: String,
    isSecure: Bool = false
  ) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
      fieldLabel(title)

      Group {
        if isSecure {
          SecureField("", text: text, prompt: fieldPrompt(prompt))
        } else {
          TextField("", text: text, prompt: fieldPrompt(prompt))
        }
      }
      .font(AppTypography.settingsEditField)
      .foregroundStyle(AppColors.settingsCardText)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .padding(.horizontal, AppSpacing.createPostFieldHorizontal)
      .frame(height: AppSize.createPostTitleFieldHeight)
      .background(
        Capsule(style: .continuous)
          .fill(AppColors.settingsCardBackground)
      )
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
    .disabled(isSaving || !canSave)
    .opacity(isSaving || !canSave ? 0.6 : 1)
  }

  private var canSave: Bool {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmedEmail.isEmpty || !password.isEmpty
  }

  private func fieldLabel(_ title: String) -> some View {
    Text(title)
      .font(AppTypography.settingsEditLabel)
      .foregroundStyle(AppColors.onImageText)
  }

  private func fieldPrompt(_ title: String) -> Text {
    Text(title)
      .font(AppTypography.settingsEditField)
      .foregroundStyle(AppColors.settingsSearchPlaceholder)
  }

  private func save() async {
    isSaving = true
    errorMessage = nil
    defer { isSaving = false }

    do {
      let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmedEmail.isEmpty {
        try await viewModel.updateEmail(trimmedEmail)
      }
      if !password.isEmpty {
        try await viewModel.updatePassword(password)
      }
      onSaved()
    } catch {
      errorMessage = "保存に失敗しました。もう一度お試しください。"
    }
  }
}
