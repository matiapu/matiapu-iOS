//
//  SignInWithAppleButton.swift
//  matiapu
//

import AuthenticationServices
import SwiftUI
import UIKit

struct AppleSignInButton: View {
    @Bindable var viewModel: AuthViewModel
    @State private var currentNonce: String?

    var body: some View {
        SignInWithAppleButtonViewRepresentable(
            onRequest: { request in
                let nonce = AppleSignInHelper.randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleSignInHelper.sha256(nonce)
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    guard
                        let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                        let tokenData = credential.identityToken,
                        let idToken = String(data: tokenData, encoding: .utf8),
                        let nonce = currentNonce
                    else {
                        viewModel.errorMessage = "Apple サインインに失敗しました。"
                        return
                    }

                    let fullName = [
                        credential.fullName?.familyName,
                        credential.fullName?.givenName,
                    ]
                    .compactMap { $0 }
                    .joined(separator: " ")

                    Task {
                        await viewModel.signInWithApple(
                            idToken: idToken,
                            nonce: nonce,
                            fullName: fullName.nilIfEmpty
                        )
                    }
                case .failure(let error):
                    if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
        )
        .frame(height: AppSize.authSocialButtonHeight)
    }
}

private struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = AppSize.authSocialButtonHeight / 2
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleTap),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void

        init(
            onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
            onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
        ) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func handleTap() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            onRequest(request)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithAuthorization authorization: ASAuthorization
        ) {
            onCompletion(.success(authorization))
        }

        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithError error: Error
        ) {
            onCompletion(.failure(error))
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            UIApplication.shared.presentationAnchor
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
