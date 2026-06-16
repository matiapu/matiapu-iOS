//
//  MapPinCalloutView.swift
//  matiapu
//

import SwiftUI

struct MapPinCalloutView: View {
    let post: Post
    let onOpenDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.mapCalloutSpacing) {
            Text(displayTitle)
                .font(AppTypography.mapCalloutTitle)
                .foregroundStyle(AppColors.postDetailText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onOpenDetail) {
                Text("詳細を見る")
                    .font(AppTypography.mapCalloutButton)
                    .foregroundStyle(AppColors.onTagText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.mapCalloutButtonVertical)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppColors.postTag)
                    )
            }
            .buttonStyle(.plain)
            .highPriorityGesture(
                TapGesture().onEnded { onOpenDetail() }
            )
        }
        .padding(AppSpacing.mapCalloutPadding)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.mapCallout, style: .continuous)
                .fill(AppColors.postDetailBackground)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, AppSpacing.mapCalloutBottom)
    }

    private var displayTitle: String {
        post.title.isEmpty ? post.tag : post.title
    }
}

#Preview {
    MapPinCalloutView(
        post: PostPreviewData.mapPosts[0],
        onOpenDetail: {}
    )
}
