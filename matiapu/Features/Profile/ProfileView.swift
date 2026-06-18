//
//  ProfileView.swift
//  matiapu
//

import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @Bindable var mapViewModel: MapViewModel
    let dependencies: AppDependencies
    @State private var selectedPost: Post?
    @State private var showsSettings = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.postScreenBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection(
                        width: geometry.size.width,
                        height: geometry.size.height * AppSize.profileHeaderHeightRatio
                    )

                    ScrollView {
                        postGridSection(width: geometry.size.width)
                            .padding(.bottom, AppSpacing.profileTabBarInset)
                    }
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.loadProfile()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post, display: .postDetail)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.postDetailSheet)
        }
        .fullScreenCover(isPresented: $showsSettings, onDismiss: {
            Task { await viewModel.loadProfile() }
        }) {
            SettingsFlowView(dependencies: dependencies, mapViewModel: mapViewModel)
        }
    }

    private func headerSection(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: AppSpacing.profileHeaderSpacing) {
                Spacer(minLength: 0)

                Circle()
                    .fill(AppColors.avatarPlaceholder)
                    .frame(width: AppSize.profileAvatar, height: AppSize.profileAvatar)

                VStack(spacing: AppSpacing.profileNameSpacing) {
                    Text(viewModel.profile?.registeredArea ?? " ")
                        .font(AppTypography.profileArea)
                        .foregroundStyle(AppColors.onImageText)

                    Text(viewModel.profile?.displayName ?? "読み込み中...")
                        .font(AppTypography.profileName)
                        .foregroundStyle(AppColors.onImageText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, AppSpacing.profileNameHorizontal)
                }

                Spacer(minLength: 0)
            }
            .frame(width: width, height: height)

            Button {
                showsSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(AppTypography.profileSettingsIcon)
                    .foregroundStyle(AppColors.onImageText)
                    .frame(width: AppSize.profileSettingsButton, height: AppSize.profileSettingsButton)
            }
            .buttonStyle(.plain)
            .padding(.trailing, AppSpacing.profileSettingsTrailing)
            .padding(.top, AppSpacing.profileSettingsTop)
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private func postGridSection(width: CGFloat) -> some View {
        if viewModel.isLoading && viewModel.posts.isEmpty {
            ProgressView()
                .tint(AppColors.onImageText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.profileGridLoadingVertical)
        } else if viewModel.posts.isEmpty {
            ContentUnavailableView(
                "まだ投稿がありません",
                systemImage: "photo.on.rectangle.angled",
                description: Text("投稿するとここに表示されます")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.profileGridLoadingVertical)
        } else {
            let spacing = AppSpacing.profileGridSpacing
            let columns = AppSize.profileGridColumns
            let cellSize = floor(
                (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            )
            let gridColumns = Array(
                repeating: GridItem(.fixed(cellSize), spacing: spacing),
                count: columns
            )

            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(viewModel.posts) { post in
                    Button {
                        selectedPost = post
                    } label: {
                        postThumbnail(for: post, size: cellSize)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(post.title)
                }
            }
            .background(AppColors.postDetailBackground)
        }
    }

    @ViewBuilder
    private func postThumbnail(for post: Post, size: CGFloat) -> some View {
        PostImageView(post: post, contentMode: .fill)
            .frame(width: size, height: size)
            .clipped()
    }
}

#Preview {
    ProfileView(
        viewModel: .preview,
        mapViewModel: MapViewModel(postRepository: MockPostRepository()),
        dependencies: .live
    )
}
