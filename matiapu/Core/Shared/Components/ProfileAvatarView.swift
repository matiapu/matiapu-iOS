//
//  ProfileAvatarView.swift
//  matiapu
//

import SwiftUI

struct ProfileAvatarView: View {
    let imageURL: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        placeholder
                            .overlay {
                                ProgressView()
                                    .controlSize(.small)
                            }
                    @unknown default:
                        placeholder
                    }
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
}
