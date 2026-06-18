//
//  SettingsScreenLayout.swift
//  matiapu
//

import SwiftUI

struct SettingsScreenLayout<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    ZStack {
      AppColors.postScreenBackgroundGradient
        .ignoresSafeArea()

      content()
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(.hidden, for: .navigationBar)
    .toolbarColorScheme(.dark, for: .navigationBar)
  }
}
