//
//  PostalCodeLookup.swift
//  matiapu
//

import Foundation

struct PostalCodeArea: Hashable, Identifiable {
    let prefecture: String
    let area: String

    var id: String { "\(prefecture)-\(area)" }
}

enum PostalCodeLookupError: LocalizedError {
    case invalidFormat
    case notFound
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "7桁の郵便番号を入力してください"
        case .notFound:
            return "該当する住所が見つかりませんでした"
        case .serviceUnavailable:
            return "郵便番号の検索に失敗しました。通信環境を確認してください"
        }
    }
}

enum PostalCodeLookup {
    private struct APIResponse: Decodable {
        let message: String?
        let results: [APIResult]?
        let status: Int
    }

    private struct APIResult: Decodable {
        let address1: String
        let address2: String
        let zipcode: String
    }

    // オフライン時のフォールバック
    private static let localEntries: [String: PostalCodeArea] = [
        "1600022": PostalCodeArea(prefecture: "東京都", area: "新宿区"),
        "1600023": PostalCodeArea(prefecture: "東京都", area: "新宿区"),
        "1500001": PostalCodeArea(prefecture: "東京都", area: "渋谷区"),
        "0600001": PostalCodeArea(prefecture: "北海道", area: "札幌市中央区"),
        "5300001": PostalCodeArea(prefecture: "大阪府", area: "大阪市北区"),
    ]

    static func normalize(_ postalCode: String) -> String {
        postalCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
    }

    static func isPostalCodeQuery(_ query: String) -> Bool {
        let normalized = normalize(query)
        return !normalized.isEmpty && normalized.allSatisfy(\.isNumber)
    }

    static func search(postalCode: String) async throws -> [PostalCodeArea] {
        let normalized = normalize(postalCode)
        guard normalized.count == 7, normalized.allSatisfy(\.isNumber) else {
            throw PostalCodeLookupError.invalidFormat
        }

        if let local = localEntries[normalized] {
            return [local]
        }

        do {
            let results = try await fetchFromZipCloud(normalized)
            if results.isEmpty {
                throw PostalCodeLookupError.notFound
            }
            return results
        } catch let error as PostalCodeLookupError {
            throw error
        } catch {
            if let local = localEntries[normalized] {
                return [local]
            }
            throw PostalCodeLookupError.serviceUnavailable
        }
    }

    private static func fetchFromZipCloud(_ normalized: String) async throws -> [PostalCodeArea] {
        var components = URLComponents(string: "https://zipcloud.ibsnet.co.jp/api/search")
        components?.queryItems = [URLQueryItem(name: "zipcode", value: normalized)]

        guard let url = components?.url else {
            throw PostalCodeLookupError.serviceUnavailable
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PostalCodeLookupError.serviceUnavailable
        }

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        guard decoded.status == 200, let results = decoded.results, !results.isEmpty else {
            return []
        }

        var seen = Set<String>()
        return results.compactMap { result in
            let area = result.address2
            let key = "\(result.address1)-\(area)"
            guard seen.insert(key).inserted else { return nil }
            return PostalCodeArea(prefecture: result.address1, area: area)
        }
    }
}
