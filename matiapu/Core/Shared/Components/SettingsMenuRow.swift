//
//  SettingsMenuRow.swift
//  matiapu
//

import SwiftUI

struct SettingsMenuRow: View {
  let title: String
  var showsChevron = true
  var titleColor: Color = AppColors.settingsCardText

  var body: some View {
    SettingsCard {
      HStack {
        Spacer(minLength: 0)

        Text(title)
          .font(AppTypography.settingsMenuTitle)
          .foregroundStyle(titleColor)
          .multilineTextAlignment(.center)

        Spacer(minLength: 0)

        if showsChevron {
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.settingsChevron)
        }
      }
      .padding(.horizontal, AppSpacing.settingsHorizontal)
      .padding(.vertical, AppSpacing.settingsMenuRowVertical)
      .frame(minHeight: AppSize.settingsMenuRowMinHeight)
    }
  }
}
