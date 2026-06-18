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
        imageName: MockImages.postImage(at: 0),
        location: nil,
        authorUserId: MockMatching.demoCitizenId
    )

    static let match = Post(
        id: "preview-match-1",
        authorName: "名前名前名前",
        tag: "災害",
        title: "タイトルタイトルタイトル\nタイトルタイトルタイトル",
        body: String(repeating: "本文", count: 30),
        postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 19).date ?? .now,
        imageName: MockImages.postImage(at: 1),
        location: nil,
        legislatorId: "leg-1"
    )

    static let matchCandidates: [Post] = [
        Post(
            id: "preview-match-2",
            authorName: "田中 太郎",
            tag: "道路",
            title: "歩道の整備を\n進めます",
            body: "地域の歩道の老朽化が進んでいます。安全な通行のため、段階的な整備計画を提案します。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 4, day: 12).date ?? .now,
            imageName: MockImages.postImage(at: 2),
            location: nil,
            legislatorId: MockMatching.demoLegislatorId
        ),
        match,
        Post(
            id: "preview-match-3",
            authorName: "佐藤 花子",
            tag: "お店",
            title: "商店街の活性化\n支援策",
            body: "空き店舗の活用とイベント開催により、にぎわいのある商店街を目指します。",
            postedAt: .now,
            imageName: MockImages.postImage(at: 3),
            location: nil,
            legislatorId: "leg-3"
        ),
        Post(
            id: "preview-match-4",
            authorName: "鈴木 一郎",
            tag: "通報",
            title: "防犯カメラの\n設置拡大",
            body: "住民からの声を反映し、犯罪抑止のため防犯カメラの設置を拡大します。",
            postedAt: .now,
            imageName: MockImages.postImage(at: 4),
            location: nil,
            legislatorId: "leg-4"
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
            imageName: MockImages.postImage(at: 5),
            location: nil,
            authorUserId: "citizen-2"
        ),
        Post(
            id: "preview-feed-3",
            authorName: "匿名ユーザー",
            tag: "ごみ",
            title: "駅前のごみ捨てが\n増えています",
            body: "週末になるとペットボトルが散乱しています。",
            postedAt: .now,
            imageName: MockImages.postImage(at: 6),
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
            imageName: MockImages.postImage(at: 1),
            location: PostLocation(latitude: 35.681228, longitude: 139.767052)
        ),
        Post(
            id: "preview-map-road",
            authorName: "匿名ユーザー",
            tag: "道路",
            title: "ラーメン店B",
            body: "歩道に小さな穴が開いています。",
            postedAt: .now,
            imageName: MockImages.postImage(at: 2),
            location: PostLocation(latitude: 35.683500, longitude: 139.765000)
        ),
        Post(
            id: "preview-map-shop",
            authorName: "商店街の方",
            tag: "お店",
            title: "緑の公園C",
            body: "駅前にオープンしました。",
            postedAt: .now,
            imageName: MockImages.postImage(at: 3),
            location: PostLocation(latitude: 35.678000, longitude: 139.769000)
        ),
        Post(
            id: "preview-map-disaster-2",
            authorName: "匿名ユーザー",
            tag: "災害",
            title: "静かなカフェD",
            body: "強風で看板が破損しています。",
            postedAt: .now,
            imageName: MockImages.postImage(at: 4),
            location: PostLocation(latitude: 35.685000, longitude: 139.771000)
        ),
        Post(
            id: "preview-map-bulletin",
            authorName: "匿名ユーザー",
            tag: "通報",
            title: "通報エリアA",
            body: "夜間に同じ場所をうろつく人物を見かけました。",
            postedAt: .now,
            imageName: MockImages.postImage(at: 5),
            location: PostLocation(latitude: 35.682000, longitude: 139.768000)
        ),
    ]

    static let userPosts: [Post] = [
        Post(
            id: "preview-user-1",
            authorName: "ユーザー名ユーザー名",
            tag: "災害",
            title: "強風で看板が\n破損しています",
            body: "商店街入口の看板が揺れて外れかけています。通行の際はご注意ください。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 8).date ?? .now,
            imageName: MockImages.postImage(at: 0),
            location: PostLocation(latitude: 35.693800, longitude: 139.703400)
        ),
        Post(
            id: "preview-user-2",
            authorName: "ユーザー名ユーザー名",
            tag: "道路",
            title: "歩道の段差が\n大きいです",
            body: "交差点付近の歩道に段差があり、ベビーカーでの通行が困難です。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 5).date ?? .now,
            imageName: MockImages.postImage(at: 1),
            location: PostLocation(latitude: 35.694200, longitude: 139.702800)
        ),
        Post(
            id: "preview-user-3",
            authorName: "ユーザー名ユーザー名",
            tag: "お店",
            title: "新しいカフェが\nオープン",
            body: "駅前に地域食材を使ったカフェがオープンしました。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 6, day: 1).date ?? .now,
            imageName: MockImages.postImage(at: 2),
            location: PostLocation(latitude: 35.692500, longitude: 139.704100)
        ),
        Post(
            id: "preview-user-4",
            authorName: "ユーザー名ユーザー名",
            tag: "通報",
            title: "夜間の騒音\nについて",
            body: "最近、深夜に同じ場所から騒音が聞こえることがあります。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 28).date ?? .now,
            imageName: MockImages.postImage(at: 3),
            location: PostLocation(latitude: 35.691900, longitude: 139.701900)
        ),
        Post(
            id: "preview-user-5",
            authorName: "ユーザー名ユーザー名",
            tag: "災害",
            title: "公園の木が\n倒れそうです",
            body: "台風後、根元が浮き上がっている木があります。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 22).date ?? .now,
            imageName: MockImages.postImage(at: 4),
            location: PostLocation(latitude: 35.695000, longitude: 139.705500)
        ),
        Post(
            id: "preview-user-6",
            authorName: "ユーザー名ユーザー名",
            tag: "道路",
            title: "横断歩道の\n信号が故障",
            body: "押しボタンを押しても反応しない横断歩道があります。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 18).date ?? .now,
            imageName: MockImages.postImage(at: 0),
            location: PostLocation(latitude: 35.690800, longitude: 139.706200)
        ),
        Post(
            id: "preview-user-7",
            authorName: "ユーザー名ユーザー名",
            tag: "お店",
            title: "商店街の\nイベント告知",
            body: "今週末にフリーマーケットを開催します。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 12).date ?? .now,
            imageName: MockImages.postImage(at: 1),
            location: PostLocation(latitude: 35.696300, longitude: 139.700700)
        ),
        Post(
            id: "preview-user-8",
            authorName: "ユーザー名ユーザー名",
            tag: "通報",
            title: "放置自転車が\n増えています",
            body: "駅前広場に放置自転車が増えており、通行の妨げになっています。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 8).date ?? .now,
            imageName: MockImages.postImage(at: 2),
            location: PostLocation(latitude: 35.697100, longitude: 139.699800)
        ),
        Post(
            id: "preview-user-9",
            authorName: "ユーザー名ユーザー名",
            tag: "災害",
            title: "側溝の詰まり\nを確認",
            body: "雨の後も水が流れない側溝がありました。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 5, day: 3).date ?? .now,
            imageName: MockImages.postImage(at: 3),
            location: PostLocation(latitude: 35.689500, longitude: 139.707600)
        ),
        Post(
            id: "preview-user-10",
            authorName: "ユーザー名ユーザー名",
            tag: "道路",
            title: "路面の穴が\n深くなっています",
            body: "車両通過時に大きな音がする穴が見つかりました。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 4, day: 27).date ?? .now,
            imageName: MockImages.postImage(at: 4),
            location: PostLocation(latitude: 35.688700, longitude: 139.708300)
        ),
        Post(
            id: "preview-user-11",
            authorName: "ユーザー名ユーザー名",
            tag: "お店",
            title: "閉店した店舗\nについて",
            body: "長年利用していたパン屋が閉店しました。後継店舗を希望します。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 4, day: 20).date ?? .now,
            imageName: MockImages.postImage(at: 0),
            location: PostLocation(latitude: 35.687900, longitude: 139.709000)
        ),
        Post(
            id: "preview-user-12",
            authorName: "ユーザー名ユーザー名",
            tag: "通報",
            title: "公園の照明が\n消えています",
            body: "夜間、公園内の一部照明が点灯していません。",
            postedAt: DateComponents(calendar: .current, year: 2026, month: 4, day: 15).date ?? .now,
            imageName: MockImages.postImage(at: 1),
            location: PostLocation(latitude: 35.686800, longitude: 139.710200)
        ),
    ]

    static let likedPosts: [Post] = Array(feedCandidates.prefix(12))
}
