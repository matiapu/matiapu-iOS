//
//  AuthViewModel.swift
//  matiapu
//

import FirebaseAuth
import Foundation
import Observation

enum AuthPhase: Equatable {
    case loading
    case unauthenticated
    case needsEmailVerification(displayName: String)
    case authenticated
}

enum AuthScreen: Hashable {
    case login
    case signUp
    case forgotPassword
}

@Observable
@MainActor
final class AuthViewModel {
    private(set) var phase: AuthPhase = .loading
    private(set) var isProcessing = false
    var errorMessage: String?

    private let authRepository: any AuthRepository
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    func start() {
        guard FirebaseBootstrap.isConfigured else {
            phase = .authenticated
            return
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.refreshPhase(for: user)
            }
        }
        refreshPhase(for: Auth.auth().currentUser)
    }

    func stop() {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    func signIn(email: String, password: String) async {
        await perform {
            try await authRepository.signIn(email: email, password: password)
        }
    }

    func signUp(displayName: String, email: String, password: String) async {
        await perform {
            try await authRepository.signUp(displayName: displayName, email: email, password: password)
            if let name = authRepository.pendingVerificationDisplayName {
                phase = .needsEmailVerification(displayName: name)
            }
        }
    }

    func signInWithGoogle() async {
        await perform {
            try await authRepository.signInWithGoogle()
        }
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async {
        await perform {
            try await authRepository.signInWithApple(
                idToken: idToken,
                nonce: nonce,
                fullName: fullName
            )
        }
    }

    func sendPasswordReset(email: String) async -> Bool {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try await authRepository.sendPasswordReset(to: email)
            return true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func resendVerificationEmail() async {
        await perform {
            try await authRepository.sendEmailVerification()
        }
    }

    func verifyEmail() async -> Bool {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let verified = try await authRepository.reloadAndCheckEmailVerified()
            refreshPhase(for: Auth.auth().currentUser)
            return verified
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signOut() async {
        errorMessage = nil
        try? await authRepository.signOut()
        phase = .unauthenticated
    }

    private func refreshPhase(for user: User?) {
        guard FirebaseBootstrap.isConfigured else {
            phase = .authenticated
            return
        }

        guard let user else {
            phase = .unauthenticated
            return
        }

        if FirebaseAuthSession.needsEmailVerification(user: user) {
            let displayName = authRepository.pendingVerificationDisplayName
                ?? user.displayName
                ?? "ユーザー"
            phase = .needsEmailVerification(displayName: displayName)
            return
        }

        phase = .authenticated
    }

    private func perform(_ operation: () async throws -> Void) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try await operation()
            refreshPhase(for: Auth.auth().currentUser)
        } catch let error as AuthError {
            if case .emailNotVerified = error,
               let name = authRepository.pendingVerificationDisplayName {
                phase = .needsEmailVerification(displayName: name)
                return
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
extension AuthViewModel {
    static var preview: AuthViewModel {
        let viewModel = AuthViewModel(authRepository: MockAuthRepository())
        viewModel.phase = .unauthenticated
        return viewModel
    }
}
#endif
