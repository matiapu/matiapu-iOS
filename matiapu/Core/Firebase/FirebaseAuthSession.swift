//
//  FirebaseAuthSession.swift
//  matiapu
//

import FirebaseAuth
import Foundation

enum FirebaseAuthSession {
    static var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    static var currentUser: User? {
        Auth.auth().currentUser
    }

    static func ensureSignedIn() async throws -> String {
        guard let uid = currentUID else {
            throw FirebaseRepositoryError.notAuthenticated
        }
        return uid
    }

    static func needsEmailVerification(user: User) -> Bool {
        let providers = user.providerData.map(\.providerID)
        let isEmailProvider = providers.contains("password") || providers.isEmpty
        return isEmailProvider && !user.isEmailVerified
    }
}
