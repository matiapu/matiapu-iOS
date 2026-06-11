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
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        GoogleMapsConfigurator.configureIfNeeded()
        return true
    }
}

@main
struct matiapuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private let dependencies = AppDependencies.live

    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
        }
    }
}
