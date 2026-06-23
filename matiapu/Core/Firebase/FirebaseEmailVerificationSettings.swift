//
//  FirebaseEmailVerificationSettings.swift
//  matiapu
//

import FirebaseAuth
import Foundation

enum FirebaseEmailVerificationSettings {
    /// Firebase Console の「承認済みドメイン」に含まれる URL を使用する。
    static func make() -> ActionCodeSettings {
        let settings = ActionCodeSettings()
        settings.url = URL(string: "https://matiapu-d775d.firebaseapp.com")!
        settings.handleCodeInApp = true
        if let bundleID = Bundle.main.bundleIdentifier {
            settings.setIOSBundleID(bundleID)
        }
        return settings
    }
}
