//
//  PostView.swift
//  matiapu
//

import SwiftUI

struct PostView: View {
    @Bindable var viewModel: PostViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppColors.postScreenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                postCardContent
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            createPostButton
                .padding(.trailing, AppSpacing.fabTrailing)
                .padding(.top, AppSpacing.screenTop)
        }
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
        .sheet(isPresented: createPostPresentation) {
            if let createPostViewModel = viewModel.createPostViewModel {
                CreatePostView(viewModel: createPostViewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
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

    private var createPostPresentation: Binding<Bool> {
        Binding(
            get: { viewModel.isCreatePostPresented },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissCreatePost()
                }
            }
        )
    }

    @ViewBuilder
    private var postCardContent: some View {
        if let post = viewModel.post {
            SwipeablePostCard(
                post: post,
                display: .postFeed,
                isBodyExpanded: viewModel.isBodyExpanded,
                onSeeMore: viewModel.toggleBodyExpanded,
                onSwipe: viewModel.handleSwipe
            )
            .id(post.id)
        } else if viewModel.isLoading {
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

    private var createPostButton: some View {
        Button(action: viewModel.openCreatePost) {
            Image(systemName: "plus")
                .font(AppTypography.fabIcon)
                .foregroundStyle(AppColors.onFABIcon)
                .frame(width: AppSize.fab, height: AppSize.fab)
                .background(Circle().fill(AppColors.postFABBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PostView(viewModel: .preview)
}
