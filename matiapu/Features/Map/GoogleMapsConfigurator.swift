//
//  GoogleMapsConfigurator.swift
//  matiapu
//

import GoogleMaps

enum GoogleMapsConfigurator {
  private(set) static var isConfigured = false

  @discardableResult
  static func configureIfNeeded() -> Bool {
    guard !isConfigured else { return true }
    guard let apiKey = resolvedAPIKey() else {
      return false
    }

    GMSServices.provideAPIKey(apiKey)
    isConfigured = true
    return true
  }

  private static func resolvedAPIKey() -> String? {
    let candidates = [
      Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
    ]

    for candidate in candidates {
      guard let candidate else { continue }
      let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty, !trimmed.contains("$(") else { continue }
      return trimmed
    }
    return nil
  }
}
