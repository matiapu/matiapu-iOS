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
    let chat: ChatViewModel

    init(dependencies: AppDependencies) {
        let postRepository = dependencies.postRepository
        let profileViewModel = ProfileViewModel(
            authRepository: dependencies.authRepository,
            postRepository: postRepository
        )

        let chatViewModel = ChatViewModel(chatRepository: dependencies.chatRepository)

        map = MapViewModel(postRepository: postRepository)
        post = PostViewModel(
            postRepository: postRepository,
            matchRepository: dependencies.matchRepository,
            authRepository: dependencies.authRepository
        )
        match = MatchViewModel(
            postRepository: postRepository,
            matchRepository: dependencies.matchRepository,
            authRepository: dependencies.authRepository
        )
        profile = profileViewModel
        chat = chatViewModel

        match.onMatched = { [weak chatViewModel] conversation in
            await chatViewModel?.loadConversations()
            _ = conversation
        }

        Task {
            await map.loadInitialCenter(from: dependencies.authRepository)
        }

        post.onPostCreated = { [weak map] in
            await map?.loadPosts()
            await profileViewModel.loadProfile()
        }
    }
}
