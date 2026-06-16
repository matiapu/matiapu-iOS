//
//  PostRepository.swift
//  matiapu
//

import Foundation
import UIKit

enum PostRepositoryError: LocalizedError {
    case missingLocation

    var errorDescription: String? {
        switch self {
        case .missingLocation:
            return "位置情報が取得できませんでした。位置情報をオンにしてから再度お試しください。"
        }
    }
}

protocol PostRepository: Sendable {
    func fetchPosts(filter: MapFilter?) async throws -> [Post]
    func fetchMatchCandidates() async throws -> [Post]
    func fetchFeaturedPost() async throws -> Post?
    func fetchFeedPosts() async throws -> [Post]
    func fetchUserPosts() async throws -> [Post]
    func recordSwipe(postId: String, action: PostSwipeAction) async throws
    func createPost(
        title: String,
        body: String,
        tag: MapFilter,
        image: UIImage,
        location: PostLocation
    ) async throws -> Post
}

final class MockPostRepository: PostRepository, @unchecked Sendable {
    private var createdPosts: [Post] = []
    private let lock = NSLock()

    func fetchPosts(filter: MapFilter?) async throws -> [Post] {
        let stored = locked { createdPosts }
        let all = PostPreviewData.mapPosts + stored
        let located = all.filter { $0.location != nil }

        guard let filter else { return located }
        return located.filter { filter.matches(post: $0) }
    }

    func fetchMatchCandidates() async throws -> [Post] {
        PostPreviewData.matchCandidates
    }

    func fetchFeaturedPost() async throws -> Post? {
        PostPreviewData.featured
    }

    func fetchFeedPosts() async throws -> [Post] {
        PostPreviewData.feedCandidates
    }

    func fetchUserPosts() async throws -> [Post] {
        let created = locked { createdPosts }
        return (created + PostPreviewData.userPosts)
            .sorted { $0.postedAt > $1.postedAt }
    }

    func recordSwipe(postId: String, action: PostSwipeAction) async throws {}

    func createPost(
        title: String,
        body: String,
        tag: MapFilter,
        image: UIImage,
        location: PostLocation
    ) async throws -> Post {
        // 撮影された写真をそのまま保持し、詳細・一覧で表示できるようにする。
        // 画質と容量のバランスを考慮して JPEG(0.8) でエンコードする。
        let imageData = image.jpegData(compressionQuality: 0.8)

        let post = Post(
            id: UUID().uuidString,
            authorName: "あなた",
            tag: tag.title,
            title: title,
            body: body,
            postedAt: .now,
            imageName: nil,
            imageData: imageData,
            location: location
        )

        locked {
            createdPosts.append(post)
        }

        return post
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
