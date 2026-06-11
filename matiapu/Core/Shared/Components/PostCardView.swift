//
//  PostCardView.swift
//  matiapu
//

import SwiftUI

/// 画面ごとに表示する項目を切り替える
struct PostCardDisplay {
    let showsPostedDate: Bool
    let showsTitle: Bool
    let showsTag: Bool
    let showsSeeMoreLink: Bool
    let collapsedBodyLineLimit: Int?

    static let postFeed = PostCardDisplay(
        showsPostedDate: true,
        showsTitle: true,
        showsTag: true,
        showsSeeMoreLink: true,
        collapsedBodyLineLimit: 5
    )

    static let match = PostCardDisplay(
        showsPostedDate: false,
        showsTitle: false,
        showsTag: true,
        showsSeeMoreLink: false,
        collapsedBodyLineLimit: nil
    )
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
                headerRow
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
            Group {
                if let imageName = post.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [AppColors.postCardPlaceholderTop, AppColors.postCardPlaceholderBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    private var headerRow: some View {
        HStack(spacing: AppSpacing.cardHeaderSpacing) {
            Circle()
                .fill(AppColors.avatarPlaceholder)
                .frame(width: AppSize.avatar, height: AppSize.avatar)

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
                    Button(action: onSeeMore) {
                        Text("続きを見る")
                            .font(AppTypography.cardSeeMore)
                            .foregroundStyle(AppColors.onImageText)
                    }
                    .buttonStyle(.plain)
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
    .background(AppColors.postScreenBackground)
}

#Preview("Match") {
    PostCardView(
        post: PostPreviewData.match,
        display: .match,
        isBodyExpanded: true,
        onSeeMore: {}
    )
    .padding()
}
