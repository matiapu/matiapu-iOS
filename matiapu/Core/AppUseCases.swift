//
//  AppUseCases.swift
//  matiapu
//

import Foundation

/// ViewModel から利用するユースケース群（MVVM の Domain 層エントリポイント）
struct AppUseCases: Sendable {
    // Map
    let resolveMunicipalityScope: ResolveMunicipalityScopeUseCase
    let fetchMapPosts: FetchMapPostsUseCase
    let fetchMapOverlays: FetchMapOverlaysUseCase

    // Post
    let createPost: CreatePostUseCase
    let fetchFeedPosts: FetchFeedPostsUseCase
    let recordPostSwipe: RecordPostSwipeUseCase
    let fetchLikedPosts: FetchLikedPostsUseCase

    // Comment
    let loadPostComments: LoadPostCommentsUseCase
    let submitPostComment: SubmitPostCommentUseCase

    // Auth
    let authenticate: AuthenticateUseCase
    let manageAccount: ManageAccountUseCase
    let completeProfile: CompleteProfileUseCase

    // Match
    let fetchMatchCandidates: FetchMatchCandidatesUseCase
    let processMatchSwipe: ProcessMatchSwipeUseCase

    // Profile
    let loadUserProfile: LoadUserProfileUseCase

    // Chat
    let fetchConversations: FetchConversationsUseCase
    let chatRoom: ChatRoomUseCase

    // Settings
    let fetchNotifications: FetchNotificationsUseCase
    let searchPostalCode: SearchPostalCodeUseCase

    // QA
    let fetchQAQuestions: FetchQAQuestionsUseCase
    let loadQADetail: LoadQADetailUseCase

    static func make(from dependencies: AppDependencies) -> AppUseCases {
        let postRepository = dependencies.postRepository
        let authRepository = dependencies.authRepository
        let manageAccount = ManageAccountUseCase(authRepository: authRepository)

        return AppUseCases(
            resolveMunicipalityScope: ResolveMunicipalityScopeUseCase(
                authRepository: authRepository
            ),
            fetchMapPosts: FetchMapPostsUseCase(postRepository: postRepository),
            fetchMapOverlays: FetchMapOverlaysUseCase(
                shelterRepository: dependencies.shelterRepository,
                disasterRepository: dependencies.disasterRepository
            ),
            createPost: CreatePostUseCase(postRepository: postRepository),
            fetchFeedPosts: FetchFeedPostsUseCase(
                postRepository: postRepository,
                authRepository: authRepository
            ),
            recordPostSwipe: RecordPostSwipeUseCase(
                postRepository: postRepository,
                matchRepository: dependencies.matchRepository,
                authRepository: authRepository
            ),
            fetchLikedPosts: FetchLikedPostsUseCase(postRepository: postRepository),
            loadPostComments: LoadPostCommentsUseCase(
                commentRepository: dependencies.commentRepository,
                authRepository: authRepository
            ),
            submitPostComment: SubmitPostCommentUseCase(
                commentRepository: dependencies.commentRepository,
                authRepository: authRepository
            ),
            authenticate: AuthenticateUseCase(authRepository: authRepository),
            manageAccount: manageAccount,
            completeProfile: CompleteProfileUseCase(authRepository: authRepository),
            fetchMatchCandidates: FetchMatchCandidatesUseCase(postRepository: postRepository),
            processMatchSwipe: ProcessMatchSwipeUseCase(
                postRepository: postRepository,
                matchRepository: dependencies.matchRepository,
                manageAccount: manageAccount
            ),
            loadUserProfile: LoadUserProfileUseCase(
                manageAccount: manageAccount,
                postRepository: postRepository
            ),
            fetchConversations: FetchConversationsUseCase(
                chatRepository: dependencies.chatRepository
            ),
            chatRoom: ChatRoomUseCase(chatRepository: dependencies.chatRepository),
            fetchNotifications: FetchNotificationsUseCase(
                notificationRepository: dependencies.notificationRepository
            ),
            searchPostalCode: SearchPostalCodeUseCase(),
            fetchQAQuestions: FetchQAQuestionsUseCase(
                qaRepository: dependencies.qaRepository
            ),
            loadQADetail: LoadQADetailUseCase(qaRepository: dependencies.qaRepository)
        )
    }
}
