//
//  ChatCrypto.swift
//  matiapu
//

import CryptoKit
import Foundation

enum ChatCryptoError: LocalizedError {
    case missingSalt
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .missingSalt:
            return "チャット暗号化用のソルトが設定されていません。"
        case .invalidPayload:
            return "メッセージの復号に失敗しました。"
        }
    }
}

enum ChatCrypto {
    private nonisolated static let tagByteCount = 16
    private nonisolated(unsafe) static var configuredSalt: String?

    nonisolated static let undecryptableMessageText = "🔒 [復号化に失敗した暗号メッセージ]"

    nonisolated static var isSaltConfigured: Bool {
        resolvedSalt() != nil
    }

    static func configure(chatSalt: String?) {
        configuredSalt = chatSalt
    }

    nonisolated static func chatRoomID(uid1: String, uid2: String) -> String {
        [uid1, uid2].sorted().joined(separator: "_")
    }

    nonisolated static func deriveKey(roomID: String) throws -> SymmetricKey {
        guard let salt = resolvedSalt() else {
            throw ChatCryptoError.missingSalt
        }
        let material = Data((roomID + salt).utf8)
        let hash = SHA256.hash(data: material)
        return SymmetricKey(data: Data(hash))
    }

    nonisolated static func encrypt(text: String, roomID: String) throws -> (encryptedContent: String, iv: String) {
        let key = try deriveKey(roomID: roomID)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(Data(text.utf8), using: key, nonce: nonce)

        var payload = Data(sealed.ciphertext)
        payload.append(sealed.tag)

        return (
            encryptedContent: payload.base64EncodedString(),
            iv: Data(nonce).base64EncodedString()
        )
    }

    nonisolated static func decrypt(encryptedContent: String, iv: String, roomID: String) throws -> String {
        guard
            let payload = decodeBase64(encryptedContent),
            let ivData = decodeBase64(iv),
            payload.count > tagByteCount
        else {
            throw ChatCryptoError.invalidPayload
        }

        let key = try deriveKey(roomID: roomID)
        let nonce = try AES.GCM.Nonce(data: ivData)
        let ciphertext = payload.prefix(payload.count - tagByteCount)
        let tag = payload.suffix(tagByteCount)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let decrypted = try AES.GCM.open(sealedBox, using: key)

        guard let text = String(data: decrypted, encoding: .utf8) else {
            throw ChatCryptoError.invalidPayload
        }
        return text
    }

    nonisolated static func decryptMessage(
        encryptedContent: String,
        iv: String,
        roomID: String
    ) -> String {
        (try? decrypt(encryptedContent: encryptedContent, iv: iv, roomID: roomID))
            ?? undecryptableMessageText
    }

    nonisolated private static func resolvedSalt() -> String? {
        if let configuredSalt {
            let trimmed = configuredSalt.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.contains("$(") {
                return trimmed
            }
        }

        if let envSalt = ProcessInfo.processInfo.environment["CHAT_SALT"] {
            let trimmed = envSalt.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.contains("$(") {
                return trimmed
            }
        }

        return nil
    }

    nonisolated private static func decodeBase64(_ value: String) -> Data? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let data = Data(base64Encoded: trimmed) {
            return data
        }

        var normalized = trimmed
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = normalized.count % 4
        if remainder > 0 {
            normalized.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: normalized)
    }
}
