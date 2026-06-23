//
//  AppSecrets.swift
//  matiapu
//

import Foundation

enum AppSecrets {
    static var chatSalt: String? {
        resolvedValue(forInfoKey: "CHAT_SALT", envKey: "CHAT_SALT")
    }

    private static func resolvedValue(forInfoKey infoKey: String, envKey: String) -> String? {
        let candidates = [
            Bundle.main.object(forInfoDictionaryKey: infoKey) as? String,
            ProcessInfo.processInfo.environment[envKey],
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
