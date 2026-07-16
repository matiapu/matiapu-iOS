//
//  MapView.swift
//  matiapu
//

import SwiftUI

struct MapView: View {
    @Bindable var viewModel: MapViewModel
    @Bindable var postViewModel: PostViewModel
    var isLocationTrackingEnabled = true
    @Environment(\.appDependencies) private var dependencies
    @State private var hasLoadedInitial = false

    var body: some View {
        ZStack(alignment: .top) {
            if let mapCenter = viewModel.mapCenter {
                GoogleMapView(
                    posts: viewModel.posts,
                    shelters: viewModel.shelters,
                    disasters: viewModel.disasters,
                    mapCenter: mapCenter,
                    municipalityScope: viewModel.municipalityScope,
                    selectedPostID: viewModel.selectedPost?.id,
                    selectedShelterID: viewModel.selectedShelter?.id,
                    isLocationTrackingEnabled: isLocationTrackingEnabled,
                    onPostTap: viewModel.selectPost,
                    onShelterTap: viewModel.selectShelter,
                    onMapTap: viewModel.dismissMapSelection
                )
                .ignoresSafeArea()
            } else if hasLoadedInitial, let centerErrorMessage = viewModel.centerErrorMessage {
                ContentUnavailableView(
                    centerErrorMessage,
                    systemImage: "map",
                    description: Text("設定画面から登録地域を確認してください。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.postScreenBackgroundGradient)
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
                } else if let selectedShelter = viewModel.selectedShelter {
                    MapShelterCalloutView(shelter: selectedShelter)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPost?.id)
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedShelter?.id)
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
                onCapture: postViewModel.handleCapturedImage,
                onCancel: postViewModel.cancelCamera
            )
            .ignoresSafeArea()
        }
        .task {
            async let posts: Void = viewModel.loadPosts()
            async let center: Void = viewModel.loadInitialCenter()
            _ = await (posts, center)
            hasLoadedInitial = true
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
