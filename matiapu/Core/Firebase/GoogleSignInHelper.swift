//
//  GoogleSignInHelper.swift
//  matiapu
//

import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

enum GoogleSignInHelper {
    @MainActor
    static func signIn() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown("Google サインインの設定が見つかりません。")
        }
        guard let rootViewController = UIApplication.shared.rootViewController else {
            throw AuthError.unknown("画面の取得に失敗しました。")
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.unknown("Google 認証トークンの取得に失敗しました。")
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        _ = try await Auth.auth().signIn(with: credential)
    }
}
