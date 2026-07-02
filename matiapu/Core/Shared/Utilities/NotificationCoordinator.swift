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
        monitor: FirestoreRealtimeNotificationMonitor = FirestoreRealtimeNotificationMonitor(),
        pushService: PushNotificationService = .shared,
        inboxStore: LocalNotificationInboxStore = .shared
    ) {
        self.monitor = monitor
        self.pushService = pushService
        self.inboxStore = inboxStore
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
    }

    func stop() {
        monitor.stop()
    }

    func setOpenConversationID(_ conversationID: String?) {
        monitor.setOpenConversationID(conversationID)
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
