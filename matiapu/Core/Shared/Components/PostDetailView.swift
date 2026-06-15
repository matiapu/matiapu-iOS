//
//  PostDetailView.swift
//  matiapu
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    let display: PostCardDisplay

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    heroImage(maxHeight: geometry.size.height * AppSize.postDetailImageHeightRatio)
                    contentSection
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(AppColors.postDetailBackground)
    }

    @ViewBuilder
    private func heroImage(maxHeight: CGFloat) -> some View {
        Group {
            if let imageName = post.imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                LinearGradient(
                    colors: [AppColors.postCardPlaceholderTop, AppColors.postCardPlaceholderBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: maxHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: maxHeight)
        .background(AppColors.postDetailImageBackground)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.postDetailSectionSpacing) {
            if display.showsAuthorName {
                authorRow
            }
            if display.showsTitle, !post.title.isEmpty {
                Text(post.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.postDetailText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if display.showsTag {
                tagLabel
            }
            Text(post.body)
                .font(AppTypography.cardBody)
                .foregroundStyle(AppColors.postDetailText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.postDetailHorizontal)
        .padding(.top, AppSpacing.postDetailTop)
        .padding(.bottom, AppSpacing.postDetailBottom)
    }

    @ViewBuilder
    private var authorRow: some View {
        HStack(spacing: AppSpacing.cardHeaderSpacing) {
            if display.showsAvatar {
                Circle()
                    .fill(AppColors.avatarPlaceholder)
                    .overlay {
                        Circle()
                            .stroke(AppColors.postDetailAvatarBorder, lineWidth: 1)
                    }
                    .frame(width: AppSize.avatar, height: AppSize.avatar)
            }

            Text(post.authorName)
                .font(AppTypography.cardAuthorName)
                .foregroundStyle(AppColors.postDetailText)

            Spacer()

            if display.showsPostedDate {
                Text(post.formattedDate)
                    .font(AppTypography.cardDate)
                    .foregroundStyle(AppColors.postDetailSecondaryText)
            }
        }
    }

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
}

#Preview("Post Detail") {
    PostDetailView(post: PostPreviewData.featured, display: .postDetail)
}

#Preview("Match Detail") {
    PostDetailView(post: PostPreviewData.match, display: .matchDetail)
}
