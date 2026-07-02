//
//  FirebaseEmailVerificationSettings.swift
//  matiapu
//

import FirebaseAuth
import Foundation

enum FirebaseEmailVerificationSettings {
    /// 認証メールを送信する。
    /// ActionCodeSettings の in-app ハンドリングは環境依存で届かないことがあるため、
    /// まず標準 API を使い、失敗時のみ continue URL 付きで再送する。
    static func send(to user: User) async throws {
        do {
            try await user.sendEmailVerification()
            return
        } catch {
            let mapped = FirebaseAuthErrorMapper.map(error)
            guard shouldRetryWithContinueURL(mapped) else {
                throw mapped
            }
        }

        let settings = ActionCodeSettings()
        settings.url = continueURL
        settings.handleCodeInApp = false
        if let bundleID = Bundle.main.bundleIdentifier {
            settings.setIOSBundleID(bundleID)
        }

        do {
            try await user.sendEmailVerification(with: settings)
        } catch {
            throw FirebaseAuthErrorMapper.map(error)
        }
    }

    private static var continueURL: URL {
        let projectID = googleServiceValue(for: "PROJECT_ID") ?? "matiapu-d775d"
        return URL(string: "https://\(projectID).firebaseapp.com")!
    }

    private static func googleServiceValue(for key: String) -> String? {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any],
            let value = dictionary[key] as? String,
            !value.isEmpty
        else {
            return nil
        }
        return value
    }

    private static func shouldRetryWithContinueURL(_ error: AuthError) -> Bool {
        if case .unknown = error {
            return true
        }
        return false
    }
}
