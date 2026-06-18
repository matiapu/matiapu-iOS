//
//  MatchView.swift
//  matiapu
//

import SwiftUI

struct MatchView: View {
    @Bindable var viewModel: MatchViewModel
    @Bindable var chatViewModel: ChatViewModel

    var body: some View {
        PostFeedScreen(
            post: viewModel.currentPost,
            display: .match,
            isLoading: viewModel.isLoading,
            onSeeMore: viewModel.openDetail,
            onSwipe: viewModel.handleSwipe,
            overlay: {
                ChatFAB(action: viewModel.openChat)
            }
        )
        .task {
            await viewModel.loadPosts()
        }
        .sheet(isPresented: chatPresentation) {
            NavigationStack {
                ChatView(viewModel: chatViewModel)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(AppRadius.postDetailSheet)
        }
        .sheet(item: $viewModel.detailPost) { post in
            PostDetailView(post: post, display: .matchDetail)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.postDetailSheet)
        }
        .alert("マッチしました！", isPresented: $viewModel.showMatchAlert) {
            Button("チャットを開く") {
                viewModel.openChatAfterMatch()
            }
            Button("閉じる", role: .cancel) {
                viewModel.dismissMatchAlert()
            }
        } message: {
            if let name = viewModel.matchedPartnerName {
                Text("\(name)さんとマッチしました。チャットでメッセージを送れます。")
            }
        }
    }

    private var chatPresentation: Binding<Bool> {
        Binding(
            get: { viewModel.isChatPresented },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissChat()
                }
            }
        )
    }
}

#Preview {
    MatchView(
        viewModel: .preview,
        chatViewModel: .preview
    )
}
