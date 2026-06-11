//
//  MatchView.swift
//  matiapu
//

import SwiftUI

struct MatchView: View {
    @Bindable var viewModel: MatchViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                cardContent

                Spacer()

                Text("右スワイプで共感 / 左・下でスキップ")
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("マッチング")
            .task {
                await viewModel.loadPosts()
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        if let post = viewModel.currentPost {
            SwipeablePostCard(
                post: post,
                display: .match,
                onSwipe: viewModel.handleSwipe
            )
            .id(post.id)
        } else if viewModel.isLoading {
            ProgressView()
                .frame(width: AppSize.postCardWidth, height: AppSize.postCardHeight)
        } else {
            ContentUnavailableView(
                "投稿がありません",
                systemImage: "rectangle.stack",
                description: Text("新しい投稿が追加されるまでお待ちください")
            )
            .frame(width: AppSize.postCardWidth, height: AppSize.postCardHeight)
        }
    }
}

#Preview {
    MatchView(viewModel: .preview)
}
