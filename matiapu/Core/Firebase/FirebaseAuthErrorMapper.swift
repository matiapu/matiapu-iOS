//
//  FirebaseAuthErrorMapper.swift
//  matiapu
//

import FirebaseAuth
import Foundation

enum FirebaseAuthErrorMapper {
    static func map(_ error: Error) -> AuthError {
        let nsError = error as NSError
        guard
            nsError.domain == AuthErrorDomain,
            let code = AuthErrorCode(rawValue: nsError.code)
        else {
            return .unknown(error.localizedDescription)
        }

        switch code {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .userNotFound:
            return .userNotFound
        case .wrongPassword, .invalidCredential:
            return .wrongPassword
        case .networkError:
            return .unknown("ネットワークエラーが発生しました。")
        case .tooManyRequests:
            return .unknown("リクエストが多すぎます。しばらく待ってから再度お試しください。")
        case .requiresRecentLogin:
            return .requiresRecentLogin
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
