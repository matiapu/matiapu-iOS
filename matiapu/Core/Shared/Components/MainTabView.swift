//
//  MainTabView.swift
//  matiapu
//

import SwiftUI

struct MainTabView: View {
    @Bindable var viewModels: AppViewModels
    let dependencies: AppDependencies
    var onSignOut: () -> Void = {}

    var body: some View {
        TabView {
            MapView(viewModel: viewModels.map, postViewModel: viewModels.post)
                .tabItem {
                    Label("map", systemImage: "mappin.and.ellipse")
                }

            PostView(viewModel: viewModels.post)
                .tabItem {
                    Label("post", systemImage: "person.line.dotted.person.fill")
                }

            MatchView(viewModel: viewModels.match, chatViewModel: viewModels.chat)
                .tabItem {
                    Label("match", systemImage: "figure.walk.suitcase.rolling")
                }

            ProfileView(
                viewModel: viewModels.profile,
                dependencies: dependencies,
                onSignOut: onSignOut
            )
                .tabItem {
                    Label("account", systemImage: "person.fill")
                }
        }
        .tint(.blue)
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
