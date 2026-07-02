//
//  MunicipalityBoundaryLoader.swift
//  matiapu
//

import Foundation

actor MunicipalityBoundaryLoader {
    static let shared = MunicipalityBoundaryLoader()

    private var memoryCache: [String: MunicipalityBoundary] = [:]

    func loadBoundary(municipalityName: String) async -> MunicipalityBoundary? {
        let trimmed = municipalityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard let entry = await municipalityEntry(for: trimmed) else {
            return nil
        }

        return await loadBoundary(municipalityId: entry.municipality.id)
    }

    func loadBoundary(municipalityId: String) async -> MunicipalityBoundary? {
        if let cached = memoryCache[municipalityId] {
            return cached
        }

        if let bundled = await loadBundledBoundary(municipalityId: municipalityId) {
            memoryCache[municipalityId] = bundled
            return bundled
        }

        if let cachedFile = loadCachedBoundary(municipalityId: municipalityId) {
            memoryCache[municipalityId] = cachedFile
            return cachedFile
        }

        guard let remote = await downloadBoundary(municipalityId: municipalityId) else {
            return nil
        }

        memoryCache[municipalityId] = remote
        return remote
    }

    private func municipalityEntry(for name: String) async -> MunicipalityCatalog.MunicipalityEntry? {
        await MainActor.run {
            MunicipalityStore.shared.entry(forMunicipality: name)
        }
    }

    private func loadBundledBoundary(municipalityId: String) async -> MunicipalityBoundary? {
        guard let codes = MunicipalityBoundaryResourceCodes(municipalityId: municipalityId) else { return nil }

        let candidates: [(resource: String, subdirectory: String?)] = [
            (codes.cityCode, "municipality_boundaries/\(codes.prefectureCode)"),
            (codes.cityCode, "municipality_boundaries"),
        ]

        let bundledURL = await MainActor.run { () -> URL? in
            for candidate in candidates {
                if let url = Bundle.main.url(
                    forResource: candidate.resource,
                    withExtension: "json",
                    subdirectory: candidate.subdirectory
                ) {
                    return url
                }
            }
            return nil
        }

        guard let bundledURL, let boundary = parseBoundaryFile(at: bundledURL) else {
            return nil
        }

        return boundary.simplified()
    }

    private func loadCachedBoundary(municipalityId: String) -> MunicipalityBoundary? {
        guard let fileURL = cacheFileURL(municipalityId: municipalityId),
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return parseBoundaryFile(at: fileURL)?.simplified()
    }

    private func downloadBoundary(municipalityId: String) async -> MunicipalityBoundary? {
        guard let codes = MunicipalityBoundaryResourceCodes(municipalityId: municipalityId),
              let url = codes.remoteURL else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }

            let boundary = try MunicipalityBoundaryGeoJSONParser.parse(data: data).simplified()
            if let fileURL = cacheFileURL(municipalityId: municipalityId) {
                let directory = fileURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try? data.write(to: fileURL, options: .atomic)
            }
            return boundary
        } catch {
            return nil
        }
    }

    private func parseBoundaryFile(at url: URL) -> MunicipalityBoundary? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? MunicipalityBoundaryGeoJSONParser.parse(data: data)
    }

    private func cacheFileURL(municipalityId: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return caches
            .appendingPathComponent("municipality_boundaries", isDirectory: true)
            .appendingPathComponent("\(municipalityId).json")
    }
}

private nonisolated struct MunicipalityBoundaryResourceCodes {
    let prefectureCode: String
    let cityCode: String

    init?(municipalityId: String) {
        guard municipalityId.count >= 5 else { return nil }
        prefectureCode = String(municipalityId.prefix(2))
        cityCode = String(municipalityId.prefix(5))
    }

    var remoteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/niiyz/JapanCityGeoJson/master/geojson/\(prefectureCode)/\(cityCode).json")
    }
}
