//
//  NotificationCoordinator.swift
//  matiapu
//

import FirebaseAuth
import Foundation

@MainActor
final class NotificationCoordinator {
    private let monitor: FirestoreRealtimeNotificationMonitor
    private let pushService: PushNotificationService
    private let inboxStore: LocalNotificationInboxStore

    var onOpenChat: ((String) -> Void)?
    var onOpenNotifications: (() -> Void)?

    init(
        monitor: FirestoreRealtimeNotificationMonitor? = nil,
        pushService: PushNotificationService? = nil,
        inboxStore: LocalNotificationInboxStore? = nil
    ) {
        let inbox = inboxStore ?? LocalNotificationInboxStore.shared
        self.inboxStore = inbox
        self.monitor = monitor ?? FirestoreRealtimeNotificationMonitor(inboxStore: inbox)
        self.pushService = pushService ?? PushNotificationService.shared
    }

    func start() {
        guard FirebaseBootstrap.isConfigured else { return }
        guard let userID = Auth.auth().currentUser?.uid else { return }

        pushService.onNotificationTapped = { [weak self] payload in
            self?.handleTap(payload)
        }

        monitor.onEvent = { [weak self] event in
            Task { @MainActor in
                await self?.handleRealtimeEvent(event)
            }
        }

        monitor.start(userID: userID)
        Task {
            await pushService.requestAuthorizationIfNeeded()
        }
        // トークン発行がログインより先だった場合に備えて保存を再試行
        PushTokenRegistrar.shared.registerPendingTokenIfNeeded()
    }

    func stop() {
        monitor.stop()
    }

    func setOpenConversationID(_ conversationID: String?) {
        monitor.setOpenConversationID(conversationID)
    }

    func markMatchAsKnown(currentUID: String, partnerID: String, currentRole: UserRole) {
        let matchID: String
        switch currentRole {
        case .citizen:
            matchID = FirestoreMatchService.matchDocumentID(userUID: currentUID, politicianUID: partnerID)
        case .legislator:
            matchID = FirestoreMatchService.matchDocumentID(userUID: partnerID, politicianUID: currentUID)
        case .store:
            matchID = FirestoreMatchService.matchDocumentID(userUID: currentUID, politicianUID: partnerID)
        }
        monitor.markMatchAsKnown(matchID)
    }

    func notifyMatch(partnerName: String, conversationID: String) async {
        let notification = AppNotification(
            id: "match-local-\(conversationID)",
            kind: .match,
            title: "マッチしました！",
            body: "\(partnerName)さんとマッチしました。チャットを始めましょう。",
            publishedAt: .now,
            isRead: false,
            relatedID: conversationID
        )
        inboxStore.append(notification)
        await pushService.schedule(
            PushNotificationPayload(
                id: notification.id,
                kind: .match,
                title: notification.title,
                body: notification.body,
                relatedID: conversationID
            )
        )
    }

    private func handleRealtimeEvent(_ event: RealtimeNotificationEvent) async {
        await pushService.schedule(
            PushNotificationPayload(
                id: event.id,
                kind: event.kind,
                title: event.title,
                body: event.body,
                relatedID: event.relatedID
            )
        )
    }

    private func handleTap(_ payload: PushNotificationPayload) {
        switch payload.kind {
        case .message, .match:
            if let relatedID = payload.relatedID {
                onOpenChat?(relatedID)
            }
        case .announcement:
            onOpenNotifications?()
        }
    }
}
