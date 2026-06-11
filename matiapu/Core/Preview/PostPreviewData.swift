//
//  PostPreviewData.swift
//  matiapu
//

import Foundation

enum PostPreviewData {
    static let featured = Post(
        id: "preview-featured",
        authorName: "アカウント名",
        tag: "タグ",
        title: "タイトルタイトルタイトル\nタイトルタイトルタイトル",
        body: String(repeating: "本文", count: 30),
        postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 19).date ?? .now,
        imageName: "PostSample",
        location: nil
    )

    static let match = Post(
        id: "preview-match-1",
        authorName: "匿名ユーザー",
        tag: "インフラ・道路",
        title: "",
        body: "夜道が暗くて危ないです...",
        postedAt: .now,
        imageName: "PostSample",
        location: nil
    )

    static let matchCandidates: [Post] = [
        match,
        Post(
            id: "preview-match-2",
            authorName: "匿名ユーザー",
            tag: "防犯・安全",
            title: "",
            body: "公園の照明が切れている場所があります。",
            postedAt: .now,
            imageName: "PostSample",
            location: nil
        ),
        Post(
            id: "preview-match-3",
            authorName: "匿名ユーザー",
            tag: "交通",
            title: "",
            body: "横断歩道の白線が消えかかっています。",
            postedAt: .now,
            imageName: "PostSample",
            location: nil
        ),
    ]

    static let feedCandidates: [Post] = [
        featured,
        Post(
            id: "preview-feed-2",
            authorName: "地域の住民",
            tag: "公園",
            title: "児童公園の遊具が\n老朽化しています",
            body: "ブランコのチェーンが錆びていて危ないです。",
            postedAt: .now,
            imageName: "PostSample",
            location: nil
        ),
        Post(
            id: "preview-feed-3",
            authorName: "匿名ユーザー",
            tag: "ごみ",
            title: "駅前のごみ捨てが\n増えています",
            body: "週末になるとペットボトルが散乱しています。",
            postedAt: .now,
            imageName: "PostSample",
            location: nil
        ),
    ]

    static let mapPosts: [Post] = [
        Post(
            id: "preview-map-disaster-1",
            authorName: "地域の住民",
            tag: "災害",
            title: "おしゃれカフェA",
            body: "倒木の報告があります。",
            postedAt: .now,
            imageName: "PostSample",
            location: PostLocation(latitude: 35.681228, longitude: 139.767052)
        ),
        Post(
            id: "preview-map-road",
            authorName: "匿名ユーザー",
            tag: "道路",
            title: "ラーメン店B",
            body: "歩道に小さな穴が開いています。",
            postedAt: .now,
            imageName: "PostSample",
            location: PostLocation(latitude: 35.683500, longitude: 139.765000)
        ),
        Post(
            id: "preview-map-shop",
            authorName: "商店街の方",
            tag: "お店",
            title: "緑の公園C",
            body: "駅前にオープンしました。",
            postedAt: .now,
            imageName: "PostSample",
            location: PostLocation(latitude: 35.678000, longitude: 139.769000)
        ),
        Post(
            id: "preview-map-disaster-2",
            authorName: "匿名ユーザー",
            tag: "災害",
            title: "静かなカフェD",
            body: "強風で看板が破損しています。",
            postedAt: .now,
            imageName: "PostSample",
            location: PostLocation(latitude: 35.685000, longitude: 139.771000)
        ),
        Post(
            id: "preview-map-bulletin",
            authorName: "匿名ユーザー",
            tag: "通報",
            title: "通報エリアA",
            body: "夜間に同じ場所をうろつく人物を見かけました。",
            postedAt: .now,
            imageName: "PostSample",
            location: PostLocation(latitude: 35.682000, longitude: 139.768000)
        ),
    ]
}
