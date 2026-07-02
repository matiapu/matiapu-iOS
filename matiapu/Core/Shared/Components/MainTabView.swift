//
//  MainTabView.swift
//  matiapu
//

import SwiftUI

struct MainTabView: View {
    @Bindable var viewModels: AppViewModels
    let dependencies: AppDependencies
    var onSignOut: () -> Void = {}

    @State private var selectedTab: Tab = .map

    private enum Tab: Hashable {
        case map
        case post
        case match
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView(
                viewModel: viewModels.map,
                postViewModel: viewModels.post,
                isLocationTrackingEnabled: selectedTab == .map
            )
                .tabItem {
                    Label("map", systemImage: "mappin.and.ellipse")
                }
                .tag(Tab.map)

            PostView(viewModel: viewModels.post, chatViewModel: viewModels.chat)
                .tabItem {
                    Label("post", systemImage: "person.line.dotted.person.fill")
                }
                .tag(Tab.post)

            MatchView(viewModel: viewModels.match, chatViewModel: viewModels.chat)
                .tabItem {
                    Label("match", systemImage: "figure.walk.suitcase.rolling")
                }
                .tag(Tab.match)

            ProfileView(
                viewModel: viewModels.profile,
                dependencies: dependencies,
                onSignOut: onSignOut,
                onRegisteredAreaChanged: {
                    Task { await viewModels.map.reloadMunicipalityScope() }
                },
                shouldOpenNotifications: viewModels.shouldOpenSettingsNotifications,
                onNotificationsOpened: {
                    viewModels.clearSettingsNotificationsRequest()
                }
            )
                .tabItem {
                    Label("account", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .environment(\.appDependencies, dependencies)
        .tint(.blue)
        .onChange(of: viewModels.chat.conversationToOpen?.id) { _, conversationID in
            guard conversationID != nil else { return }
            selectedTab = .match
        }
        .sheet(item: createPostPresentation) { createPostViewModel in
            CreatePostView(viewModel: createPostViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var createPostPresentation: Binding<CreatePostViewModel?> {
        Binding(
            get: { viewModels.post.createPostViewModel },
            set: { newValue in
                if newValue == nil {
                    viewModels.post.dismissCreatePost()
                }
            }
        )
    }
}

#Preview {
    MainTabView(viewModels: AppViewModels(dependencies: .live), dependencies: .live)
}
