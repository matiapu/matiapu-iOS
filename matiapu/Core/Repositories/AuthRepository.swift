//
//  AuthRepository.swift
//  matiapu
//

import Foundation

protocol AuthRepository: Sendable {
    func fetchCurrentUser() async throws -> UserProfile
    func fetchUserPosts() async throws -> [ProfilePostItem]
    func updateDisplayName(_ name: String) async throws
    func updateRegisteredArea(_ area: String) async throws
    func updateEmail(_ email: String) async throws
    func updatePassword(_ password: String) async throws
    func signOut() async throws
}

final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var currentUser = UserProfile(
        displayName: "ユーザー名ユーザー名",
        registeredArea: "新宿区",
        email: "user@example.com",
        role: .citizen
    )

    func fetchCurrentUser() async throws -> UserProfile {
        locked { currentUser }
    }

    func fetchUserPosts() async throws -> [ProfilePostItem] {
        (1...12).map { index in
            ProfilePostItem(
                id: "profile-post-\(index)",
                imageName: MockImages.postImage(at: index - 1)
            )
        }
    }

    func updateDisplayName(_ name: String) async throws {
        locked {
            currentUser = UserProfile(
                displayName: name,
                registeredArea: currentUser.registeredArea,
                email: currentUser.email
            )
        }
    }

    func updateRegisteredArea(_ area: String) async throws {
        locked {
            currentUser = UserProfile(
                displayName: currentUser.displayName,
                registeredArea: area,
                email: currentUser.email
            )
        }
    }

    func updateEmail(_ email: String) async throws {
        locked {
            currentUser = UserProfile(
                displayName: currentUser.displayName,
                registeredArea: currentUser.registeredArea,
                email: email
            )
        }
    }

    func updatePassword(_ password: String) async throws {}

    func signOut() async throws {
        locked {
            currentUser = UserProfile(
                displayName: "ユーザー名ユーザー名",
                registeredArea: "新宿区",
                email: "user@example.com"
            )
        }
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
