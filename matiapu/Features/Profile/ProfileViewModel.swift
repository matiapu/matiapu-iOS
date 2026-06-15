//
//  ProfileViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var profile: UserProfile?
    private(set) var posts: [Post] = []
    private(set) var isLoading = false

    private let authRepository: any AuthRepository
    private let postRepository: any PostRepository

    init(
        authRepository: any AuthRepository,
        postRepository: any PostRepository
    ) {
        self.authRepository = authRepository
        self.postRepository = postRepository
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        profile = try? await authRepository.fetchCurrentUser()
        posts = (try? await postRepository.fetchUserPosts()) ?? []
    }

    func signOut() {
        Task {
            try? await authRepository.signOut()
            profile = nil
            posts = []
        }
    }
}

#if DEBUG
extension ProfileViewModel {
    static var preview: ProfileViewModel {
        let viewModel = ProfileViewModel(
            authRepository: MockAuthRepository(),
            postRepository: MockPostRepository()
        )
        viewModel.profile = UserProfile(
            displayName: "ユーザー名ユーザー名",
            registeredArea: "東京都新宿区"
        )
        viewModel.posts = PostPreviewData.userPosts
        return viewModel
    }
}
#endif
