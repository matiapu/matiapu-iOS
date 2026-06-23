//
//  SettingsFlowView.swift
//  matiapu
//

import SwiftUI

struct SettingsFlowView: View {
  @State private var settingsViewModel: SettingsViewModel
  @State private var likedPostsViewModel: LikedPostsViewModel
  @State private var notificationsViewModel: NotificationsViewModel
  @State private var navigationPath = NavigationPath()
  @Environment(\.dismiss) private var dismiss
  let onSignOut: () -> Void

  init(
    dependencies: AppDependencies,
    mapViewModel: MapViewModel,
    onSignOut: @escaping () -> Void = {}
  ) {
    let settingsViewModel = SettingsViewModel(
      authRepository: dependencies.authRepository,
      notificationRepository: dependencies.notificationRepository
    )
    settingsViewModel.onRegisteredAreaUpdated = { area in
      Task { await mapViewModel.updateCenter(forRegisteredArea: area) }
    }
    _settingsViewModel = State(initialValue: settingsViewModel)
    _likedPostsViewModel = State(
      initialValue: LikedPostsViewModel(postRepository: dependencies.postRepository)
    )
    _notificationsViewModel = State(
      initialValue: NotificationsViewModel(
        notificationRepository: dependencies.notificationRepository
      )
    )
    self.onSignOut = onSignOut
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      SettingsView(viewModel: settingsViewModel, onSignOut: onSignOut)
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
        viewModel: RegionSelectionViewModel(),
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
      LikedPostsView(viewModel: likedPostsViewModel)
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
    }
  }

  private func resetNavigation() {
    navigationPath = NavigationPath()
  }
}

#Preview {
  SettingsFlowView(dependencies: .live, mapViewModel: MapViewModel(postRepository: MockPostRepository()))
}
