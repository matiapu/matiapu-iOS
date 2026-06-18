//
//  UserProfile.swift
//  matiapu
//

import Foundation

struct UserProfile: Hashable {
    let id: String
    let displayName: String
    let registeredArea: String
    let email: String
    let role: UserRole

    init(
        id: String = MockMatching.demoCitizenId,
        displayName: String,
        registeredArea: String,
        email: String = "",
        role: UserRole = .citizen
    ) {
        self.id = id
        self.displayName = displayName
        self.registeredArea = registeredArea
        self.email = email
        self.role = role
    }
}
