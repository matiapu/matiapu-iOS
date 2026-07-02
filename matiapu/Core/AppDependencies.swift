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
    let commentRepository: any CommentRepository
    let shelterRepository: any ShelterRepository
    let disasterRepository: any DisasterRepository
    let qaRepository: any QARepository

    static let live: AppDependencies = {
        if FirebaseBootstrap.isConfigured {
            return makeFirebaseDependencies()
        }
        return makeMockDependencies()
    }()

    private static func makeFirebaseDependencies() -> AppDependencies {
        let authRepository = FirebaseAuthRepository()
        let likeService = FirestoreLikeService()
        let chatService = FirestoreChatService()
        let matchService = FirestoreMatchService(chatService: chatService)

        return AppDependencies(
            postRepository: FirebasePostRepository(
                authRepository: authRepository,
                likeService: likeService
            ),
            authRepository: authRepository,
            notificationRepository: FirebaseNotificationRepository(),
            chatRepository: FirebaseChatRepository(
                chatService: chatService
            ),
            matchRepository: FirebaseMatchRepository(
                matchService: matchService
            ),
            commentRepository: FirebaseCommentRepository(),
            shelterRepository: FirebaseShelterRepository(),
            disasterRepository: FirebaseDisasterRepository(),
            qaRepository: FirebaseQARepository()
        )
    }

    private static func makeMockDependencies() -> AppDependencies {
        let chatRepository = MockChatRepository()
        let matchRepository = MockMatchRepository(chatRepository: chatRepository)

        return AppDependencies(
            postRepository: MockPostRepository(),
            authRepository: MockAuthRepository(),
            notificationRepository: MockNotificationRepository(),
            chatRepository: chatRepository,
            matchRepository: matchRepository,
            commentRepository: MockCommentRepository(),
            shelterRepository: MockShelterRepository(),
            disasterRepository: MockDisasterRepository(),
            qaRepository: MockQARepository()
        )
    }
}

extension AppDependencies {
    var useCases: AppUseCases {
        AppUseCases.make(from: self)
    }
}
