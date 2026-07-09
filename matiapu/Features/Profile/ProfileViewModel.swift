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

    private let loadUserProfile: LoadUserProfileUseCase
    private let manageAccount: ManageAccountUseCase
    private var hasLoadedOnce = false

    init(loadUserProfile: LoadUserProfileUseCase, manageAccount: ManageAccountUseCase) {
        self.loadUserProfile = loadUserProfile
        self.manageAccount = manageAccount
        profile = manageAccount.cachedCurrentUser()
    }

    func syncProfileFromCache() {
        if let cached = manageAccount.cachedCurrentUser() {
            profile = cached
        }
    }

    func loadProfileIfNeeded() async {
        syncProfileFromCache()
        guard !hasLoadedOnce else { return }
        await loadProfile()
    }

    func loadProfile(forceRefresh: Bool = false) async {
        syncProfileFromCache()
        if profile == nil {
            isLoading = true
        }
        defer {
            isLoading = false
            hasLoadedOnce = true
        }

        guard let snapshot = try? await loadUserProfile.execute(forceRefresh: forceRefresh) else { return }
        profile = snapshot.profile
        posts = snapshot.posts
    }

    func signOut() {
        Task {
            try? await manageAccount.signOut()
            profile = nil
            posts = []
            hasLoadedOnce = false
        }
    }
}

#if DEBUG
extension ProfileViewModel {
    static var preview: ProfileViewModel {
        let manageAccount = ManageAccountUseCase(authRepository: MockAuthRepository())
        let viewModel = ProfileViewModel(
            loadUserProfile: LoadUserProfileUseCase(
                manageAccount: manageAccount,
                postRepository: MockPostRepository()
            ),
            manageAccount: manageAccount
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
