//
//  SettingsDestination.swift
//  matiapu
//

import Foundation

enum SettingsDestination: Hashable {
    case accountSettings
    case usernameEdit
    case emailPasswordEdit
    case regionSelection
    case municipalitySelection(prefectureName: String)
    case likedPosts
    case notifications
    case notificationDetail(notificationId: String)
}
