//
//  ProfileRegistrationFlowView.swift
//  matiapu
//

import SwiftUI

struct ProfileRegistrationFlowView: View {
    @Bindable var authViewModel: AuthViewModel
    let role: UserRole
    var needsAccountTypeSelection: Bool

    @State private var registrationViewModel: ProfileRegistrationViewModel
    @State private var showsAccountTypeSelection: Bool

    init(
        authViewModel: AuthViewModel,
        role: UserRole,
        needsAccountTypeSelection: Bool,
        dependencies: AppDependencies
    ) {
        self.authViewModel = authViewModel
        self.role = role
        self.needsAccountTypeSelection = needsAccountTypeSelection
        _registrationViewModel = State(
            initialValue: AppViewModelFactory.profileRegistration(
                role: role,
                dependencies: dependencies
            )
        )
        _showsAccountTypeSelection = State(initialValue: needsAccountTypeSelection)
    }

    var body: some View {
        Group {
            if registrationViewModel.didComplete {
                ProfileRegistrationCompleteView {
                    authViewModel.markProfileRegistrationComplete()
                }
            } else if showsAccountTypeSelection {
                AccountTypeSelectionView(
                    viewModel: registrationViewModel,
                    onBack: backToLogin,
                    onSelected: {
                        showsAccountTypeSelection = false
                    }
                )
            } else {
                registrationForm
            }
        }
        .task {
            await registrationViewModel.loadEmail()
        }
    }

    @ViewBuilder
    private var registrationForm: some View {
        switch registrationViewModel.role {
        case .citizen:
            CitizenProfileRegistrationView(
                viewModel: registrationViewModel,
                onBack: backFromProfileForm
            )
        case .store:
            StoreProfileRegistrationView(
                viewModel: registrationViewModel,
                onBack: backFromProfileForm
            )
        case .legislator:
            LegislatorProfileRegistrationView(
                viewModel: registrationViewModel,
                onBack: backFromProfileForm
            )
        }
    }

    private func backFromProfileForm() {
        if needsAccountTypeSelection {
            showsAccountTypeSelection = true
        } else {
            backToLogin()
        }
    }

    private func backToLogin() {
        Task { await authViewModel.signOut() }
    }
}
