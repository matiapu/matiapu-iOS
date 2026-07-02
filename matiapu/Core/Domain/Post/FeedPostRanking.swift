//
//  FeedPostRanking.swift
//  matiapu
//

import Foundation

/// 投稿フィードの並び替え・絞り込みルール。
@MainActor
enum FeedPostRanking {
    /// 自分以外の同一地域の投稿を、いいね数の多い順に並べる。
    static func rankedPosts(
        posts: [Post],
        currentUserID: String,
        registeredArea: String,
        likeCounts: [String: Int]
    ) -> [Post] {
        guard let userMunicipality = normalizedMunicipality(registeredArea) else {
            return []
        }

        return posts
            .filter { post in
                guard post.authorUserId != currentUserID else { return false }
                guard let postMunicipality = normalizedMunicipality(post.municipality) else { return false }
                return postMunicipality == userMunicipality
            }
            .sorted { lhs, rhs in
                let lhsLikes = likeCounts[lhs.id] ?? 0
                let rhsLikes = likeCounts[rhs.id] ?? 0
                if lhsLikes != rhsLikes {
                    return lhsLikes > rhsLikes
                }
                return lhs.postedAt > rhs.postedAt
            }
    }

    private static func normalizedMunicipality(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return MunicipalityStore.shared.resolveMunicipalityName(from: trimmed) ?? trimmed
    }
}
