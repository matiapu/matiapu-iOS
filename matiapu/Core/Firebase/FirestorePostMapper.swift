//
//  FirestorePostMapper.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

enum FirestorePostMapper {
    static func post(
        id: String,
        data: [String: Any],
        authorNameOverride: String? = nil
    ) -> Post? {
        let status = data[FirestoreFields.Post.status] as? String ?? FirestorePostStatus.publicStatus
        guard status == FirestorePostStatus.publicStatus else { return nil }

        let body = data[FirestoreFields.Post.contentText] as? String ?? ""
        let title = data[FirestoreFields.Post.title] as? String ?? defaultTitle(from: body)
        let tag = data[FirestoreFields.Post.tag] as? String ?? MapFilter.bulletin.title
        let authorName = authorNameOverride
            ?? data[FirestoreFields.Post.authorDisplayName] as? String
            ?? "匿名ユーザー"

        return Post(
            id: id,
            authorName: authorName,
            tag: tag,
            title: title,
            body: body,
            postedAt: FirestoreDateCodec.date(from: data[FirestoreFields.Post.createdAt]) ?? .now,
            imageName: nil,
            imageData: nil,
            imageURL: data[FirestoreFields.Post.imageURL] as? String,
            location: location(from: data[FirestoreFields.Post.geoLocation]),
            authorUserId: data[FirestoreFields.Post.authorUID] as? String,
            legislatorId: nil
        )
    }

    static func legislatorCard(uid: String, data: [String: Any]) -> Post {
        let profile = FirestoreUserMapper.profile(from: data, uid: uid)
        return Post(
            id: "legislator-\(uid)",
            authorName: profile.displayName,
            tag: "議員",
            title: "\(profile.displayName)\n政策カード",
            body: profile.registeredArea.isEmpty
                ? "地域の課題解決に取り組みます。"
                : "\(profile.registeredArea)の課題解決に取り組みます。",
            postedAt: .now,
            imageName: nil,
            imageData: nil,
            imageURL: nil,
            location: nil,
            authorUserId: nil,
            legislatorId: uid
        )
    }

    static func createPayload(
        authorUID: String,
        authorDisplayName: String,
        userBadge: String,
        title: String,
        body: String,
        tag: String,
        imageURL: String?,
        location: PostLocation
    ) -> [String: Any] {
        var payload: [String: Any] = [
            FirestoreFields.Post.authorUID: authorUID,
            FirestoreFields.Post.userBadge: userBadge,
            FirestoreFields.Post.contentText: body,
            FirestoreFields.Post.title: title,
            FirestoreFields.Post.tag: tag,
            FirestoreFields.Post.authorDisplayName: authorDisplayName,
            FirestoreFields.Post.status: FirestorePostStatus.publicStatus,
            FirestoreFields.Post.createdAt: FirestoreDateCodec.timestamp(),
            FirestoreFields.Post.geoLocation: GeoPoint(
                latitude: location.latitude,
                longitude: location.longitude
            ),
        ]

        if let imageURL {
            payload[FirestoreFields.Post.imageURL] = imageURL
        } else {
            payload[FirestoreFields.Post.imageURL] = NSNull()
        }

        return payload
    }

    private static func location(from value: Any?) -> PostLocation? {
        switch value {
        case let geoPoint as GeoPoint:
            return PostLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        case let dictionary as [String: Any]:
            guard
                let latitude = dictionary["latitude"] as? Double,
                let longitude = dictionary["longitude"] as? Double
            else {
                return nil
            }
            return PostLocation(latitude: latitude, longitude: longitude)
        default:
            return nil
        }
    }

    private static func defaultTitle(from body: String) -> String {
        let firstLine = body
            .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? body
        if firstLine.count <= 24 {
            return firstLine
        }
        return String(firstLine.prefix(24))
    }
}
