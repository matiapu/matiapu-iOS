//
//  PostImageView.swift
//  matiapu
//

import SwiftUI
import UIKit

/// 投稿画像を解決して表示する共通ビュー。
/// 優先順位は「imageData → imageURL → Asset 画像(imageName) → プレースホルダー」。
struct PostImageView: View {
    let post: Post
    var contentMode: ContentMode = .fill

    var body: some View {
        if let uiImage = resolvedLocalImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if let imageURL = post.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    PostImagePlaceholder()
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    PostImagePlaceholder()
                }
            }
        } else if let imageName = post.imageName, !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            PostImagePlaceholder()
        }
    }

    private var resolvedLocalImage: UIImage? {
        guard let data = post.imageData else { return nil }
        return UIImage(data: data)
    }
}

/// 画像が無い投稿用のプレースホルダー。
struct PostImagePlaceholder: View {
    var body: some View {
        LinearGradient(
            colors: [AppColors.postCardPlaceholderTop, AppColors.postCardPlaceholderBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
