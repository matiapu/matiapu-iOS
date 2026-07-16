//
//  ProfileAvatarView.swift
//  matiapu
//

import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let imageURL: String?
    let size: CGFloat
    /// 自分のアイコン表示時など、UID ベースのローカルキャッシュを優先する場合に指定する。
    var userID: String? = nil

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                placeholder
                    .overlay {
                        ProgressView()
                            .controlSize(.small)
                    }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(AppColors.postDetailAvatarBorder, lineWidth: 1)
        }
        .task(id: loadTaskID) {
            await loadImage()
        }
    }

    private var loadTaskID: String {
        "\(userID ?? "")|\(imageURL ?? "")"
    }

    private var placeholder: some View {
        Circle()
            .fill(AppColors.avatarPlaceholder)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.38))
                    .foregroundStyle(AppColors.authIconMuted)
            }
    }

    @MainActor
    private func loadImage() async {
        if let userID, let cached = LocalProfileImageStore.shared.image(forUID: userID) {
            image = cached
            isLoading = false
            return
        }

        guard let imageURL,
              let url = URL(string: imageURL),
              !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            image = nil
            isLoading = false
            return
        }

        if let cached = LocalProfileImageStore.shared.image(forURL: imageURL) {
            image = cached
            isLoading = false
            return
        }

        isLoading = image == nil
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let downloaded = UIImage(data: data) else {
                if image == nil {
                    image = nil
                }
                return
            }

            LocalProfileImageStore.shared.save(data: data, forURL: imageURL, uid: userID)
            image = downloaded
        } catch {
            // 既存のローカル表示があれば維持する
        }
    }
}
