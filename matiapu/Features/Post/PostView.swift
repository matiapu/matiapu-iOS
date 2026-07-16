//
//  PostView.swift
//  matiapu
//

import SwiftUI

struct PostView: View {
    @Bindable var viewModel: PostViewModel
    @Bindable var chatViewModel: ChatViewModel
    @Environment(\.appDependencies) private var dependencies

    var body: some View {
        PostFeedScreen(
            post: viewModel.post,
            display: .postFeed,
            isLoading: viewModel.isLoading,
            onSeeMore: viewModel.openDetail,
            onSwipe: viewModel.handleSwipe,
            overlay: {
                CreatePostFAB(action: viewModel.openCreatePost)
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
            if let dependencies {
                PostDetailView(post: post, display: .postDetail, dependencies: dependencies)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.postDetailSheet)
            }
        }
        .fullScreenCover(isPresented: cameraPresentation) {
            CameraImagePicker(
                onCapture: viewModel.handleCapturedImage,
                onCancel: viewModel.cancelCamera
            )
            .ignoresSafeArea()
        }
        .alert("マッチしました！", isPresented: $viewModel.showMatchAlert) {
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
            get: { chatViewModel.conversationToOpen != nil },
            set: { isPresented in
                if !isPresented {
                    chatViewModel.clearOpenedConversation()
                }
            }
        )
    }

    private var cameraPresentation: Binding<Bool> {
        Binding(
            get: { viewModel.isCameraPresented },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelCamera()
                }
            }
        )
    }
}
