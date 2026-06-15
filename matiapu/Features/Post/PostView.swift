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
            detailDisplay: .postDetail,
            isLoading: viewModel.isLoading,
            detailPost: $viewModel.detailPost,
            onSeeMore: viewModel.openDetail,
            onSwipe: viewModel.handleSwipe,
            overlay: {
                CreatePostFAB(action: viewModel.openCreatePost)
            }
        )
        .task {
            await viewModel.loadPosts()
        }
        .fullScreenCover(isPresented: cameraPresentation) {
            CameraImagePicker(
                onCapture: viewModel.handleCapturedImage,
                onCancel: viewModel.cancelCamera
            )
            .ignoresSafeArea()
        }
        .sheet(item: createPostPresentation) { createPostViewModel in
            CreatePostView(viewModel: createPostViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

    private var createPostPresentation: Binding<CreatePostViewModel?> {
        Binding(
            get: { viewModel.createPostViewModel },
            set: { newValue in
                if newValue == nil {
                    viewModel.dismissCreatePost()
                }
            }
        )
    }
}

#Preview {
    PostView(viewModel: .preview)
}
