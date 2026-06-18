//
//  MapView.swift
//  matiapu
//

import SwiftUI

struct MapView: View {
    @Bindable var viewModel: MapViewModel
    @Bindable var postViewModel: PostViewModel
    @State private var isMapReady = false

    var body: some View {
        ZStack(alignment: .top) {
            if isMapReady {
                GoogleMapView(
                    posts: viewModel.posts,
                    mapCenter: viewModel.mapCenter,
                    selectedPostID: viewModel.selectedPost?.id,
                    onMarkerTap: viewModel.selectPost,
                    onMapTap: viewModel.dismissSelectedPost
                )
                .ignoresSafeArea()
            } else {
                AppColors.postScreenBackgroundGradient
                    .ignoresSafeArea()
            }

            VStack(spacing: AppSpacing.mapFilterSpacing) {
                topControls

                if viewModel.isLoading {
                    loadingBanner
                }

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                }

                Spacer()

                if let selectedPost = viewModel.selectedPost {
                    MapPinCalloutView(
                        post: selectedPost,
                        onOpenDetail: viewModel.openDetail
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPost?.id)
        }
        .sheet(item: $viewModel.detailPost) { post in
            PostDetailView(post: post, display: .postDetail)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.postDetailSheet)
        }
        .fullScreenCover(isPresented: cameraPresentation) {
            CameraImagePicker(
                onCapture: postViewModel.handleCapturedImage,
                onCancel: postViewModel.cancelCamera
            )
            .ignoresSafeArea()
        }
        .task {
            isMapReady = true
            await viewModel.loadPosts()
        }
    }

    private var cameraPresentation: Binding<Bool> {
        Binding(
            get: { postViewModel.isCameraPresented },
            set: { isPresented in
                if !isPresented {
                    postViewModel.cancelCamera()
                }
            }
        )
    }

    private var topControls: some View {
        HStack(alignment: .center, spacing: AppSpacing.mapFilterSpacing) {
            filterButtons

            GlassFAB(systemImage: "plus", action: postViewModel.openCreatePost)
        }
        .padding(.top, AppSpacing.screenTop)
    }

    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.mapFilterSpacing) {
                allFilterButton

                ForEach(MapFilter.allCases, id: \.self) { filter in
                    categoryFilterButton(filter)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var allFilterButton: some View {
        let isSelected = viewModel.selectedFilter == nil

        return Button {
            viewModel.selectFilter(nil)
        } label: {
            Text("すべて")
                .font(AppTypography.mapFilter)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.vertical, AppSpacing.mapFilterVertical)
                .padding(.horizontal, AppSpacing.mapFilterHorizontal)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? MapCategoryStyle.allFilterColor : AppColors.mapFilterUnselected)
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(MapCategoryStyle.allFilterColor, lineWidth: isSelected ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
    }

    private func categoryFilterButton(_ filter: MapFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter

        return Button {
            viewModel.selectFilter(filter)
        } label: {
            Text(filter.title)
                .font(AppTypography.mapFilter)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.vertical, AppSpacing.mapFilterVertical)
                .padding(.horizontal, AppSpacing.mapFilterHorizontal)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? filter.pinColor : AppColors.mapFilterUnselected)
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(filter.pinColor, lineWidth: isSelected ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
    }

    private var loadingBanner: some View {
        Text("読み込み中...")
            .font(AppTypography.mapFilter)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, AppSpacing.mapFilterHorizontal)
            .padding(.vertical, AppSpacing.mapFilterVertical)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.mapFilterUnselected)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorBanner(_ message: String) -> some View {
        Text("エラー: \(message)")
            .font(AppTypography.mapFilter)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, AppSpacing.mapFilterHorizontal)
            .padding(.vertical, AppSpacing.mapFilterVertical)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.mapFilterUnselected)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MapView(
        viewModel: MapViewModel(postRepository: MockPostRepository()),
        postViewModel: .preview
    )
}
