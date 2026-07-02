//
//  ProfileCompletionInput.swift
//  matiapu
//

import Foundation
import UIKit

struct CitizenProfileInput {
    var lastName: String
    var firstName: String
    var lastNameKana: String
    var firstNameKana: String
    var nickname: String
    var birthDate: String
    var address: UserAddress
    var profileImage: UIImage?
}

struct StoreProfileInput {
    var storeName: String
    var storeDescription: String
    var phoneNumber: String
    var address: UserAddress
    var profileImage: UIImage?
}

struct LegislatorProfileInput {
    var lastName: String
    var firstName: String
    var lastNameKana: String
    var firstNameKana: String
    var politicalParty: String
    var manifesto: String
    var address: UserAddress
    var profileImage: UIImage?
}

enum ProfileCompletionInput {
    case citizen(CitizenProfileInput)
    case store(StoreProfileInput)
    case legislator(LegislatorProfileInput)

    var role: UserRole {
        switch self {
        case .citizen: .citizen
        case .store: .store
        case .legislator: .legislator
        }
    }

    var profileImage: UIImage? {
        switch self {
        case .citizen(let input): input.profileImage
        case .store(let input): input.profileImage
        case .legislator(let input): input.profileImage
        }
    }
}
