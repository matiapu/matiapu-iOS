//
//  MapView.swift
//  matiapu
//

import SwiftUI

struct MapView: View {
    @Bindable var viewModel: MapViewModel
    @State private var isMapReady = false

    var body: some View {
        ZStack(alignment: .top) {
            if isMapReady {
                GoogleMapView(posts: viewModel.posts)
                    .ignoresSafeArea()
            } else {
                AppColors.postScreenBackground
                    .ignoresSafeArea()
            }

            VStack(spacing: AppSpacing.mapFilterSpacing) {
                filterButtons

                if viewModel.isLoading {
                    loadingBanner
                }

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, 8)
        }
        .task {
            isMapReady = true
            await viewModel.loadPosts()
        }
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
    MapView(viewModel: MapViewModel(postRepository: MockPostRepository()))
}
