//
//  Post.swift
//  matiapu
//

import CoreGraphics
import Foundation

struct Post: Identifiable, Hashable {
    let id: String
    let authorName: String
    let tag: String
    let title: String
    let body: String
    let postedAt: Date
    /// Asset カタログ上の画像名（モックデータ用）。
    let imageName: String?
    /// ユーザーが実際に撮影・投稿した写真の画像データ。
    let imageData: Data?
    let location: PostLocation?
    /// 投稿した市民のユーザーID
    let authorUserId: String?
    /// 議員カード（Match画面）の議員ID
    let legislatorId: String?

    init(
        id: String,
        authorName: String,
        tag: String,
        title: String,
        body: String,
        postedAt: Date,
        imageName: String? = nil,
        imageData: Data? = nil,
        location: PostLocation?,
        authorUserId: String? = nil,
        legislatorId: String? = nil
    ) {
        self.id = id
        self.authorName = authorName
        self.tag = tag
        self.title = title
        self.body = body
        self.postedAt = postedAt
        self.imageName = imageName
        self.imageData = imageData
        self.location = location
        self.authorUserId = authorUserId
        self.legislatorId = legislatorId
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: postedAt)
    }

    // 画像データは比較・ハッシュ対象から除外し、一意な id でアイデンティティを表す。
    // （大きな Data のハッシュ計算を避けつつ、リスト描画の差分検出を高速に保つため）
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
            && lhs.authorName == rhs.authorName
            && lhs.tag == rhs.tag
            && lhs.title == rhs.title
            && lhs.body == rhs.body
            && lhs.postedAt == rhs.postedAt
            && lhs.imageName == rhs.imageName
            && lhs.location == rhs.location
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Swipe

/// スワイプ操作の種類（右: 共感 / 左・下: スキップ）
enum PostSwipeAction: Sendable, Hashable {
    case empathy
    case skip

    var hintLabel: String {
        switch self {
        case .empathy: return "共感"
        case .skip: return "スキップ"
        }
    }
}

/// スワイプ中に表示するスタンプ（Tinder 風）
enum PostSwipeStampKind: Sendable {
    case empathy
    case skipLeft
    case skipDown

    var symbolName: String {
        switch self {
        case .empathy: return "heart.fill"
        case .skipLeft: return "xmark"
        case .skipDown: return "forward.end.fill"
        }
    }

    var placement: PostSwipeHintPlacement {
        switch self {
        case .empathy: return .topLeading
        case .skipLeft: return .topTrailing
        case .skipDown: return .bottom
        }
    }

    var action: PostSwipeAction {
        switch self {
        case .empathy: return .empathy
        case .skipLeft, .skipDown: return .skip
        }
    }

    static func from(translation: CGSize) -> PostSwipeStampKind? {
        let minimum = PostSwipeMetrics.hintThreshold
        let horizontal = abs(translation.width)
        let vertical = translation.height

        if vertical > minimum, vertical > horizontal {
            return .skipDown
        }
        if translation.width > minimum {
            return .empathy
        }
        if translation.width < -minimum {
            return .skipLeft
        }
        return nil
    }
}

/// スワイプ判定のしきい値
enum PostSwipeMetrics {
    static let commitThreshold: CGFloat = 100
    static let hintThreshold: CGFloat = 40
    static let dragMinimumDistance: CGFloat = 12
    static let stampSize: CGFloat = 88
    static let stampCircleSize: CGFloat = 96
    static let stampSymbolSize: CGFloat = 36

    /// ドラッグ量に応じたスタンプの不透明度（Tinder 風にだんだん濃くなる）
    static func stampOpacity(for translation: CGSize) -> Double {
        guard PostSwipeStampKind.from(translation: translation) != nil else { return 0 }

        let horizontal = abs(translation.width)
        let vertical = max(0, translation.height)
        let dominant = max(horizontal, vertical)
        let range = commitThreshold - hintThreshold
        guard range > 0 else { return 1 }

        let progress = (dominant - hintThreshold) / range
        return min(1, max(0.15, Double(progress)))
    }

    /// ドラッグ量に応じたスタンプの拡大率
    static func stampScale(for translation: CGSize) -> CGFloat {
        let opacity = stampOpacity(for: translation)
        return 0.75 + CGFloat(opacity) * 0.35
    }
}

/// ドラッグ終了時のスワイプ判定結果
enum PostSwipeDecision: Equatable, Sendable {
    case committed(PostSwipeAction)
    case cancelled

    static func from(
        translation: CGSize,
        threshold: CGFloat = PostSwipeMetrics.commitThreshold
    ) -> PostSwipeDecision {
        let horizontal = abs(translation.width)
        let vertical = translation.height

        if vertical > threshold, vertical > horizontal {
            return .committed(.skip)
        }
        if translation.width > threshold {
            return .committed(.empathy)
        }
        if translation.width < -threshold {
            return .committed(.skip)
        }
        return .cancelled
    }
}

extension PostSwipeAction {
    /// ドラッグ中にヒントを表示するかどうか
    static func hint(for translation: CGSize) -> PostSwipeAction? {
        let minimum = PostSwipeMetrics.hintThreshold
        let horizontal = abs(translation.width)
        let vertical = translation.height

        if vertical > minimum, vertical > horizontal {
            return .skip
        }
        if translation.width > minimum {
            return .empathy
        }
        if translation.width < -minimum {
            return .skip
        }
        return nil
    }

    /// ヒントラベルの表示位置
    static func hintPlacement(for translation: CGSize) -> PostSwipeHintPlacement {
        let minimum = PostSwipeMetrics.hintThreshold
        let horizontal = abs(translation.width)
        let vertical = translation.height

        if vertical > minimum, vertical > horizontal {
            return .bottom
        }
        if translation.width > minimum {
            return .topLeading
        }
        return .topTrailing
    }
}

enum PostSwipeHintPlacement: Sendable {
    case bottom
    case topLeading
    case topTrailing
}

/// スワイプ対象の投稿キュー
struct PostSwipeQueue {
    private(set) var current: Post?
    private var remaining: [Post]

    init(candidates: [Post] = []) {
        var queue = candidates
        current = queue.isEmpty ? nil : queue.removeFirst()
        remaining = queue
    }

    var isEmpty: Bool {
        current == nil && remaining.isEmpty
    }

    var remainingCount: Int {
        remaining.count
    }

    /// スワイプ後に次の投稿へ進む。処理した操作を返す。
    @discardableResult
    mutating func advance(with action: PostSwipeAction) -> PostSwipeAction? {
        guard current != nil else { return nil }
        current = remaining.isEmpty ? nil : remaining.removeFirst()
        return action
    }
}
