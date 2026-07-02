//
//  PushNotificationService.swift
//  matiapu
//

import Foundation
import UserNotifications

enum PushNotificationUserInfoKey {
    static let kind = "notification_kind"
    static let relatedID = "notification_related_id"
    static let notificationID = "notification_id"
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
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard
            let kindRaw = userInfo[PushNotificationUserInfoKey.kind] as? String,
            let kind = AppNotificationKind(rawValue: kindRaw)
        else {
            return
        }

        let payload = PushNotificationPayload(
            id: userInfo[PushNotificationUserInfoKey.notificationID] as? String ?? UUID().uuidString,
            kind: kind,
            title: response.notification.request.content.title,
            body: response.notification.request.content.body,
            relatedID: userInfo[PushNotificationUserInfoKey.relatedID] as? String
        )

        await MainActor.run {
            PushNotificationService.shared.onNotificationTapped?(payload)
        }
    }
}
