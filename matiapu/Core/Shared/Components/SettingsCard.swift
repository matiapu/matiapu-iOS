//
//  SettingsCard.swift
//  matiapu
//

import SwiftUI

struct SettingsCard<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: AppRadius.settingsCard, style: .continuous)
          .fill(AppColors.settingsCardBackground)
      )
  }
}
