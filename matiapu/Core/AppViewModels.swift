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
        map = MapViewModel(postRepository: postRepository)
        post = PostViewModel(postRepository: postRepository)
        match = MatchViewModel(postRepository: postRepository)
        profile = ProfileViewModel(authRepository: dependencies.authRepository)

        post.onPostCreated = { [weak map] in
            await map?.loadPosts()
        }
    }
}
