//
//  AuthenticateUseCase.swift
//  matiapu
//

import Foundation
import UIKit

struct AuthenticateUseCase: Sendable {
    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    var pendingVerificationDisplayName: String? {
        authRepository.pendingVerificationDisplayName
    }

    func signIn(email: String, password: String) async throws {
        try await authRepository.signIn(email: email, password: password)
    }

    func signUp(displayName: String, email: String, password: String, role: UserRole) async throws {
        try await authRepository.signUp(
            displayName: displayName,
            email: email,
            password: password,
            role: role
        )
    }

    func signInWithGoogle() async throws {
        try await authRepository.signInWithGoogle()
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws {
        try await authRepository.signInWithApple(
            idToken: idToken,
            nonce: nonce,
            fullName: fullName
        )
    }
}

struct ManageAccountUseCase: Sendable {
    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    func fetchCurrentUser(forceRefresh: Bool = false) async throws -> UserProfile {
        try await authRepository.fetchCurrentUser(forceRefresh: forceRefresh)
    }

    func cachedCurrentUser() -> UserProfile? {
        authRepository.cachedCurrentUser()
    }

    func signOut() async throws {
        try await authRepository.signOut()
    }

    func deleteAccount() async throws {
        try await authRepository.deleteAccount()
    }

    func sendPasswordReset(to email: String) async throws {
        try await authRepository.sendPasswordReset(to: email)
    }

    func sendEmailVerification() async throws {
        try await authRepository.sendEmailVerification()
    }

    func reloadAndCheckEmailVerified() async throws -> Bool {
        try await authRepository.reloadAndCheckEmailVerified()
    }

    func updateDisplayName(_ name: String) async throws {
        try await authRepository.updateDisplayName(name)
    }

    func updateProfileImage(_ image: UIImage) async throws {
        try await authRepository.updateProfileImage(image)
    }

    func updateRegisteredArea(_ area: String) async throws {
        try await authRepository.updateRegisteredArea(area)
    }

    func updateEmail(_ email: String) async throws {
        try await authRepository.updateEmail(email)
    }

    func updatePassword(_ password: String) async throws {
        try await authRepository.updatePassword(password)
    }
}

struct CompleteProfileUseCase: Sendable {
    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    func loadRegistrationEmail() async -> String {
        (try? await authRepository.fetchCurrentUser())?.email ?? ""
    }

    func updateRegistrationRole(_ role: UserRole) async throws {
        try await authRepository.updateRegistrationRole(role)
    }

    func completeProfile(_ input: ProfileCompletionInput) async throws {
        try await authRepository.completeProfile(input)
    }
}
