//
//  AppDependencies.swift
//  matiapu
//

import Foundation

struct AppDependencies {
    let postRepository: any PostRepository
    let authRepository: any AuthRepository

    static let live = AppDependencies(
        postRepository: MockPostRepository(),
        authRepository: MockAuthRepository()
    )
}
