//
//  RootView.swift
//  matiapu
//

import FirebaseAuth
import GoogleSignIn
import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies
    @State private var authViewModel: AuthViewModel
    @State private var loadedViewModels: AppViewModels?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _authViewModel = State(initialValue: AppViewModelFactory.auth(dependencies: dependencies))
    }

    var body: some View {
        Group {
            if !FirebaseBootstrap.isConfigured {
                mainApp
            } else {
                switch authViewModel.phase {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.authBackground)
                case .unauthenticated:
                    AuthFlowView(viewModel: authViewModel)
                case .needsEmailVerification(let displayName):
                    EmailVerificationView(
                        viewModel: authViewModel,
                        displayName: displayName
                    )
                case .needsProfileRegistration(let role, let needsAccountTypeSelection):
                    ProfileRegistrationFlowView(
                        authViewModel: authViewModel,
                        role: role,
                        needsAccountTypeSelection: needsAccountTypeSelection,
                        dependencies: dependencies
                    )
                case .authenticated:
                    mainApp
                }
            }
        }
        .task {
            authViewModel.start()
        }
        .onDisappear {
            authViewModel.stop()
        }
        .onOpenURL { url in
            if Auth.auth().canHandle(url) {
                Task { _ = await authViewModel.verifyEmail() }
                return
            }
            GIDSignIn.sharedInstance.handle(url)
        }
    }

    @ViewBuilder
    private var mainApp: some View {
        if let loadedViewModels {
            MainTabView(
                viewModels: loadedViewModels,
                dependencies: dependencies,
                onSignOut: {
                    self.loadedViewModels = nil
                    Task { await authViewModel.signOut() }
                }
            )
        } else {
            ProgressView()
                .task {
                    loadedViewModels = AppViewModels(dependencies: dependencies)
                }
        }
    }
}

#Preview {
    RootView(dependencies: .live)
}
