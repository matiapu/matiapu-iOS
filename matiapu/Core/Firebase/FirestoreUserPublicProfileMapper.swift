//
//  FirestoreUserPublicProfileMapper.swift
//  matiapu
//

import Foundation

/// TaskGroup などバックグラウンドコンテキストから呼べるよう、Main actor 非依存で実装
enum FirestoreUserPublicProfileMapper: Sendable {
    nonisolated static func map(from data: [String: Any], uid: String) -> UserPublicProfile {
        let nickname = data["nickname"] as? String ?? ""
        let lastName = data["lastName"] as? String ?? ""
        let firstName = data["firstName"] as? String ?? ""
        let composedName = [lastName, firstName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let storeName = data["storeName"] as? String ?? ""
        let displayName = trimmedNonEmpty(nickname)
            ?? trimmedNonEmpty(storeName)
            ?? trimmedNonEmpty(composedName)
            ?? "ユーザー"

        return UserPublicProfile(
            id: uid,
            displayName: displayName,
            profileImageURL: profileImageURL(from: data)
        )
    }

    nonisolated private static func profileImageURL(from data: [String: Any]) -> String? {
        guard let dictionary = data["profileImage"] as? [String: Any],
              let url = dictionary["url"] as? String else {
            return nil
        }
        return trimmedNonEmpty(url)
    }

    nonisolated private static func trimmedNonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
