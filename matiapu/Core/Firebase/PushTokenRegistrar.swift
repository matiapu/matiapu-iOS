//
//  PushTokenRegistrar.swift
//  matiapu
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Foundation

/// FCM トークンを取得し、ログイン中のユーザーの Firestore ドキュメントに保存する。
/// トークン発行時に未ログインの場合があるため、ログイン後に `registerPendingTokenIfNeeded()` で再試行する。
final class PushTokenRegistrar: NSObject, MessagingDelegate, @unchecked Sendable {
    static let shared = PushTokenRegistrar()

    private let lock = NSLock()
    private var latestToken: String?

    static let announcementsTopic = "announcements"

    private override init() {
        super.init()
    }

    func start() {
        guard FirebaseBootstrap.isConfigured else { return }
        Messaging.messaging().delegate = self
    }

    /// ログイン完了後に呼び、未保存のトークンがあれば保存する
    func registerPendingTokenIfNeeded() {
        let token = locked { latestToken }
        guard let token else { return }
        save(token: token)
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        locked { latestToken = fcmToken }
        save(token: fcmToken)

        messaging.subscribe(toTopic: Self.announcementsTopic)
    }

    private func save(token: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let userRef = Firestore.firestore()
            .collection(FirestoreCollections.users)
            .document(userID)

        userRef.setData(
            [FirestoreFields.User.fcmTokens: FieldValue.arrayUnion([token])],
            merge: true
        ) { error in
            if let error {
                print("FCMトークンの保存に失敗しました: \(error.localizedDescription)")
            }
        }
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
