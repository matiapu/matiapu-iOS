//
//  MainTabView.swift
//  matiapu
//

import SwiftUI

struct MainTabView: View {
    var viewModels: AppViewModels

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

            MatchView(viewModel: viewModels.match)
                .tabItem {
                    Label("match", systemImage: "figure.walk.suitcase.rolling")
                }

            ProfileView(viewModel: viewModels.profile)
                .tabItem {
                    Label("account", systemImage: "person.fill")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView(viewModels: AppViewModels(dependencies: .live))
}
