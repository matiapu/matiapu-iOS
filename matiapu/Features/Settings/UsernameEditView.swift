//
//  UsernameEditView.swift
//  matiapu
//

import SwiftUI

struct UsernameEditView: View {
  @Bindable var viewModel: SettingsViewModel
  var onSaved: () -> Void = {}

  @State private var displayName = ""
  @State private var isSaving = false
  @State private var errorMessage: String?

  var body: some View {
    SettingsScreenLayout {
      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.createPostSectionSpacing) {
          fieldLabel("ユーザー名")

          TextField("", text: $displayName, prompt: fieldPrompt("新しいユーザー名"))
            .font(AppTypography.settingsEditField)
            .foregroundStyle(AppColors.settingsCardText)
            .padding(.horizontal, AppSpacing.createPostFieldHorizontal)
            .frame(height: AppSize.createPostTitleFieldHeight)
            .background(
              Capsule(style: .continuous)
                .fill(AppColors.settingsCardBackground)
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
      displayName = viewModel.profile?.displayName ?? ""
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
    .disabled(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    .opacity(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
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
    let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    isSaving = true
    errorMessage = nil
    defer { isSaving = false }

    do {
      try await viewModel.updateDisplayName(trimmed)
      onSaved()
    } catch {
      errorMessage = "保存に失敗しました。もう一度お試しください。"
    }
  }
}

#Preview {
  NavigationStack {
    UsernameEditView(viewModel: .preview)
  }
}
