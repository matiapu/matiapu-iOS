//
//  FirestoreUserMapper.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestoreUserMapper {
    static func profile(from data: [String: Any], uid: String) -> UserProfile {
        let nickname = data[FirestoreFields.User.nickname] as? String
        let lastName = data[FirestoreFields.User.lastName] as? String ?? ""
        let firstName = data[FirestoreFields.User.firstName] as? String ?? ""
        let composedName = [lastName, firstName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let displayName = nickname?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? composedName.nilIfEmpty
            ?? "ユーザー"

        let registeredArea = registeredArea(from: data[FirestoreFields.User.address])
            ?? (data["registered_area"] as? String)
            ?? ""

        let roleRaw = data[FirestoreFields.User.role] as? String ?? UserRole.citizen.rawValue
        let role = UserRole(rawValue: roleRaw) ?? .citizen

        return UserProfile(
            id: uid,
            displayName: displayName,
            registeredArea: registeredArea,
            email: data[FirestoreFields.User.email] as? String ?? "",
            role: role
        )
    }

    static func defaultProfile(uid: String, email: String) -> [String: Any] {
        registrationProfile(uid: uid, email: email, displayName: "ユーザー")
    }

    static func registrationProfile(uid: String, email: String, displayName: String) -> [String: Any] {
        let now = FirestoreDateCodec.isoString()
        return [
            FirestoreFields.User.uid: uid,
            FirestoreFields.User.email: email,
            FirestoreFields.User.nickname: displayName,
            FirestoreFields.User.role: UserRole.citizen.rawValue,
            FirestoreFields.User.isVerified: false,
            FirestoreFields.User.isProfileCompleted: false,
            FirestoreFields.User.isRegistered: true,
            FirestoreFields.User.createdAt: now,
            FirestoreFields.User.updatedAt: now,
            "registered_area": "",
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

    private static func registeredArea(from value: Any?) -> String? {
        guard let dictionary = value as? [String: Any] else { return nil }
        let municipality = dictionary["municipality"] as? String
        let city = dictionary["city"] as? String
        let prefecture = dictionary["prefecture"] as? String

        if let municipality, !municipality.isEmpty {
            return municipality
        }
        if let city, !city.isEmpty {
            return city
        }
        if let prefecture, !prefecture.isEmpty {
            return prefecture
        }
        return nil
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
