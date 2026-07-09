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
    private nonisolated static let nonceByteCount = 12
    /// Web の `NEXT_PUBLIC_CHAT_SALT` 未設定時と同じフォールバック値
    private nonisolated static let defaultSalt = "matiapu_chat_secure_salt_2026"
    /// 過去に `Secrets.xcconfig` へ誤って設定されていた値（復号フォールバック専用）
    private nonisolated static let legacySalts = [
        "AIzaSyCaZJPQyp1jbmq7jkWG2CMBrVL1iq2Cg3E",
    ]
    private nonisolated(unsafe) static var configuredSalt: String?

    nonisolated static let undecryptableMessageText = "（メッセージを表示できません）"

    /// Web `chatDb.ts` の `deriveRoomKey` と同じ結合順
    private nonisolated enum KeyMaterialStyle: CaseIterable {
        case roomIDUnderscoreSalt
        case roomIDSalt
        case saltRoomID

        nonisolated func material(roomID: String, salt: String) -> String {
            switch self {
            case .roomIDUnderscoreSalt:
                return roomID + "_" + salt
            case .roomIDSalt:
                return roomID + salt
            case .saltRoomID:
                return salt + roomID
            }
        }
    }

    nonisolated static var isSaltConfigured: Bool {
        resolvedSalt() != nil
    }

    static func configure(chatSalt: String?) {
        configuredSalt = chatSalt
    }

    nonisolated static func isUndecryptableDisplayText(_ text: String) -> Bool {
        text == undecryptableMessageText
    }

    nonisolated static func chatRoomID(uid1: String, uid2: String) -> String {
        [uid1, uid2].sorted().joined(separator: "_")
    }

    nonisolated static func deriveKey(roomID: String) throws -> SymmetricKey {
        guard let salt = resolvedSalt() else {
            throw ChatCryptoError.missingSalt
        }
        return deriveKey(roomID: roomID, salt: salt, style: .roomIDUnderscoreSalt)
    }

    nonisolated static func encrypt(text: String, roomID: String) throws -> (encryptedContent: String, iv: String) {
        let key = try deriveKey(roomID: roomID)
        let sealed = try AES.GCM.seal(Data(text.utf8), using: key)
        guard let combined = sealed.combined else {
            throw ChatCryptoError.invalidPayload
        }

        return (
            encryptedContent: combined.base64EncodedString(),
            iv: Data(sealed.nonce).base64EncodedString()
        )
    }

    nonisolated static func decrypt(encryptedContent: String, iv: String, roomID: String) throws -> String {
        guard
            let payload = decodeBase64(encryptedContent),
            let ivData = decodeBase64(iv),
            !ivData.isEmpty
        else {
            throw ChatCryptoError.invalidPayload
        }

        for salt in candidateSalts() {
            for style in KeyMaterialStyle.allCases {
                let key = deriveKey(roomID: roomID, salt: salt, style: style)

                // Web: encrypted_content = ciphertext + tag, iv = nonce
                if let text = try? openCombinedSealedBox(payload: ivData + payload, key: key) {
                    return text
                }

                // iOS: encrypted_content = nonce + ciphertext + tag
                if let text = try? openCombinedSealedBox(payload: payload, key: key) {
                    return text
                }

                // 旧 iOS: ciphertext + tag を iv と手動結合
                if payload.count > tagByteCount,
                   let text = try? openSplitPayload(ivData: ivData, payload: payload, key: key) {
                    return text
                }
            }
        }

        throw ChatCryptoError.invalidPayload
    }

    nonisolated static func decryptMessage(
        encryptedContent: String,
        iv: String,
        roomID: String
    ) -> String {
        (try? decrypt(encryptedContent: encryptedContent, iv: iv, roomID: roomID))
            ?? undecryptableMessageText
    }

    nonisolated private static func deriveKey(
        roomID: String,
        salt: String,
        style: KeyMaterialStyle
    ) -> SymmetricKey {
        let material = style.material(roomID: roomID, salt: salt)
        let hash = SHA256.hash(data: Data(material.utf8))
        return SymmetricKey(data: Data(hash))
    }

    nonisolated private static func openSplitPayload(
        ivData: Data,
        payload: Data,
        key: SymmetricKey
    ) throws -> String {
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

    nonisolated private static func openCombinedSealedBox(payload: Data, key: SymmetricKey) throws -> String {
        let minimumCombinedLength = nonceByteCount + tagByteCount + 1
        guard payload.count >= minimumCombinedLength else {
            throw ChatCryptoError.invalidPayload
        }

        let sealedBox = try AES.GCM.SealedBox(combined: payload)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        guard let text = String(data: decrypted, encoding: .utf8) else {
            throw ChatCryptoError.invalidPayload
        }
        return text
    }

    nonisolated private static func resolvedSalt() -> String? {
        candidateSalts().first
    }

    nonisolated private static func candidateSalts() -> [String] {
        var salts: [String] = []

        func appendUnique(_ candidate: String?) {
            guard let candidate else { return }
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.contains("$("), !salts.contains(trimmed) else { return }
            salts.append(trimmed)
        }

        appendUnique(configuredSalt)
        appendUnique(ProcessInfo.processInfo.environment["CHAT_SALT"])
        appendUnique(defaultSalt)
        for legacySalt in legacySalts {
            appendUnique(legacySalt)
        }
        return salts
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
