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

    func entry(forMunicipality name: String) -> MunicipalityEntry? {
        allMunicipalities.first { $0.municipality.name == name }
    }

    func searchMunicipalities(matching query: String) -> [MunicipalityEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return allMunicipalities.filter {
            $0.municipality.name.contains(trimmed) || $0.prefectureName.contains(trimmed)
        }
    }

    /// 住所文字列の先頭から市区町村名を抽出する（旧データの復元用）
    func resolveMunicipalityName(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if allMunicipalities.contains(where: { $0.municipality.name == trimmed }) {
            return trimmed
        }

        if let prefix = municipalityPrefix(in: trimmed) {
            return prefix
        }

        for prefecture in prefectures where trimmed.hasPrefix(prefecture.name) {
            let remainder = String(trimmed.dropFirst(prefecture.name.count))
            if let prefix = municipalityPrefix(in: remainder) {
                return prefix
            }
        }

        return trimmed
    }

    private func municipalityPrefix(in text: String) -> String? {
        allMunicipalities
            .map(\.municipality.name)
            .filter { text.hasPrefix($0) }
            .max(by: { $0.count < $1.count })
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
