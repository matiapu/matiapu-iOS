//
//  SettingsSearchBar.swift
//  matiapu
//

import SwiftUI

struct SettingsSearchBar: View {
  let placeholder: String
  @Binding var text: String
  var keyboardType: UIKeyboardType = .default

  var body: some View {
  HStack(spacing: 10) {
    Image(systemName: "magnifyingglass")
      .font(.system(size: 16, weight: .medium))
      .foregroundStyle(AppColors.settingsSearchPlaceholder)

    TextField("", text: $text, prompt: searchPrompt)
      .font(AppTypography.settingsSearch)
      .foregroundStyle(AppColors.settingsCardText)
      .keyboardType(keyboardType)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
  }
  .padding(.horizontal, AppSpacing.settingsHorizontal)
  .frame(height: AppSize.settingsSearchBarHeight)
  .background(
    Capsule(style: .continuous)
      .fill(AppColors.settingsCardBackground)
  )
  }

  private var searchPrompt: Text {
    Text(placeholder)
      .font(AppTypography.settingsSearch)
      .foregroundStyle(AppColors.settingsSearchPlaceholder)
  }
}
