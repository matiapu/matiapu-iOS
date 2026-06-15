//
//  AppTypography.swift
//  matiapu
//

import SwiftUI

enum AppTypography {
    // MARK: - Post Card

    static let cardAuthorName = Font.system(size: 16, weight: .semibold)
    static let cardDate = Font.system(size: 14, weight: .medium)
    static let cardTitle = Font.system(size: 26, weight: .bold)
    static let cardTag = Font.system(size: 13, weight: .bold)
    static let cardBody = Font.system(size: 15)
    static let cardSeeMore = Font.system(size: 14, weight: .semibold)

    // MARK: - Post Screen

    static let fabIcon = Font.system(size: 22, weight: .bold)

    // MARK: - Create Post

    static let createPostLabel = Font.system(size: 16, weight: .semibold)
    static let createPostField = Font.system(size: 16)
    static let createPostTag = Font.system(size: 14, weight: .semibold)
    static let createPostSubmit = Font.system(size: 16, weight: .bold)

    // MARK: - Map

    static let mapFilter = Font.system(size: 15, weight: .semibold)
    static let mapCalloutTitle = Font.system(size: 18, weight: .bold)
    static let mapCalloutButton = Font.system(size: 15, weight: .semibold)

    // MARK: - Profile

    static let profileArea = Font.system(size: 16, weight: .medium)
    static let profileName = Font.system(size: 22, weight: .bold)
    static let profileSettingsIcon = Font.system(size: 22, weight: .semibold)
}
