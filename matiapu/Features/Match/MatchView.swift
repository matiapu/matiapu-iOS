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
            detailDisplay: .matchDetail,
            isLoading: viewModel.isLoading,
            detailPost: $viewModel.detailPost,
            onSeeMore: viewModel.openDetail,
            onSwipe: viewModel.handleSwipe
        )
        .task {
            await viewModel.loadPosts()
        }
    }
}

#Preview {
    MatchView(viewModel: .preview)
}
