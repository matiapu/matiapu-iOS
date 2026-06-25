//
//  UIApplication+RootViewController.swift
//  matiapu
//

import UIKit

extension UIApplication {
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostViewController
    }

    /// Sign in with Apple 等の認証 UI 表示用アンカー
    var presentationAnchor: UIWindow {
        if let keyWindow = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) {
            return keyWindow
        }

        let windowScene = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? connectedScenes.compactMap { $0 as? UIWindowScene }.first

        guard let windowScene else {
            preconditionFailure("No UIWindowScene available for presentation")
        }

        return windowScene.windows.first ?? UIWindow(windowScene: windowScene)
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        if let navigation = self as? UINavigationController, let visible = navigation.visibleViewController {
            return visible.topMostViewController
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController
        }
        return self
    }
}
