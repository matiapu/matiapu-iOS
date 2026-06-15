//
//  PostFeedScreen.swift
//  matiapu
//

import SwiftUI

struct PostFeedScreen<Overlay: View>: View {
    let post: Post?
    let display: PostCardDisplay
    let detailDisplay: PostCardDisplay
    let isLoading: Bool
    @Binding var detailPost: Post?
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
        .sheet(item: $detailPost) { post in
            PostDetailView(post: post, display: detailDisplay)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.postDetailSheet)
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
        detailDisplay: PostCardDisplay,
        isLoading: Bool,
        detailPost: Binding<Post?>,
        onSeeMore: @escaping () -> Void,
        onSwipe: @escaping (PostSwipeAction) -> Void
    ) {
        self.post = post
        self.display = display
        self.detailDisplay = detailDisplay
        self.isLoading = isLoading
        self._detailPost = detailPost
        self.onSeeMore = onSeeMore
        self.onSwipe = onSwipe
        self.overlay = { EmptyView() }
    }
}

struct CreatePostGlassButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(AppTypography.fabIcon)
                .frame(width: AppSize.fab, height: AppSize.fab)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}

struct CreatePostFAB: View {
    let action: () -> Void

    var body: some View {
        CreatePostGlassButton(action: action)
            .padding(.trailing, AppSpacing.fabTrailing)
            .padding(.top, AppSpacing.screenTop)
    }
}

#Preview("With FAB") {
    PostFeedScreen(
        post: PostPreviewData.featured,
        display: .postFeed,
        detailDisplay: .postDetail,
        isLoading: false,
        detailPost: .constant(nil),
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
        detailDisplay: .matchDetail,
        isLoading: false,
        detailPost: .constant(nil),
        onSeeMore: {},
        onSwipe: { _ in }
    )
}
