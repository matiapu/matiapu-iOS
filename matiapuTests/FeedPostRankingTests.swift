//
//  FeedPostRankingTests.swift
//  matiapuTests
//

import XCTest
@testable import matiapu

final class FeedPostRankingTests: XCTestCase {
    @MainActor
    func testRankedPosts_excludesSelfAndOtherRegions_sortsByLikes() {
        let posts = [
            Post(
                id: "self",
                authorName: "自分",
                tag: "災害",
                title: "自分の投稿",
                body: "本文",
                postedAt: .now,
                location: nil,
                municipality: "新宿区",
                authorUserId: "user-1"
            ),
            Post(
                id: "local-low",
                authorName: "住民A",
                tag: "道路",
                title: "いいね少",
                body: "本文",
                postedAt: .now,
                location: nil,
                municipality: "新宿区",
                authorUserId: "user-2"
            ),
            Post(
                id: "local-high",
                authorName: "住民B",
                tag: "お店",
                title: "いいね多",
                body: "本文",
                postedAt: .now,
                location: nil,
                municipality: "新宿区",
                authorUserId: "user-3"
            ),
            Post(
                id: "other-region",
                authorName: "他地域",
                tag: "通報",
                title: "渋谷",
                body: "本文",
                postedAt: .now,
                location: nil,
                municipality: "渋谷区",
                authorUserId: "user-4"
            ),
        ]

        let ranked = FeedPostRanking.rankedPosts(
            posts: posts,
            currentUserID: "user-1",
            registeredArea: "新宿区",
            likeCounts: [
                "local-low": 2,
                "local-high": 10,
                "other-region": 99,
            ]
        )

        XCTAssertEqual(ranked.map(\.id), ["local-high", "local-low"])
    }

    @MainActor
    func testRankedPosts_returnsEmptyWhenRegisteredAreaMissing() {
        let posts = [
            Post(
                id: "local",
                authorName: "住民",
                tag: "災害",
                title: "タイトル",
                body: "本文",
                postedAt: .now,
                location: nil,
                municipality: "新宿区",
                authorUserId: "user-2"
            ),
        ]

        let ranked = FeedPostRanking.rankedPosts(
            posts: posts,
            currentUserID: "user-1",
            registeredArea: "",
            likeCounts: [:]
        )

        XCTAssertTrue(ranked.isEmpty)
    }
}
