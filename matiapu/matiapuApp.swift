//
//  matiapuApp.swift
//  matiapu
//
//  Created by 石田湊 on 2026/05/21.
//

import FirebaseCore
import FirebaseMessaging
import SwiftUI
import UIKit

// SwiftUIライフサイクルでFirebaseを安全に初期化するためのAppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard FirebaseBootstrap.isConfigured else { return true }

        // 通知タップのハンドリング（UNUserNotificationCenterDelegate）を早期に有効化
        _ = PushNotificationService.shared
        PushTokenRegistrar.shared.start()
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("リモート通知の登録に失敗しました: \(error.localizedDescription)")
    }
}

@main
struct matiapuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private let dependencies: AppDependencies

    init() {
        FirebaseBootstrap.configureIfNeeded()
        GoogleMapsConfigurator.configureIfNeeded()
        ChatCrypto.configure(chatSalt: AppSecrets.chatSalt)
        dependencies = AppDependencies.live
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
