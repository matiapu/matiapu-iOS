//
//  PostFeedScreen.swift
//  matiapu
//

import SwiftUI

struct PostFeedScreen<Overlay: View>: View {
    let post: Post?
    let display: PostCardDisplay
    let isLoading: Bool
    let onSeeMore: () -> Void
    let onSwipe: (PostSwipeAction) -> Void
    @ViewBuilder let overlay: () -> Overlay

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppColors.postScreenBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                postCardContent
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            overlay()
        }
    }

    @ViewBuilder
    private var postCardContent: some View {
        if let post {
            SwipeablePostCard(
                post: post,
                display: display,
                isBodyExpanded: false,
                onSeeMore: onSeeMore,
                onSwipe: onSwipe
            )
            .id(post.id)
        } else if isLoading {
            ProgressView()
                .tint(AppColors.onImageText)
                .frame(width: AppSize.postCardWidth, height: AppSize.postCardHeight)
        } else {
            ContentUnavailableView(
                "投稿がありません",
                systemImage: "rectangle.stack"
            )
            .frame(width: AppSize.postCardWidth, height: AppSize.postCardHeight)
        }
    }
}

extension PostFeedScreen where Overlay == EmptyView {
    init(
        post: Post?,
        display: PostCardDisplay,
        isLoading: Bool,
        onSeeMore: @escaping () -> Void,
        onSwipe: @escaping (PostSwipeAction) -> Void
    ) {
        self.post = post
        self.display = display
        self.isLoading = isLoading
        self.onSeeMore = onSeeMore
        self.onSwipe = onSwipe
        self.overlay = { EmptyView() }
    }
}

struct CreatePostFAB: View {
    let action: () -> Void

    var body: some View {
        GlassFAB(systemImage: "plus", action: action)
            .padding(.trailing, AppSpacing.fabTrailing)
            .padding(.top, AppSpacing.screenTop)
    }
}

struct ChatFAB: View {
    let action: () -> Void

    var body: some View {
        GlassFAB(systemImage: "bubble.left.and.bubble.right.fill", action: action)
            .padding(.trailing, AppSpacing.fabTrailing)
            .padding(.top, AppSpacing.screenTop)
    }
}

struct GlassFAB: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(AppTypography.fabIcon)
                .frame(width: AppSize.fab, height: AppSize.fab)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}

#Preview("With FAB") {
    PostFeedScreen(
        post: PostPreviewData.featured,
        display: .postFeed,
        isLoading: false,
        onSeeMore: {},
        onSwipe: { _ in },
        overlay: {
            CreatePostFAB(action: {})
        }
    )
}

#Preview("Match") {
    PostFeedScreen(
        post: PostPreviewData.match,
        display: .match,
        isLoading: false,
        onSeeMore: {},
        onSwipe: { _ in }
    )
}
