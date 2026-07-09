//
//  LocalUserProfileStore.swift
//  matiapu
//

import Foundation

private enum UserProfileDefaults {
    nonisolated static let suiteName = "com.minato.matiapu.user-profile-cache"
}

/// ログイン中ユーザーのプロフィールを端末内に保持するストア
final class LocalUserProfileStore: @unchecked Sendable {
    static let shared = LocalUserProfileStore()

    private let lock = NSLock()
    private nonisolated(unsafe) let defaults: UserDefaults
    private let profileKeyPrefix = "cached_profile_"

    nonisolated init() {
        guard let defaults = UserDefaults(suiteName: UserProfileDefaults.suiteName) else {
            fatalError("プロフィールキャッシュ用 UserDefaults の作成に失敗しました")
        }
        self.defaults = defaults
    }

    func load(uid: String) -> UserProfile? {
        locked {
            guard let data = defaults.data(forKey: key(for: uid)) else { return nil }
            return try? JSONDecoder().decode(UserProfile.self, from: data)
        }
    }

    func save(_ profile: UserProfile) {
        locked {
            guard let data = try? JSONEncoder().encode(profile) else { return }
            defaults.set(data, forKey: key(for: profile.id))
        }
    }

    func remove(uid: String) {
        locked {
            defaults.removeObject(forKey: key(for: uid))
        }
    }

    func clearAll() {
        locked {
            defaults.dictionaryRepresentation().keys
                .filter { $0.hasPrefix(profileKeyPrefix) }
                .forEach { defaults.removeObject(forKey: $0) }
        }
    }

    private func key(for uid: String) -> String {
        profileKeyPrefix + uid
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
