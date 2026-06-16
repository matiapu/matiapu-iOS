//
//  PostView.swift
//  matiapu
//

import SwiftUI

struct PostView: View {
    @Bindable var viewModel: PostViewModel

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
        .sheet(item: $viewModel.detailPost) { post in
            PostDetailView(post: post, display: .postDetail)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.postDetailSheet)
        }
        .fullScreenCover(isPresented: cameraPresentation) {
            CameraImagePicker(
                onCapture: viewModel.handleCapturedImage,
                onCancel: viewModel.cancelCamera
            )
            .ignoresSafeArea()
        }
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

#Preview {
    PostView(viewModel: .preview)
}
