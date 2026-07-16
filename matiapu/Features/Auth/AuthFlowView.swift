//
//  AuthFlowView.swift
//  matiapu
//

import SwiftUI

struct AuthFlowView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var screen: AuthScreen = .login

    var body: some View {
        Group {
            switch screen {
            case .login:
                LoginView(
                    viewModel: viewModel,
                    onSignUp: { screen = .signUp },
                    onForgotPassword: { screen = .forgotPassword }
                )
            case .signUp:
                SignUpView(
                    viewModel: viewModel,
                    onLogin: { screen = .login }
                )
            case .forgotPassword:
                ForgotPasswordView(
                    viewModel: viewModel,
                    onBack: { screen = .login }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: screen)
    }
}
