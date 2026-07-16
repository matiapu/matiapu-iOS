//
//  UserProfile.swift
//  matiapu
//

import Foundation

struct UserProfile: Hashable, Codable {
    let id: String
    let displayName: String
    let registeredArea: String
    let email: String
    let role: UserRole
    let isProfileCompleted: Bool
    let lastName: String
    let firstName: String
    let lastNameKana: String
    let firstNameKana: String
    let nickname: String
    let birthDate: String
    let address: UserAddress?
    let profileImageURL: String?

    init(
        id: String = MockMatching.demoCitizenId,
        displayName: String,
        registeredArea: String,
        email: String = "",
        role: UserRole = .citizen,
        isProfileCompleted: Bool = true,
        lastName: String = "",
        firstName: String = "",
        lastNameKana: String = "",
        firstNameKana: String = "",
        nickname: String = "",
        birthDate: String = "",
        address: UserAddress? = nil,
        profileImageURL: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.registeredArea = registeredArea
        self.email = email
        self.role = role
        self.isProfileCompleted = isProfileCompleted
        self.lastName = lastName
        self.firstName = firstName
        self.lastNameKana = lastNameKana
        self.firstNameKana = firstNameKana
        self.nickname = nickname
        self.birthDate = birthDate
        self.address = address
        self.profileImageURL = profileImageURL
    }

    var publicProfile: UserPublicProfile {
        UserPublicProfile(
            id: id,
            displayName: displayName,
            profileImageURL: profileImageURL
        )
    }

    func updating(
        displayName: String? = nil,
        registeredArea: String? = nil,
        email: String? = nil,
        nickname: String? = nil,
        address: UserAddress? = nil,
        profileImageURL: String? = nil,
        clearsProfileImageURL: Bool = false
    ) -> UserProfile {
        let resolvedDisplayName = displayName ?? self.displayName
        let resolvedNickname = nickname ?? self.nickname
        let resolvedRegisteredArea = registeredArea ?? self.registeredArea
        let resolvedProfileImageURL: String?
        if clearsProfileImageURL {
            resolvedProfileImageURL = nil
        } else {
            resolvedProfileImageURL = profileImageURL ?? self.profileImageURL
        }
        return UserProfile(
            id: id,
            displayName: resolvedDisplayName,
            registeredArea: resolvedRegisteredArea,
            email: email ?? self.email,
            role: role,
            isProfileCompleted: isProfileCompleted,
            lastName: lastName,
            firstName: firstName,
            lastNameKana: lastNameKana,
            firstNameKana: firstNameKana,
            nickname: resolvedNickname,
            birthDate: birthDate,
            address: address ?? self.address,
            profileImageURL: resolvedProfileImageURL
        )
    }

    func updatingRegisteredArea(_ area: String) -> UserProfile {
        var updatedAddress = address ?? UserAddress()
        updatedAddress.municipality = area
        return updating(registeredArea: area, address: updatedAddress)
    }
}
