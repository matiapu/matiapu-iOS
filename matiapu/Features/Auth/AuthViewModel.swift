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
    case needsProfileRegistration(role: UserRole, needsAccountTypeSelection: Bool)
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

    private let authenticate: AuthenticateUseCase
    private let manageAccount: ManageAccountUseCase
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init(useCases: AppUseCases) {
        self.authenticate = useCases.authenticate
        self.manageAccount = useCases.manageAccount
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
            try await authenticate.signIn(email: email, password: password)
        }
    }

    func signUp(displayName: String, email: String, password: String, role: UserRole) async {
        await perform {
            try await authenticate.signUp(
                displayName: displayName,
                email: email,
                password: password,
                role: role
            )
            if let name = authenticate.pendingVerificationDisplayName {
                phase = .needsEmailVerification(displayName: name)
            }
        }
    }

    func markProfileRegistrationComplete() {
        phase = .authenticated
    }

    func signInWithGoogle() async {
        await perform {
            try await authenticate.signInWithGoogle()
        }
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async {
        await perform {
            try await authenticate.signInWithApple(
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
            try await manageAccount.sendPasswordReset(to: email)
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
            try await manageAccount.sendEmailVerification()
        }
    }

    func verifyEmail() async -> Bool {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let verified = try await manageAccount.reloadAndCheckEmailVerified()
            if verified, let user = Auth.auth().currentUser {
                await refreshProfileCompletionPhase(for: user)
            } else {
                refreshPhase(for: Auth.auth().currentUser)
            }
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
        try? await manageAccount.signOut()
        phase = .unauthenticated
    }

    func deleteAccount() async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try await manageAccount.deleteAccount()
            phase = .unauthenticated
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
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
            let displayName = authenticate.pendingVerificationDisplayName
                ?? user.displayName
                ?? "ユーザー"
            phase = .needsEmailVerification(displayName: displayName)
            return
        }

        Task {
            await refreshProfileCompletionPhase(for: user)
        }
    }

    private func refreshProfileCompletionPhase(for user: User) async {
        guard let profile = try? await manageAccount.fetchCurrentUser() else {
            phase = .authenticated
            return
        }

        guard !profile.isProfileCompleted else {
            phase = .authenticated
            return
        }

        let providers = user.providerData.map(\.providerID)
        let isSocialProvider = providers.contains(where: {
            $0 == "google.com" || $0 == "apple.com"
        })

        phase = .needsProfileRegistration(
            role: profile.role,
            needsAccountTypeSelection: isSocialProvider
        )
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
               let name = authenticate.pendingVerificationDisplayName {
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
        let viewModel = AuthViewModel(useCases: AppUseCases.make(from: .live))
        viewModel.phase = .unauthenticated
        return viewModel
    }
}
#endif
