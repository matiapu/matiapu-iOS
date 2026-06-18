//
//  AppDependencies.swift
//  matiapu
//

import Foundation

struct AppDependencies {
    let postRepository: any PostRepository
    let authRepository: any AuthRepository
    let notificationRepository: any NotificationRepository
    let chatRepository: any ChatRepository
    let matchRepository: any MatchRepository

    static let live: AppDependencies = {
        let chatRepository = MockChatRepository()
        let matchRepository = MockMatchRepository(chatRepository: chatRepository)
        return AppDependencies(
            postRepository: MockPostRepository(),
            authRepository: MockAuthRepository(),
            notificationRepository: MockNotificationRepository(),
            chatRepository: chatRepository,
            matchRepository: matchRepository
        )
    }()
}
