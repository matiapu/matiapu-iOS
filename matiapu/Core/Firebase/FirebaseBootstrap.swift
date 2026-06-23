//
//  FirebaseBootstrap.swift
//  matiapu
//

import FirebaseCore
import Foundation

enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }
        FirebaseApp.configure()
        isConfigured = FirebaseApp.app() != nil
    }
}
