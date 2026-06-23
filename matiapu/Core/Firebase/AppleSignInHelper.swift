//
//  AppleSignInHelper.swift
//  matiapu
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation

enum AppleSignInHelper {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status != errSecSuccess {
                    random = UInt8.random(in: 0...255)
                }
                return random
            }

            randoms.forEach { random in
                if remaining == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func credential(
        idToken: String,
        nonce: String,
        fullName: String?
    ) -> AuthCredential {
        var nameComponents: PersonNameComponents?
        if let fullName, !fullName.isEmpty {
            var components = PersonNameComponents()
            let parts = fullName.split(separator: " ", maxSplits: 1).map(String.init)
            if let familyName = parts.first {
                components.familyName = familyName
            }
            if parts.count > 1 {
                components.givenName = parts[1]
            }
            nameComponents = components
        }

        return OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: nameComponents
        )
    }
}
