//
//  AppColors.swift
//  matiapu
//

import SwiftUI

enum AppColors {
    // MARK: - Screen Background

    static let screenBackgroundTop = Color(red: 43 / 255, green: 188 / 255, blue: 255 / 255)
    static let screenBackgroundBottom = Color(red: 0 / 255, green: 74 / 255, blue: 153 / 255)

    static var postScreenBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [screenBackgroundTop, screenBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Post

    static let postScreenBackground = screenBackgroundTop
    static let postFABBackground = Color(red: 0.65, green: 0.84, blue: 0.95)
    static let postTag = Color(red: 1.0, green: 0.92, blue: 0.0)
    static let postCardPlaceholderTop = Color(red: 0.55, green: 0.65, blue: 0.75)
    static let postCardPlaceholderBottom = Color(red: 0.35, green: 0.45, blue: 0.55)

    static let postCardGradient: [Color] = [
        .black.opacity(0.05),
        .black.opacity(0.25),
        .black.opacity(0.65),
    ]

    static let createPostFieldBackground = Color.white
    static let createPostPlaceholder = Color.gray.opacity(0.45)
    static let createPostLocationWarning = Color(red: 1.0, green: 0.85, blue: 0.85)

    static let postDetailBackground = Color.white
    static let postDetailImageBackground = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let postDetailText = Color.black
    static let postDetailSecondaryText = Color.gray
    static let postDetailAvatarBorder = Color.black.opacity(0.08)

    // MARK: - Map

    static let mapFilterUnselected = Color.white.opacity(0.78)

    // MARK: - Semantic

    static let onImageText = Color.white
    static let onTagText = Color.black
    static let onFABIcon = Color.black
    static let avatarPlaceholder = Color.white

    // MARK: - Swipe Stamp

    static let swipeStampEmpathy = Color(red: 0.18, green: 0.78, blue: 0.44)
    static let swipeStampSkip = Color(red: 0.95, green: 0.26, blue: 0.21)
    static let swipeStampSkipDown = Color(red: 0.98, green: 0.60, blue: 0.08)
    static let swipeStampIcon = Color.white
}
