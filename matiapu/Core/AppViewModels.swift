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

    var shouldOpenSettingsNotifications = false

    private let notificationCoordinator = NotificationCoordinator()

    init(dependencies: AppDependencies) {
        let useCases = dependencies.useCases
        let profileViewModel = AppViewModelFactory.profile(dependencies: dependencies)
        let chatViewModel = AppViewModelFactory.chat(dependencies: dependencies)

        map = MapViewModel(
            useCases: useCases,
            authRepository: dependencies.authRepository
        )
        post = PostViewModel(useCases: useCases)
        match = AppViewModelFactory.match(dependencies: dependencies)
        profile = profileViewModel
        chat = chatViewModel

        match.onMatched = { [weak self] conversation in
            guard let self else { return }
            await chatViewModel.handleMatch(conversation)
        }

        post.onMatched = { [weak self] conversation in
            guard let self else { return }
            await chatViewModel.handleMatch(conversation)
            await openChat(for: conversation)
        }

        post.onPostCreated = { [weak map] createdPost in
            map?.insertCreatedPost(createdPost)
            await map?.loadPosts()
            await profileViewModel.loadProfile()
        }

        chat.onConversationVisibilityChanged = { [weak notificationCoordinator] conversationID in
            notificationCoordinator?.setOpenConversationID(conversationID)
        }

        notificationCoordinator.onOpenChat = { [weak self] conversationID in
            Task { @MainActor in
                await self?.openChat(conversationID: conversationID)
            }
        }

        notificationCoordinator.onOpenNotifications = { [weak self] in
            self?.shouldOpenSettingsNotifications = true
        }

        notificationCoordinator.start()
    }

    func openChat(for conversation: ChatConversation) async {
        await chat.loadConversations()
        match.isChatPresented = true
        chat.conversationToOpen = conversation
    }

    func openChat(conversationID: String) async {
        await chat.loadConversations()
        guard let conversation = chat.conversations.first(where: { $0.id == conversationID }) else { return }
        await openChat(for: conversation)
    }

    func clearSettingsNotificationsRequest() {
        shouldOpenSettingsNotifications = false
    }
}
