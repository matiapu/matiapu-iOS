//
//  SettingsFlowView.swift
//  matiapu
//

import SwiftUI

struct SettingsFlowView: View {
  @State private var settingsViewModel: SettingsViewModel
  @State private var likedPostsViewModel: LikedPostsViewModel
  @State private var notificationsViewModel: NotificationsViewModel
  @State private var qaViewModel: QAViewModel
  @State private var navigationPath = NavigationPath()
  @Environment(\.dismiss) private var dismiss
  private let dependencies: AppDependencies
  let openNotificationsOnAppear: Bool
  let onSignOut: () -> Void

  init(
    dependencies: AppDependencies,
    openNotificationsOnAppear: Bool = false,
    onSignOut: @escaping () -> Void = {}
  ) {
    self.dependencies = dependencies
    self.openNotificationsOnAppear = openNotificationsOnAppear
    _settingsViewModel = State(initialValue: AppViewModelFactory.settings(dependencies: dependencies))
    _likedPostsViewModel = State(initialValue: AppViewModelFactory.likedPosts(dependencies: dependencies))
    _notificationsViewModel = State(initialValue: AppViewModelFactory.notifications(dependencies: dependencies))
    _qaViewModel = State(initialValue: AppViewModelFactory.qa(dependencies: dependencies))
    self.onSignOut = onSignOut
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      SettingsView(viewModel: settingsViewModel)
        .navigationDestination(for: SettingsDestination.self) { destination in
          destinationView(for: destination)
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.onImageText)
            }
          }
        }
    }
    .environment(\.appDependencies, dependencies)
    .onAppear {
      if openNotificationsOnAppear {
        navigationPath.append(SettingsDestination.notifications)
      }
    }
  }

  @ViewBuilder
  private func destinationView(for destination: SettingsDestination) -> some View {
    switch destination {
    case .accountSettings:
      AccountSettingsView()
    case .usernameEdit:
      UsernameEditView(viewModel: settingsViewModel, onSaved: resetNavigation)
    case .emailPasswordEdit:
      EmailPasswordEditView(viewModel: settingsViewModel, onSaved: resetNavigation)
    case .regionSelection:
      RegionSelectionView(
        viewModel: RegionSelectionViewModel(
          searchPostalCode: dependencies.useCases.searchPostalCode
        ),
        settingsViewModel: settingsViewModel,
        onRegionSaved: resetNavigation
      )
    case .municipalitySelection(let prefectureName):
      MunicipalitySelectionView(
        prefectureName: prefectureName,
        settingsViewModel: settingsViewModel,
        onRegionSaved: resetNavigation
      )
    case .likedPosts:
      LikedPostsView(viewModel: likedPostsViewModel, dependencies: dependencies)
    case .notifications:
      NotificationsView(viewModel: notificationsViewModel)
        .onDisappear {
          Task { await settingsViewModel.loadUnreadNotificationCount() }
        }
    case .notificationDetail(let notificationId):
      NotificationDetailView(
        notificationId: notificationId,
        viewModel: notificationsViewModel
      )
    case .qaList:
      QAListView(viewModel: qaViewModel)
    case .qaDetail(let questionId):
      QADetailView(
        questionId: questionId,
        viewModel: AppViewModelFactory.qaDetail(
          questionId: questionId,
          dependencies: dependencies
        )
      )
    case .signOutConfirmation:
      SettingsConfirmationView(
        title: "ログアウト",
        message: "ログアウトしますか？",
        confirmTitle: "ログアウトする",
        isDestructive: false,
        onConfirm: {
          onSignOut()
        }
      )
    case .deleteAccountConfirmation:
      SettingsConfirmationView(
        title: "アカウント削除",
        message: "アカウントを削除すると、プロフィールや投稿データは復元できません。本当に削除しますか？",
        confirmTitle: "アカウントを削除する",
        isDestructive: true,
        isProcessing: settingsViewModel.isDeletingAccount,
        errorMessage: settingsViewModel.deleteAccountError,
        onConfirm: {
          let deleted = await settingsViewModel.deleteAccount()
          if deleted {
            onSignOut()
          }
        }
      )
    }
  }

  private func resetNavigation() {
    settingsViewModel.syncProfileFromCache()
    navigationPath = NavigationPath()
  }
}

#Preview {
  SettingsFlowView(dependencies: .live)
}
