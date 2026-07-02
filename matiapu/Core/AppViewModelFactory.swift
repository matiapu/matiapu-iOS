//
//  AppViewModelFactory.swift
//  matiapu
//

import Foundation

/// Composition Root から ViewModel を生成するファクトリ
@MainActor
enum AppViewModelFactory {
    static func auth(dependencies: AppDependencies) -> AuthViewModel {
        AuthViewModel(useCases: dependencies.useCases)
    }

    static func profile(dependencies: AppDependencies) -> ProfileViewModel {
        ProfileViewModel(
            loadUserProfile: dependencies.useCases.loadUserProfile,
            manageAccount: dependencies.useCases.manageAccount
        )
    }

    static func chat(dependencies: AppDependencies) -> ChatViewModel {
        ChatViewModel(useCases: dependencies.useCases)
    }

    static func match(dependencies: AppDependencies) -> MatchViewModel {
        MatchViewModel(useCases: dependencies.useCases)
    }

    static func settings(dependencies: AppDependencies) -> SettingsViewModel {
        SettingsViewModel(useCases: dependencies.useCases)
    }

    static func likedPosts(dependencies: AppDependencies) -> LikedPostsViewModel {
        LikedPostsViewModel(fetchLikedPosts: dependencies.useCases.fetchLikedPosts)
    }

    static func notifications(dependencies: AppDependencies) -> NotificationsViewModel {
        NotificationsViewModel(fetchNotifications: dependencies.useCases.fetchNotifications)
    }

    static func qa(dependencies: AppDependencies) -> QAViewModel {
        QAViewModel(fetchQAQuestions: dependencies.useCases.fetchQAQuestions)
    }

    static func qaDetail(questionId: String, dependencies: AppDependencies) -> QADetailViewModel {
        QADetailViewModel(
            questionId: questionId,
            loadQADetail: dependencies.useCases.loadQADetail
        )
    }

    static func profileRegistration(
        role: UserRole,
        dependencies: AppDependencies
    ) -> ProfileRegistrationViewModel {
        ProfileRegistrationViewModel(
            completeProfile: dependencies.useCases.completeProfile,
            role: role
        )
    }
}
