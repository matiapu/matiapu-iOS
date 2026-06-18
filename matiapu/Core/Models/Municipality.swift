//
//  Municipality.swift
//  matiapu
//

import Foundation

struct Municipality: Identifiable, Hashable, Codable {
    let id: String
    let name: String
}

struct PrefectureMunicipalities: Codable {
    let name: String
    let municipalities: [Municipality]
}

private struct MunicipalityCatalogPayload: Codable {
    let prefectures: [PrefectureMunicipalities]
}

struct MunicipalityCatalog {
    let prefectures: [PrefectureMunicipalities]
    private let municipalitiesByPrefecture: [String: [Municipality]]
    private let allMunicipalities: [MunicipalityEntry]

    struct MunicipalityEntry: Hashable {
        let municipality: Municipality
        let prefectureName: String
    }

    static let empty = MunicipalityCatalog(prefectures: [])

    init(prefectures: [PrefectureMunicipalities]) {
        self.prefectures = prefectures
        self.municipalitiesByPrefecture = Dictionary(
            uniqueKeysWithValues: prefectures.map { ($0.name, $0.municipalities) }
        )
        self.allMunicipalities = prefectures.flatMap { prefecture in
            prefecture.municipalities.map {
                MunicipalityEntry(municipality: $0, prefectureName: prefecture.name)
            }
        }
    }

    func municipalities(for prefectureName: String) -> [Municipality] {
        municipalitiesByPrefecture[prefectureName] ?? []
    }

    func searchMunicipalities(matching query: String) -> [MunicipalityEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return allMunicipalities.filter {
            $0.municipality.name.contains(trimmed) || $0.prefectureName.contains(trimmed)
        }
    }
}

enum MunicipalityStore {
    static let shared: MunicipalityCatalog = {
        guard
            let url = Bundle.main.url(forResource: "municipalities", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(MunicipalityCatalogPayload.self, from: data)
        else {
            return .empty
        }
        return MunicipalityCatalog(prefectures: payload.prefectures)
    }()
}
