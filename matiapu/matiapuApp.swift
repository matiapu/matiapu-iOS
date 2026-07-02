//
//  matiapuApp.swift
//  matiapu
//
//  Created by 石田湊 on 2026/05/21.
//

import FirebaseCore
import SwiftUI
import UIKit

// SwiftUIライフサイクルでFirebaseを安全に初期化するためのAppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
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
