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

    // MARK: - Settings

    static let settingsCardBackground = Color.white
    static let settingsCardText = Color.black
    static let settingsChevron = Color.gray
    static let settingsProfileAvatarPlaceholder = Color(red: 0.78, green: 0.78, blue: 0.78)
    static let settingsSortButtonBackground = postTag
    static let settingsSearchPlaceholder = Color.gray.opacity(0.45)

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

    // MARK: - Auth

    static let authBackground = Color(red: 250 / 255, green: 249 / 255, blue: 255 / 255)
    static let authHeading = Color(red: 5 / 255, green: 26 / 255, blue: 62 / 255)
    static let authBrand = Color(red: 0 / 255, green: 41 / 255, blue: 109 / 255)
    static let authPrimary = Color(red: 0 / 255, green: 61 / 255, blue: 155 / 255)
    static let authPrimaryAction = Color(red: 0 / 255, green: 82 / 255, blue: 204 / 255)
    static let authPrimaryText = authPrimaryAction
    static let authCardBackground = Color.white
    static let authCardBorder = Color(red: 195 / 255, green: 198 / 255, blue: 214 / 255).opacity(0.7)
    static let authInputBackground = Color(red: 241 / 255, green: 243 / 255, blue: 255 / 255)
    static let authInputBorder = Color(red: 196 / 255, green: 198 / 255, blue: 212 / 255)
    static let authLabel = Color(red: 67 / 255, green: 70 / 255, blue: 82 / 255)
    static let authSubtitle = Color(red: 83 / 255, green: 95 / 255, blue: 115 / 255)
    static let authPlaceholder = Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)
    static let authFooterText = Color(red: 83 / 255, green: 95 / 255, blue: 115 / 255).opacity(0.7)
    static let authDivider = Color(red: 195 / 255, green: 198 / 255, blue: 214 / 255).opacity(0.5)
    static let authSocialBorder = Color(red: 195 / 255, green: 198 / 255, blue: 214 / 255)
    static let authIconMuted = Color(red: 116 / 255, green: 119 / 255, blue: 131 / 255)
}
