//
//  LocalProfileImageStore.swift
//  matiapu
//

import CryptoKit
import Foundation
import UIKit

/// プロフィール画像を端末内に保持するストア。
/// オフライン表示と再表示時の即時反映のために Application Support へ保存する。
final class LocalProfileImageStore: @unchecked Sendable {
    static let shared = LocalProfileImageStore()

    private let lock = NSLock()
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    private init() {
        memoryCache.countLimit = 80
        memoryCache.totalCostLimit = 40 * 1024 * 1024
    }

    func image(forURL urlString: String) -> UIImage? {
        let key = cacheKey(forURL: urlString)
        if let memory = memoryImage(forKey: key) {
            return memory
        }
        guard let data = loadData(forKey: key), let image = UIImage(data: data) else {
            return nil
        }
        storeMemory(image, forKey: key)
        return image
    }

    func image(forUID uid: String) -> UIImage? {
        let key = uidKey(uid)
        if let memory = memoryImage(forKey: key) {
            return memory
        }
        guard let data = loadData(forKey: key), let image = UIImage(data: data) else {
            return nil
        }
        storeMemory(image, forKey: key)
        return image
    }

    func save(_ image: UIImage, forURL urlString: String, uid: String? = nil) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        save(data: data, forURL: urlString, uid: uid)
    }

    func save(data: Data, forURL urlString: String, uid: String? = nil) {
        let urlKey = cacheKey(forURL: urlString)
        write(data: data, forKey: urlKey)
        if let image = UIImage(data: data) {
            storeMemory(image, forKey: urlKey)
        }

        if let uid {
            let userKey = uidKey(uid)
            write(data: data, forKey: userKey)
            if let image = UIImage(data: data) {
                storeMemory(image, forKey: userKey)
            }
        }
    }

    func remove(forURL urlString: String) {
        let key = cacheKey(forURL: urlString)
        remove(forKey: key)
    }

    func remove(forUID uid: String) {
        remove(forKey: uidKey(uid))
    }

    // MARK: - Private

    private func memoryImage(forKey key: String) -> UIImage? {
        locked {
            memoryCache.object(forKey: key as NSString)
        }
    }

    private func storeMemory(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        locked {
            memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        }
    }

    private func loadData(forKey key: String) -> Data? {
        guard let fileURL = fileURL(forKey: key),
              fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return try? Data(contentsOf: fileURL)
    }

    private func write(data: Data, forKey key: String) {
        guard let directory = directoryURL(),
              let fileURL = fileURL(forKey: key) else {
            return
        }

        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
        excludeFromBackup(fileURL)
    }

    private func remove(forKey key: String) {
        locked {
            memoryCache.removeObject(forKey: key as NSString)
        }
        guard let fileURL = fileURL(forKey: key) else { return }
        try? fileManager.removeItem(at: fileURL)
    }

    private func cacheKey(forURL urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let digest = SHA256.hash(data: Data(trimmed.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func uidKey(_ uid: String) -> String {
        "uid_\(uid)"
    }

    private func directoryURL() -> URL? {
        guard let support = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        return support.appendingPathComponent("profile_images", isDirectory: true)
    }

    private func fileURL(forKey key: String) -> URL? {
        directoryURL()?.appendingPathComponent("\(key).jpg")
    }

    private func excludeFromBackup(_ fileURL: URL) {
        var url = fileURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
