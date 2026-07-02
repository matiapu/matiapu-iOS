//
//  PostCardView.swift
//  matiapu
//

import SwiftUI

/// 画面ごとに表示する項目を切り替える
struct PostCardDisplay {
    let showsAvatar: Bool
    let showsAuthorName: Bool
    let showsPostedDate: Bool
    let showsTitle: Bool
    let showsTag: Bool
    let showsSeeMoreLink: Bool
    let showsComments: Bool
    let collapsedBodyLineLimit: Int?

    static let postFeed = PostCardDisplay(
        showsAvatar: true,
        showsAuthorName: true,
        showsPostedDate: true,
        showsTitle: true,
        showsTag: true,
        showsSeeMoreLink: true,
        showsComments: false,
        collapsedBodyLineLimit: 5
    )

    static let match = PostCardDisplay(
        showsAvatar: false,
        showsAuthorName: true,
        showsPostedDate: true,
        showsTitle: true,
        showsTag: true,
        showsSeeMoreLink: true,
        showsComments: false,
        collapsedBodyLineLimit: 5
    )

    static let postDetail = PostCardDisplay(
        showsAvatar: true,
        showsAuthorName: true,
        showsPostedDate: true,
        showsTitle: true,
        showsTag: true,
        showsSeeMoreLink: false,
        showsComments: true,
        collapsedBodyLineLimit: nil
    )

    static let matchDetail = PostCardDisplay(
        showsAvatar: false,
        showsAuthorName: true,
        showsPostedDate: true,
        showsTitle: true,
        showsTag: true,
        showsSeeMoreLink: false,
        showsComments: false,
        collapsedBodyLineLimit: nil
    )
}

struct PostSeeMoreButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("続きを見る")
                .font(AppTypography.cardSeeMore)
                .foregroundStyle(AppColors.onImageText)
        }
        .buttonStyle(.plain)
        .highPriorityGesture(
            TapGesture().onEnded { action() }
        )
    }
}

struct PostCardView: View {
    let post: Post
    let display: PostCardDisplay
    let isBodyExpanded: Bool
    let onSeeMore: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            cardBackground

            LinearGradient(
                colors: AppColors.postCardGradient,
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.cardSectionSpacing) {
                if display.showsAuthorName {
                    authorNameSection
                }
                if display.showsTitle {
                    titleSection
                }
                if display.showsTag {
                    tagLabel
                }
                bodySection
            }
            .padding(.horizontal, AppSpacing.cardContentHorizontal)
            .padding(.bottom, AppSpacing.cardContentBottom)
            .padding(.top, AppSpacing.cardContentTop)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(width: AppSize.postCardWidth, height: AppSize.postCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.postCard, style: .continuous))
    }

    @ViewBuilder
    private var cardBackground: some View {
        GeometryReader { geometry in
            PostImageView(post: post, contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }

    @ViewBuilder
    private var authorNameSection: some View {
        if display.showsAvatar || display.showsPostedDate {
            HStack(spacing: AppSpacing.cardHeaderSpacing) {
                if display.showsAvatar {
                    Circle()
                        .fill(AppColors.avatarPlaceholder)
                        .frame(width: AppSize.avatar, height: AppSize.avatar)
                }

                Text(post.authorName)
                    .font(AppTypography.cardAuthorName)
                    .foregroundStyle(AppColors.onImageText)

                Spacer()

                if display.showsPostedDate {
                    Text(post.formattedDate)
                        .font(AppTypography.cardDate)
                        .foregroundStyle(AppColors.onImageText)
                }
            }
        } else {
            Text(post.authorName)
                .font(AppTypography.cardAuthorName)
                .foregroundStyle(AppColors.onImageText)
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        Text(post.title)
            .font(AppTypography.cardTitle)
            .foregroundStyle(AppColors.onImageText)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var tagLabel: some View {
        Text(post.tag)
            .font(AppTypography.cardTag)
            .foregroundStyle(AppColors.onTagText)
            .padding(.horizontal, AppSpacing.tagHorizontal)
            .padding(.vertical, AppSpacing.tagVertical)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.postTag)
            )
    }

    @ViewBuilder
    private var bodySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.cardBodySpacing) {
            Text(post.body)
                .font(AppTypography.cardBody)
                .foregroundStyle(AppColors.onImageText)
                .lineSpacing(3)
                .lineLimit(bodyLineLimit)

            if display.showsSeeMoreLink {
                HStack {
                    Spacer()
                    PostSeeMoreButton(action: onSeeMore)
                }
            }
        }
    }

    private var bodyLineLimit: Int? {
        if isBodyExpanded {
            return nil
        }
        return display.collapsedBodyLineLimit
    }
}

#Preview("Post") {
    PostCardView(
        post: PostPreviewData.featured,
        display: .postFeed,
        isBodyExpanded: false,
        onSeeMore: {}
    )
    .padding()
    .background(AppColors.postScreenBackgroundGradient)
}

#Preview("Match") {
    PostCardView(
        post: PostPreviewData.match,
        display: .match,
        isBodyExpanded: false,
        onSeeMore: {}
    )
    .padding()
    .background(AppColors.postScreenBackgroundGradient)
}
