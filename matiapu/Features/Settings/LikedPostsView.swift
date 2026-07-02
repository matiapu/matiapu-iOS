//
//  LikedPostsView.swift
//  matiapu
//

import SwiftUI

struct LikedPostsView: View {
  @Bindable var viewModel: LikedPostsViewModel
  let dependencies: AppDependencies
  @State private var selectedPost: Post?

  var body: some View {
    SettingsScreenLayout {
      GeometryReader { geometry in
        ScrollView {
          VStack(spacing: AppSpacing.settingsSectionSpacing) {
            headerCard
            SettingsSearchBar(placeholder: "検索", text: $viewModel.searchText)
            postGrid(width: geometry.size.width)
          }
          .padding(.horizontal, AppSpacing.settingsHorizontal)
          .padding(.top, AppSpacing.settingsContentTop)
          .padding(.bottom, AppSpacing.settingsTabBarInset)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
      }
    }
    .task {
      await viewModel.loadPosts()
    }
    .sheet(item: $selectedPost) { post in
      PostDetailView(post: post, display: .postDetail, dependencies: dependencies)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppRadius.postDetailSheet)
    }
  }

  private var headerCard: some View {
    SettingsCard {
      VStack(spacing: AppSpacing.settingsHeaderCardPadding) {
        Text("いいねした投稿")
          .font(AppTypography.settingsHeaderTitle)
          .foregroundStyle(AppColors.settingsCardText)
          .frame(maxWidth: .infinity)

        HStack {
          Spacer(minLength: 0)

          Menu {
            ForEach(LikedPostSortOrder.allCases) { order in
              Button(order.title) {
                viewModel.sortOrder = order
              }
            }
          } label: {
            HStack(spacing: 6) {
              Text(viewModel.sortOrder.title)
                .font(AppTypography.settingsSortButton)
                .foregroundStyle(AppColors.onTagText)

              Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.onTagText)
            }
            .padding(.horizontal, AppSpacing.settingsSortButtonHorizontal)
            .padding(.vertical, AppSpacing.settingsSortButtonVertical)
            .background(
              RoundedRectangle(cornerRadius: AppRadius.settingsSortButton, style: .continuous)
                .fill(AppColors.settingsSortButtonBackground)
            )
          }
        }
      }
      .padding(AppSpacing.settingsHeaderCardPadding)
    }
  }

  @ViewBuilder
  private func postGrid(width: CGFloat) -> some View {
    if viewModel.isLoading && viewModel.posts.isEmpty {
      ProgressView()
        .tint(AppColors.onImageText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.profileGridLoadingVertical)
    } else if viewModel.filteredPosts.isEmpty {
      ContentUnavailableView(
        "いいねした投稿がありません",
        systemImage: "heart.slash",
        description: Text("投稿にいいねするとここに表示されます")
      )
      .frame(maxWidth: .infinity)
      .padding(.vertical, AppSpacing.profileGridLoadingVertical)
    } else {
      let spacing = AppSpacing.profileGridSpacing
      let columns = AppSize.profileGridColumns
      let horizontalPadding = AppSpacing.settingsHorizontal * 2
      let cellSize = floor(
        (width - horizontalPadding - spacing * CGFloat(columns - 1)) / CGFloat(columns)
      )
      let gridColumns = Array(
        repeating: GridItem(.fixed(cellSize), spacing: spacing),
        count: columns
      )

      LazyVGrid(columns: gridColumns, spacing: spacing) {
        ForEach(viewModel.filteredPosts) { post in
          Button {
            selectedPost = post
          } label: {
            PostImageView(post: post, contentMode: .fill)
              .frame(width: cellSize, height: cellSize)
              .clipped()
          }
          .buttonStyle(.plain)
          .accessibilityLabel(post.title)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    LikedPostsView(viewModel: .preview, dependencies: .live)
  }
}
