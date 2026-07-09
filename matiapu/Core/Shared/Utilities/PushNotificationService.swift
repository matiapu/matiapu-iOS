//
//  PushNotificationService.swift
//  matiapu
//

import Foundation
import UserNotifications

enum PushNotificationUserInfoKey: Sendable {
    nonisolated static let kind = "notification_kind"
    nonisolated static let relatedID = "notification_related_id"
    nonisolated static let notificationID = "notification_id"
}

struct PushNotificationPayload: Sendable {
    let id: String
    let kind: AppNotificationKind
    let title: String
    let body: String
    let relatedID: String?

    init(
        id: String = UUID().uuidString,
        kind: AppNotificationKind,
        title: String,
        body: String,
        relatedID: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.relatedID = relatedID
    }
}

@MainActor
final class PushNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationService()

    var onNotificationTapped: ((PushNotificationPayload) -> Void)?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    func schedule(_ payload: PushNotificationPayload) async {
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default
        content.userInfo = [
            PushNotificationUserInfoKey.kind: payload.kind.rawValue,
            PushNotificationUserInfoKey.notificationID: payload.id,
            PushNotificationUserInfoKey.relatedID: payload.relatedID as Any,
        ]

        let request = UNNotificationRequest(
            identifier: payload.id,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // フォアグラウンド中は Firestore リスナー経由のローカル通知が表示されるため、
        // FCM からのリモート通知は表示せず二重通知を防ぐ
        let userInfo = notification.request.content.userInfo
        if userInfo["gcm.message_id"] != nil {
            return []
        }
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let kindRaw = userInfo[PushNotificationUserInfoKey.kind] as? String
        let notificationID = userInfo[PushNotificationUserInfoKey.notificationID] as? String
        let relatedID = userInfo[PushNotificationUserInfoKey.relatedID] as? String
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body

        await MainActor.run {
            guard let kindRaw, let kind = AppNotificationKind(rawValue: kindRaw) else { return }

            let payload = PushNotificationPayload(
                id: notificationID ?? UUID().uuidString,
                kind: kind,
                title: title,
                body: body,
                relatedID: relatedID
            )
            PushNotificationService.shared.onNotificationTapped?(payload)
        }
    }
}
