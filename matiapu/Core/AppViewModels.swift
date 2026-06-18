//
//  AppViewModels.swift
//  matiapu
//

import Foundation
import Observation

/// ルートで一度だけ生成し、タブ配下へ渡す ViewModel 群
@Observable
@MainActor
final class AppViewModels {
    let map: MapViewModel
    let post: PostViewModel
    let match: MatchViewModel
    let profile: ProfileViewModel

    init(dependencies: AppDependencies) {
        let postRepository = dependencies.postRepository
        let profileViewModel = ProfileViewModel(
            authRepository: dependencies.authRepository,
            postRepository: postRepository
        )

        map = MapViewModel(postRepository: postRepository)
        post = PostViewModel(postRepository: postRepository)
        match = MatchViewModel(postRepository: postRepository)
        profile = profileViewModel

        Task {
            await map.loadInitialCenter(from: dependencies.authRepository)
        }

        post.onPostCreated = { [weak map] in
            await map?.loadPosts()
            await profileViewModel.loadProfile()
        }
    }
}
