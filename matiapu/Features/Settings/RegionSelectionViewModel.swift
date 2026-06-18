//
//  RegionSelectionViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class RegionSelectionViewModel {
    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            schedulePostalCodeSearch()
        }
    }

    private(set) var postalCodeResults: [PostalCodeArea] = []
    private(set) var isSearchingPostalCode = false
    private(set) var postalCodeMessage: String?

    let prefectures = Prefecture.all
    private let catalog = MunicipalityStore.shared
    private var postalCodeSearchTask: Task<Void, Never>?

    func filteredPrefectures(matching query: String) -> [Prefecture] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return prefectures }

        if PostalCodeLookup.isPostalCodeQuery(trimmed) {
            return []
        }

        if !searchMunicipalities(matching: trimmed).isEmpty {
            return []
        }

        return prefectures.filter { $0.name.contains(trimmed) }
    }

    func searchMunicipalities(matching query: String) -> [MunicipalityCatalog.MunicipalityEntry] {
        guard !PostalCodeLookup.isPostalCodeQuery(query) else { return [] }
        return catalog.searchMunicipalities(matching: query)
    }

    private func schedulePostalCodeSearch() {
        postalCodeSearchTask?.cancel()

        let query = searchText
        guard PostalCodeLookup.isPostalCodeQuery(query) else {
            postalCodeResults = []
            postalCodeMessage = nil
            isSearchingPostalCode = false
            return
        }

        let normalized = PostalCodeLookup.normalize(query)
        guard normalized.count == 7 else {
            postalCodeResults = []
            postalCodeMessage = normalized.isEmpty ? nil : PostalCodeLookupError.invalidFormat.errorDescription
            isSearchingPostalCode = false
            return
        }

        postalCodeSearchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performPostalCodeSearch(query: query)
        }
    }

    private func performPostalCodeSearch(query: String) async {
        isSearchingPostalCode = true
        postalCodeMessage = nil
        defer { isSearchingPostalCode = false }

        do {
            postalCodeResults = try await PostalCodeLookup.search(postalCode: query)
            postalCodeMessage = nil
        } catch let error as PostalCodeLookupError {
            postalCodeResults = []
            postalCodeMessage = error.errorDescription
        } catch {
            postalCodeResults = []
            postalCodeMessage = PostalCodeLookupError.serviceUnavailable.errorDescription
        }
    }
}

#if DEBUG
extension RegionSelectionViewModel {
    static var preview: RegionSelectionViewModel {
        RegionSelectionViewModel()
    }
}
#endif
