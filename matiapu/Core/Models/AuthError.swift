//
//  AuthError.swift
//  matiapu
//

import Foundation

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case emailNotVerified
    case notAuthenticated
    case cancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "メールアドレスの形式が正しくありません。"
        case .weakPassword:
            return "パスワードは8文字以上の英数字で入力してください。"
        case .emailAlreadyInUse:
            return "このメールアドレスはすでに登録されています。"
        case .userNotFound:
            return "アカウントが見つかりませんでした。"
        case .wrongPassword:
            return "メールアドレスまたはパスワードが正しくありません。"
        case .emailNotVerified:
            return "メールアドレスの認証が完了していません。"
        case .notAuthenticated:
            return "ログインが必要です。"
        case .cancelled:
            return "認証がキャンセルされました。"
        case .unknown(let message):
            return message
        }
    }
}
