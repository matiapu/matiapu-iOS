//
//  FirebasePostRepository.swift
//  matiapu
//

import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

final class FirebasePostRepository: PostRepository, @unchecked Sendable {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let authRepository: any AuthRepository
    private let likeService: FirestoreLikeService

    init(authRepository: any AuthRepository, likeService: FirestoreLikeService) {
        self.authRepository = authRepository
        self.likeService = likeService
    }

    func fetchPosts(filter: MapFilter?) async throws -> [Post] {
        let posts = try await fetchPublicPosts()
        let located = posts.filter { $0.location != nil }
        guard let filter else { return located }
        return located.filter { filter.matches(post: $0) }
    }

    func fetchMatchCandidates() async throws -> [Post] {
        let snapshot = try await db.collection(FirestoreCollections.users)
            .whereField(FirestoreFields.User.role, isEqualTo: UserRole.legislator.rawValue)
            .getDocuments()

        return snapshot.documents.map { document in
            FirestorePostMapper.legislatorCard(uid: document.documentID, data: document.data())
        }
    }

    func fetchFeaturedPost() async throws -> Post? {
        try await fetchPublicPosts(limit: 1).first
    }

    func fetchFeedPosts() async throws -> [Post] {
        try await fetchPublicPosts()
    }

    func fetchUserPosts() async throws -> [Post] {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let snapshot = try await db.collection(FirestoreCollections.posts)
            .whereField(FirestoreFields.Post.authorUID, isEqualTo: uid)
            .order(by: FirestoreFields.Post.createdAt, descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            FirestorePostMapper.post(id: document.documentID, data: document.data())
        }
    }

    func fetchLikedPosts() async throws -> [Post] {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let postIDs = try await likeService.likedPostIDs(for: uid)
        guard !postIDs.isEmpty else { return [] }

        var posts: [Post] = []
        posts.reserveCapacity(postIDs.count)

        for postID in postIDs {
            let snapshot = try await db.collection(FirestoreCollections.posts).document(postID).getDocument()
            guard let data = snapshot.data(),
                  let post = FirestorePostMapper.post(id: snapshot.documentID, data: data) else {
                continue
            }
            posts.append(post)
        }

        return posts.sorted { $0.postedAt > $1.postedAt }
    }

    func recordSwipe(postId: String, action: PostSwipeAction) async throws {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        switch action {
        case .empathy:
            try await likeService.likePost(postID: postId, userID: uid)
        case .skip:
            if try await likeService.hasLikedPost(postID: postId, userID: uid) {
                try await likeService.unlikePost(postID: postId, userID: uid)
            }
        }
    }

    func createPost(
        title: String,
        body: String,
        tag: MapFilter,
        image: UIImage,
        location: PostLocation
    ) async throws -> Post {
        let uid = try await FirebaseAuthSession.ensureSignedIn()
        let profile = try await authRepository.fetchCurrentUser()
        let postRef = db.collection(FirestoreCollections.posts).document()
        let imageURL = try await uploadImage(image, postID: postRef.documentID)

        let payload = FirestorePostMapper.createPayload(
            authorUID: uid,
            authorDisplayName: profile.displayName,
            userBadge: profile.displayName,
            title: title,
            body: body,
            tag: tag.title,
            imageURL: imageURL,
            location: location
        )

        try await postRef.setData(payload)

        return Post(
            id: postRef.documentID,
            authorName: profile.displayName,
            tag: tag.title,
            title: title,
            body: body,
            postedAt: .now,
            imageName: nil,
            imageData: image.jpegData(compressionQuality: 0.8),
            imageURL: imageURL,
            location: location,
            authorUserId: uid
        )
    }

    private func fetchPublicPosts(limit: Int? = nil) async throws -> [Post] {
        var query: Query = db.collection(FirestoreCollections.posts)
            .whereField(FirestoreFields.Post.status, isEqualTo: FirestorePostStatus.publicStatus)
            .order(by: FirestoreFields.Post.createdAt, descending: true)

        if let limit {
            query = query.limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            FirestorePostMapper.post(id: document.documentID, data: document.data())
        }
    }

    private func uploadImage(_ image: UIImage, postID: String) async throws -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let path = "posts/\(postID)/\(UUID().uuidString).jpg"
        let reference = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await reference.putDataAsync(data, metadata: metadata)
        return try await reference.downloadURL().absoluteString
    }
}
