//
//  AuthRepository.swift
//  matiapu
//

import Foundation

protocol AuthRepository: Sendable {
    var isAuthenticated: Bool { get }
    var pendingVerificationDisplayName: String? { get }

    func fetchCurrentUser(forceRefresh: Bool) async throws -> UserProfile
    func cachedCurrentUser() -> UserProfile?
    func fetchUserPosts() async throws -> [ProfilePostItem]
    func fetchPublicProfiles(userIDs: [String]) async throws -> [String: UserPublicProfile]
    func updateDisplayName(_ name: String) async throws
    func updateRegisteredArea(_ area: String) async throws
    func updateEmail(_ email: String) async throws
    func updatePassword(_ password: String) async throws
    func signOut() async throws
    func deleteAccount() async throws

    func signIn(email: String, password: String) async throws
    func signUp(displayName: String, email: String, password: String, role: UserRole) async throws
    func updateRegistrationRole(_ role: UserRole) async throws
    func completeProfile(_ input: ProfileCompletionInput) async throws
    func signInWithGoogle() async throws
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws
    func sendPasswordReset(to email: String) async throws
    func sendEmailVerification() async throws
    func reloadAndCheckEmailVerified() async throws -> Bool
}

extension AuthRepository {
    var isAuthenticated: Bool { false }
    var pendingVerificationDisplayName: String? { nil }

    func fetchCurrentUser() async throws -> UserProfile {
        try await fetchCurrentUser(forceRefresh: false)
    }

    func cachedCurrentUser() -> UserProfile? { nil }

    func signIn(email: String, password: String) async throws {
        throw AuthError.unknown("この環境ではログインできません。")
    }

    func signUp(displayName: String, email: String, password: String, role: UserRole) async throws {
        throw AuthError.unknown("この環境では登録できません。")
    }

    func updateRegistrationRole(_ role: UserRole) async throws {}

    func completeProfile(_ input: ProfileCompletionInput) async throws {
        throw AuthError.unknown("この環境ではプロフィール登録できません。")
    }

    func signInWithGoogle() async throws {
        throw AuthError.unknown("この環境では Google サインインできません。")
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws {
        throw AuthError.unknown("この環境では Apple サインインできません。")
    }

    func sendPasswordReset(to email: String) async throws {
        throw AuthError.unknown("この環境ではパスワード再設定できません。")
    }

    func sendEmailVerification() async throws {
        throw AuthError.unknown("この環境では認証メールを送信できません。")
    }

    func reloadAndCheckEmailVerified() async throws -> Bool { true }

    func fetchPublicProfiles(userIDs: [String]) async throws -> [String: UserPublicProfile] { [:] }

    func deleteAccount() async throws {
        throw AuthError.unknown("この環境ではアカウントを削除できません。")
    }
}

final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var isSignedIn = true
    private var currentUser = UserProfile(
        displayName: "ユーザー名ユーザー名",
        registeredArea: PreviewMockRegion.municipalityName,
        email: "user@example.com",
        role: .citizen
    )

    var isAuthenticated: Bool {
        locked { isSignedIn }
    }

    func fetchCurrentUser(forceRefresh: Bool) async throws -> UserProfile {
        guard locked({ isSignedIn }) else { throw AuthError.notAuthenticated }
        return locked { currentUser }
    }

    func cachedCurrentUser() -> UserProfile? {
        locked { isSignedIn ? currentUser : nil }
    }

    func fetchUserPosts() async throws -> [ProfilePostItem] {
        (1...12).map { index in
            ProfilePostItem(
                id: "profile-post-\(index)",
                imageName: MockImages.postImage(at: index - 1)
            )
        }
    }

    func fetchPublicProfiles(userIDs: [String]) async throws -> [String: UserPublicProfile] {
        let uniqueIDs = Array(Set(userIDs))
        guard !uniqueIDs.isEmpty else { return [:] }

        return Dictionary(
            uniqueKeysWithValues: uniqueIDs.map { id in
                (
                    id,
                    UserPublicProfile(
                        id: id,
                        displayName: id == currentUser.id ? currentUser.displayName : UserPublicProfile.fallbackDisplayName,
                        profileImageURL: id == currentUser.id ? currentUser.profileImageURL : nil
                    )
                )
            }
        )
    }

    func updateDisplayName(_ name: String) async throws {
        locked {
            currentUser = UserProfile(
                id: currentUser.id,
                displayName: name,
                registeredArea: currentUser.registeredArea,
                email: currentUser.email,
                role: currentUser.role
            )
        }
    }

    func updateRegisteredArea(_ area: String) async throws {
        locked {
            currentUser = UserProfile(
                id: currentUser.id,
                displayName: currentUser.displayName,
                registeredArea: area,
                email: currentUser.email,
                role: currentUser.role
            )
        }
    }

    func updateEmail(_ email: String) async throws {
        locked {
            currentUser = UserProfile(
                id: currentUser.id,
                displayName: currentUser.displayName,
                registeredArea: currentUser.registeredArea,
                email: email,
                role: currentUser.role
            )
        }
    }

    func updatePassword(_ password: String) async throws {}

    func signOut() async throws {
        locked { isSignedIn = false }
    }

    func deleteAccount() async throws {
        locked { isSignedIn = false }
    }

    func signIn(email: String, password: String) async throws {
        guard !email.isEmpty, password.count >= 8 else {
            throw AuthError.weakPassword
        }
        locked {
            isSignedIn = true
            currentUser = UserProfile(
                displayName: currentUser.displayName,
                registeredArea: currentUser.registeredArea,
                email: email,
                role: .citizen
            )
        }
    }

    func signUp(displayName: String, email: String, password: String, role: UserRole) async throws {
        guard !displayName.isEmpty else { throw AuthError.unknown("お名前を入力してください。") }
        guard email.contains("@") else { throw AuthError.invalidEmail }
        guard password.count >= 8 else { throw AuthError.weakPassword }

        locked {
            isSignedIn = true
            currentUser = UserProfile(
                displayName: displayName,
                registeredArea: "",
                email: email,
                role: role,
                isProfileCompleted: false
            )
        }
    }

    func updateRegistrationRole(_ role: UserRole) async throws {
        locked {
            currentUser = UserProfile(
                id: currentUser.id,
                displayName: currentUser.displayName,
                registeredArea: currentUser.registeredArea,
                email: currentUser.email,
                role: role,
                isProfileCompleted: currentUser.isProfileCompleted
            )
        }
    }

    func completeProfile(_ input: ProfileCompletionInput) async throws {
        locked {
            let displayName: String
            let registeredArea: String
            switch input {
            case .citizen(let citizen):
                displayName = citizen.nickname
                registeredArea = citizen.address.displayMunicipality
            case .store(let store):
                displayName = store.storeName
                registeredArea = store.address.displayMunicipality
            case .legislator(let legislator):
                displayName = "\(legislator.lastName) \(legislator.firstName)"
                registeredArea = legislator.address.displayMunicipality
            }

            currentUser = UserProfile(
                id: currentUser.id,
                displayName: displayName,
                registeredArea: registeredArea,
                email: currentUser.email,
                role: input.role,
                isProfileCompleted: true
            )
        }
    }

    func signInWithGoogle() async throws {
        locked {
            isSignedIn = true
            currentUser = UserProfile(
                displayName: currentUser.displayName,
                registeredArea: currentUser.registeredArea,
                email: currentUser.email,
                role: .citizen,
                isProfileCompleted: false
            )
        }
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws {
        locked {
            isSignedIn = true
            currentUser = UserProfile(
                displayName: fullName ?? currentUser.displayName,
                registeredArea: currentUser.registeredArea,
                email: currentUser.email,
                role: .citizen,
                isProfileCompleted: false
            )
        }
    }

    func sendPasswordReset(to email: String) async throws {
        guard email.contains("@") else { throw AuthError.invalidEmail }
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
