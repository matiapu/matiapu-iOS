//
//  FirebaseRepositoryError.swift
//  matiapu
//

import Foundation

enum FirebaseRepositoryError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case documentNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase が設定されていません。"
        case .notAuthenticated:
            return "ログインが必要です。"
        case .documentNotFound:
            return "データが見つかりませんでした。"
        case .invalidData:
            return "データ形式が不正です。"
        }
    }
}
