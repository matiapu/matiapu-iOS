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
    private static let tagByteCount = 16

    static func chatRoomID(uid1: String, uid2: String) -> String {
        [uid1, uid2].sorted().joined(separator: "_")
    }

    static func deriveKey(roomID: String) throws -> SymmetricKey {
        guard let salt = AppSecrets.chatSalt else {
            throw ChatCryptoError.missingSalt
        }
        let material = Data((roomID + salt).utf8)
        let hash = SHA256.hash(data: material)
        return SymmetricKey(data: Data(hash))
    }

    static func encrypt(text: String, roomID: String) throws -> (encryptedContent: String, iv: String) {
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

    static func decrypt(encryptedContent: String, iv: String, roomID: String) throws -> String {
        guard
            let payload = Data(base64Encoded: encryptedContent),
            let ivData = Data(base64Encoded: iv),
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
}
