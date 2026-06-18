//
//  AppDependencies.swift
//  matiapu
//

import Foundation

struct AppDependencies {
    let postRepository: any PostRepository
    let authRepository: any AuthRepository
    let notificationRepository: any NotificationRepository

    static let live = AppDependencies(
        postRepository: MockPostRepository(),
        authRepository: MockAuthRepository(),
        notificationRepository: MockNotificationRepository()
    )
}
