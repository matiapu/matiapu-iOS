//
//  MatchView.swift
//  matiapu
//

import SwiftUI

struct MatchView: View {
    @Bindable var viewModel: MatchViewModel

    var body: some View {
        PostFeedScreen(
            post: viewModel.currentPost,
            display: .match,
            isLoading: viewModel.isLoading,
            onSeeMore: viewModel.openDetail,
            onSwipe: viewModel.handleSwipe
        )
        .task {
            await viewModel.loadPosts()
        }
        .sheet(item: $viewModel.detailPost) { post in
            PostDetailView(post: post, display: .matchDetail)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.postDetailSheet)
        }
    }
}

#Preview {
    MatchView(viewModel: .preview)
}
