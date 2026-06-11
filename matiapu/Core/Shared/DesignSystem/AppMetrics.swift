//
//  AppMetrics.swift
//  matiapu
//

import CoreGraphics

enum AppSpacing {
    // 画面の左右の余白
    static let screenHorizontal: CGFloat = 12
    static let screenTop: CGFloat = 12
    static let fabTrailing: CGFloat = 16
    static let cardContentHorizontal: CGFloat = 20
    // PostCardのコンテンツのオフセット
    static let cardContentTop: CGFloat = 20
    static let cardContentBottom: CGFloat = 24
    static let cardSectionSpacing: CGFloat = 14
    static let cardBodySpacing: CGFloat = 8
    static let cardHeaderSpacing: CGFloat = 10
    // tagの余白
    static let tagHorizontal: CGFloat = 14
    static let tagVertical: CGFloat = 6

    // map filterの余白
    static let mapFilterSpacing: CGFloat = 8
    static let mapFilterVertical: CGFloat = 9
    static let mapFilterHorizontal: CGFloat = 18

    // create post
    static let createPostTop: CGFloat = 16
    static let createPostBottom: CGFloat = 32
    static let createPostSectionSpacing: CGFloat = 20
    static let createPostLabelSpacing: CGFloat = 8
    static let createPostFieldHorizontal: CGFloat = 20
    static let createPostBodyFieldVertical: CGFloat = 16
    static let createPostTagSpacing: CGFloat = 8
    static let createPostTagHorizontal: CGFloat = 14
    static let createPostTagVertical: CGFloat = 8
    static let createPostSubmitTop: CGFloat = 8
}

enum AppRadius {
    static let postCard: CGFloat = 28
    static let createPostPhoto: CGFloat = 12
    static let createPostBodyField: CGFloat = 24
}

enum AppSize {
    static let avatar: CGFloat = 44
    static let fab: CGFloat = 40
    static let postCardWidth: CGFloat = 390
    static let postCardHeight: CGFloat = 643
    static var postCardAspectRatio: CGFloat { postCardWidth / postCardHeight }
    static let createPostTitleFieldHeight: CGFloat = 48
    static let createPostBodyFieldMinHeight: CGFloat = 200
    static let createPostSubmitHeight: CGFloat = 48
}
