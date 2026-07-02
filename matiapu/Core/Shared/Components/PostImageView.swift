//
//  PostImageView.swift
//  matiapu
//

import SwiftUI
import UIKit
import ImageIO

/// 投稿画像を解決して表示する共通ビュー。
/// 優先順位は「imageData → imageURL → Asset 画像(imageName) → プレースホルダー」。
struct PostImageView: View {
    let post: Post
    var contentMode: ContentMode = .fill
    /// `.fit` 表示時に利用可能な領域。詳細画面などで最大表示サイズを安定させるために指定する。
    var fitBounds: CGSize? = nil

    var body: some View {
        if let imageData = post.imageData {
            LocalPostImage(
                data: imageData,
                contentMode: contentMode,
                fitBounds: fitBounds
            )
        } else if let imageURL = Self.normalizedImageURL(post.imageURL) {
            RemotePostImage(
                url: imageURL,
                cacheKey: imageURL.absoluteString,
                contentMode: contentMode,
                fitBounds: fitBounds
            )
        } else if let imageName = post.imageName, !imageName.isEmpty {
            AssetPostImage(
                imageName: imageName,
                contentMode: contentMode,
                fitBounds: fitBounds
            )
        } else {
            PostImagePlaceholder()
        }
    }

    private static func normalizedImageURL(_ value: String?) -> URL? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return URL(string: trimmed)
    }
}

// MARK: - Local (imageData)

/// メモリ上の画像データを即時表示する（元の `UIImage(data:)` 相当）。
private struct LocalPostImage: View {
    let data: Data
    let contentMode: ContentMode
    let fitBounds: CGSize?

    var body: some View {
        if let uiImage = UIImage(data: data) {
            postImage(uiImage)
        } else {
            PostImagePlaceholder()
        }
    }

    @ViewBuilder
    private func postImage(_ uiImage: UIImage) -> some View {
        if contentMode == .fit, let fitBounds {
            let size = ImageFitting.size(for: uiImage.size, in: fitBounds)
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: size.width, height: size.height)
                .frame(maxWidth: .infinity)
        } else {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }
}

// MARK: - Remote (imageURL)

private struct RemotePostImage: View {
    let url: URL
    let cacheKey: String
    let contentMode: ContentMode
    let fitBounds: CGSize?

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var didFail = false
    @State private var layoutSize: CGSize = .zero
    @State private var displayPixelSize: CGSize?
    @State private var fetchedData: Data?
    @Environment(\.displayScale) private var displayScale

    private var displayAspectRatio: CGFloat? {
        guard let displayPixelSize, displayPixelSize.height > 0 else { return nil }
        return displayPixelSize.width / displayPixelSize.height
    }

    private var explicitFitSize: CGSize? {
        guard contentMode == .fit,
              let fitBounds,
              fitBounds.width > 0,
              fitBounds.height > 0 else {
            return nil
        }

        if let displayAspectRatio {
            return ImageFitting.size(forAspectRatio: displayAspectRatio, in: fitBounds)
        }

        return fitBounds
    }

    var body: some View {
        Group {
            if let explicitFitSize {
                fittedContent(size: explicitFitSize)
                    .frame(maxWidth: .infinity)
            } else {
                flexibleContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipped()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            layoutSize = newSize
        }
        .task(id: loadTaskID) {
            await loadImage()
        }
    }

    private var loadTaskID: String {
        let decodeSize = effectiveDecodeSize()
        let aspectKey = displayAspectRatio.map { String(format: "%.4f", $0) } ?? "unknown"
        return "\(cacheKey)-\(Int(decodeSize.width.rounded()))x\(Int(decodeSize.height.rounded()))-\(aspectKey)"
    }

    private func fittedContent(size: CGSize) -> some View {
        ZStack {
            PostImagePlaceholder()
                .frame(width: size.width, height: size.height)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: size.width, height: size.height)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else if didFail {
                failedIndicator
            }
        }
    }

    private var flexibleContent: some View {
        ZStack {
            placeholderView

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else if didFail {
                failedIndicator
            }
        }
    }

    @ViewBuilder
    private var placeholderView: some View {
        if contentMode == .fit, let displayAspectRatio {
            PostImagePlaceholder()
                .aspectRatio(displayAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        } else {
            PostImagePlaceholder()
        }
    }

    private var failedIndicator: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.white.opacity(0.8))
    }

    private func effectiveDecodeSize() -> CGSize {
        if let explicitFitSize {
            return explicitFitSize
        }
        if layoutSize.width > 0, layoutSize.height > 0 {
            return layoutSize
        }
        if let fitBounds, fitBounds.width > 0, fitBounds.height > 0 {
            return fitBounds
        }
        return CGSize(width: AppSize.postCardWidth, height: AppSize.postCardHeight)
    }

    @MainActor
    private func loadImage() async {
        let decodeSize = effectiveDecodeSize()
        let maxPixelSize = ImageDownsampler.maxPixelSize(for: decodeSize, scale: displayScale)
        guard maxPixelSize > 0 else { return }

        let imageCacheKey = "\(cacheKey)-\(maxPixelSize)"
        if let cached = PostImageMemoryCache.shared.image(forKey: imageCacheKey) {
            image = cached
            didFail = false
            if displayPixelSize == nil {
                displayPixelSize = cached.size
            }
            return
        }

        isLoading = image == nil
        didFail = false
        defer { isLoading = false }

        do {
            let data = try await loadDataOnce()
            if displayPixelSize == nil {
                displayPixelSize = ImageDownsampler.displayPixelSize(data: data)
            }

            let decoded = ImageDownsampler.downsample(data: data, maxPixelSize: maxPixelSize)
                ?? UIImage(data: data)
            guard let decoded else {
                image = nil
                didFail = true
                return
            }

            PostImageMemoryCache.shared.insert(decoded, forKey: imageCacheKey)
            image = decoded
            didFail = false
        } catch {
            image = nil
            didFail = true
        }
    }

    private func loadDataOnce() async throws -> Data {
        if let fetchedData {
            return fetchedData
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        fetchedData = data
        return data
    }
}

// MARK: - Asset (imageName)

private struct AssetPostImage: View {
    let imageName: String
    let contentMode: ContentMode
    let fitBounds: CGSize?

    var body: some View {
        if contentMode == .fit,
           let fitBounds,
           let uiImage = UIImage(named: imageName) {
            let size = ImageFitting.size(for: uiImage.size, in: fitBounds)
            Image(imageName)
                .resizable()
                .frame(width: size.width, height: size.height)
                .frame(maxWidth: .infinity)
        } else {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }
}

// MARK: - Shared

private enum ImageFitting {
    static func size(for imageSize: CGSize, in bounds: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return bounds
        }
        return size(forAspectRatio: imageSize.width / imageSize.height, in: bounds)
    }

    static func size(forAspectRatio aspectRatio: CGFloat, in bounds: CGSize) -> CGSize {
        guard bounds.width > 0, bounds.height > 0, aspectRatio > 0 else {
            return bounds
        }

        let boundsRatio = bounds.width / bounds.height
        if aspectRatio > boundsRatio {
            let width = bounds.width
            return CGSize(width: width, height: floor(width / aspectRatio))
        }

        let height = bounds.height
        return CGSize(width: floor(height * aspectRatio), height: height)
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

private final class PostImageMemoryCache {
    static let shared = PostImageMemoryCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 120
        cache.totalCostLimit = 80 * 1024 * 1024
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
