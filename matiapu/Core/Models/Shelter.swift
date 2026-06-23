//
//  Shelter.swift
//  matiapu
//

import Foundation

struct Shelter: Identifiable, Hashable {
    let id: String
    let shelterName: String
    let latitude: Double
    let longitude: Double
    let capacity: Int?
}

struct CreateShelterInput: Sendable {
    let shelterName: String
    let latitude: Double
    let longitude: Double
    let capacity: Int?
}
