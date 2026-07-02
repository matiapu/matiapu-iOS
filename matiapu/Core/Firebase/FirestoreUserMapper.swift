//
//  FirestoreUserMapper.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestoreUserMapper {
    static func profile(from data: [String: Any], uid: String) -> UserProfile {
        let nickname = data[FirestoreFields.User.nickname] as? String ?? ""
        let lastName = data[FirestoreFields.User.lastName] as? String ?? ""
        let firstName = data[FirestoreFields.User.firstName] as? String ?? ""
        let composedName = [lastName, firstName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let storeName = data[FirestoreFields.User.storeName] as? String ?? ""
        let displayName = nickname.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? storeName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? composedName.nilIfEmpty
            ?? "ユーザー"

        let address = address(from: data[FirestoreFields.User.address])
        let registeredArea = address?.displayMunicipality.nilIfEmpty
            ?? municipalityOnly(from: data["registered_area"] as? String)
            ?? ""

        let roleRaw = data[FirestoreFields.User.role] as? String ?? UserRole.citizen.rawValue
        let role = UserRole(rawValue: roleRaw) ?? .citizen

        return UserProfile(
            id: uid,
            displayName: displayName,
            registeredArea: registeredArea,
            email: data[FirestoreFields.User.email] as? String ?? "",
            role: role,
            isProfileCompleted: data[FirestoreFields.User.isProfileCompleted] as? Bool ?? false,
            lastName: lastName,
            firstName: firstName,
            lastNameKana: data[FirestoreFields.User.lastNameKana] as? String ?? "",
            firstNameKana: data[FirestoreFields.User.firstNameKana] as? String ?? "",
            nickname: nickname,
            birthDate: data[FirestoreFields.User.birthDate] as? String ?? "",
            address: address,
            profileImageURL: profileImageURL(from: data)
        )
    }

    static func publicProfile(from data: [String: Any], uid: String) -> UserPublicProfile {
        FirestoreUserPublicProfileMapper.map(from: data, uid: uid)
    }

    static func profileImageURL(from data: [String: Any]) -> String? {
        guard let dictionary = data[FirestoreFields.User.profileImage] as? [String: Any],
              let url = dictionary["url"] as? String else {
            return nil
        }
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func defaultProfile(uid: String, email: String) -> [String: Any] {
        registrationProfile(uid: uid, email: email, displayName: "ユーザー", role: .citizen)
    }

    static func registrationProfile(
        uid: String,
        email: String,
        displayName: String,
        role: UserRole = .citizen
    ) -> [String: Any] {
        let now = FirestoreDateCodec.isoString()
        return [
            FirestoreFields.User.uid: uid,
            FirestoreFields.User.email: email,
            FirestoreFields.User.nickname: displayName,
            FirestoreFields.User.role: role.rawValue,
            FirestoreFields.User.isVerified: false,
            FirestoreFields.User.isProfileCompleted: false,
            FirestoreFields.User.isRegistered: true,
            FirestoreFields.User.createdAt: now,
            FirestoreFields.User.updatedAt: now,
            "registered_area": "",
        ]
    }

    static func profileCompletionPayload(
        _ input: ProfileCompletionInput,
        profileImageURL: String?
    ) -> [String: Any] {
        var payload: [String: Any] = [
            FirestoreFields.User.role: input.role.rawValue,
            FirestoreFields.User.isProfileCompleted: true,
            FirestoreFields.User.updatedAt: FirestoreDateCodec.isoString(),
        ]

        switch input {
        case .citizen(let citizen):
            payload[FirestoreFields.User.lastName] = citizen.lastName
            payload[FirestoreFields.User.firstName] = citizen.firstName
            payload[FirestoreFields.User.lastNameKana] = citizen.lastNameKana
            payload[FirestoreFields.User.firstNameKana] = citizen.firstNameKana
            payload[FirestoreFields.User.nickname] = citizen.nickname
            payload[FirestoreFields.User.birthDate] = citizen.birthDate
            payload[FirestoreFields.User.address] = addressDictionary(citizen.address)
            payload["registered_area"] = citizen.address.displayMunicipality
        case .store(let store):
            payload[FirestoreFields.User.storeName] = store.storeName
            payload[FirestoreFields.User.storeDescription] = store.storeDescription
            payload[FirestoreFields.User.phoneNumber] = store.phoneNumber
            payload[FirestoreFields.User.nickname] = store.storeName
            payload[FirestoreFields.User.address] = addressDictionary(store.address)
            payload["registered_area"] = store.address.displayMunicipality
        case .legislator(let legislator):
            payload[FirestoreFields.User.lastName] = legislator.lastName
            payload[FirestoreFields.User.firstName] = legislator.firstName
            payload[FirestoreFields.User.lastNameKana] = legislator.lastNameKana
            payload[FirestoreFields.User.firstNameKana] = legislator.firstNameKana
            payload[FirestoreFields.User.politicalParty] = legislator.politicalParty
            payload[FirestoreFields.User.manifesto] = legislator.manifesto
            payload[FirestoreFields.User.nickname] = [legislator.lastName, legislator.firstName]
                .joined(separator: " ")
            payload[FirestoreFields.User.address] = addressDictionary(legislator.address)
            payload["registered_area"] = legislator.address.displayMunicipality
        }

        if let profileImageURL {
            payload[FirestoreFields.User.profileImage] = ["url": profileImageURL]
        }

        return payload
    }

    static func roleUpdate(_ role: UserRole) -> [String: Any] {
        [
            FirestoreFields.User.role: role.rawValue,
            FirestoreFields.User.updatedAt: FirestoreDateCodec.isoString(),
        ]
    }

    static func displayNameUpdate(_ name: String) -> [String: Any] {
        [
            FirestoreFields.User.nickname: name,
            FirestoreFields.User.updatedAt: FirestoreDateCodec.isoString(),
        ]
    }

    static func registeredAreaUpdate(_ area: String) -> [String: Any] {
        [
            "registered_area": area,
            FirestoreFields.User.address: [
                "municipality": area,
            ],
            FirestoreFields.User.updatedAt: FirestoreDateCodec.isoString(),
        ]
    }

    static func emailUpdate(_ email: String) -> [String: Any] {
        [
            FirestoreFields.User.email: email,
            FirestoreFields.User.updatedAt: FirestoreDateCodec.isoString(),
        ]
    }

    static func address(from value: Any?) -> UserAddress? {
        guard let dictionary = value as? [String: Any] else { return nil }

        let postalCode = dictionary["postalCode"] as? String
            ?? dictionary["postal_code"] as? String
            ?? ""
        let prefecture = dictionary["prefecture"] as? String ?? ""
        let municipality = dictionary["municipality"] as? String
            ?? dictionary["city"] as? String
            ?? ""
        let streetAddress = dictionary["streetAddress"] as? String
            ?? dictionary["street_address"] as? String
            ?? ""
        let building = dictionary["building"] as? String

        if postalCode.isEmpty, prefecture.isEmpty, municipality.isEmpty, streetAddress.isEmpty {
            if let municipalityOnly = dictionary["municipality"] as? String, !municipalityOnly.isEmpty {
                return UserAddress(municipality: municipalityOnly)
            }
            return nil
        }

        return UserAddress(
            postalCode: postalCode,
            prefecture: prefecture,
            municipality: municipality,
            streetAddress: streetAddress,
            building: building
        )
    }

    private static func addressDictionary(_ address: UserAddress) -> [String: Any] {
        var dictionary: [String: Any] = [
            "postalCode": address.postalCode,
            "prefecture": address.prefecture,
            "municipality": address.municipality,
            "streetAddress": address.streetAddress,
        ]
        if let building = address.building?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
            dictionary["building"] = building
        }
        return dictionary
    }

    private static func municipalityOnly(from registeredArea: String?) -> String? {
        guard let registeredArea else { return nil }
        return MunicipalityStore.shared.resolveMunicipalityName(from: registeredArea)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
