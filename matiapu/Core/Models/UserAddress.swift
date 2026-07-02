//
//  UserAddress.swift
//  matiapu
//

import Foundation

nonisolated struct UserAddress: Hashable, Codable {
    var postalCode: String
    var prefecture: String
    var municipality: String
    var streetAddress: String
    var building: String?

    init(
        postalCode: String = "",
        prefecture: String = "",
        municipality: String = "",
        streetAddress: String = "",
        building: String? = nil
    ) {
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.municipality = municipality
        self.streetAddress = streetAddress
        self.building = building
    }

    var displayMunicipality: String {
        municipality.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFilled: Bool {
        !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prefecture.isEmpty
            && !municipality.isEmpty
            && !streetAddress.isEmpty
    }
}
