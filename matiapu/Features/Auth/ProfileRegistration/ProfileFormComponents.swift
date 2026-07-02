//
//  ProfileFormComponents.swift
//  matiapu
//

import PhotosUI
import SwiftUI

struct ProfileRequiredBadge: View {
    var body: some View {
        Text("必須")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.authPrimary)
            )
    }
}

struct ProfileFieldLabel: View {
    let title: String
    var isRequired = false

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(AppTypography.authFieldLabel)
                .foregroundStyle(AppColors.authLabel)
                .kerning(0.6)

            if isRequired {
                ProfileRequiredBadge()
            }

            Spacer()
        }
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    var prompt: String
    var isRequired = false
    var keyboardType: UIKeyboardType = .default
    var isReadOnly = false
    var showsLock = false
    var helperText: String?
    var maxLength: Int?
    var showsCounter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileFieldLabel(title: title, isRequired: isRequired)

            HStack(spacing: 12) {
                TextField("", text: $text, prompt: Text(prompt).foregroundStyle(AppColors.authPlaceholder))
                    .font(AppTypography.authField)
                    .foregroundStyle(isReadOnly ? AppColors.authSubtitle : AppColors.authHeading)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(isReadOnly)

                if showsLock {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.authIconMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(isReadOnly ? AppColors.authInputBackground.opacity(0.7) : AppColors.authInputBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppColors.authInputBorder, lineWidth: 1)
            )
            .onChange(of: text) { _, newValue in
                guard let maxLength, newValue.count > maxLength else { return }
                text = String(newValue.prefix(maxLength))
            }

            if let helperText {
                Text(helperText)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.authSubtitle)
            }

            if showsCounter, let maxLength {
                Text("\(text.count)/\(maxLength)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.authSubtitle)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct ProfileTextEditor: View {
    let title: String
    @Binding var text: String
    var prompt: String
    var isRequired = false
    var minLength: Int?
    var maxLength: Int
    var helperText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileFieldLabel(title: title, isRequired: isRequired)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(prompt)
                        .font(AppTypography.authField)
                        .foregroundStyle(AppColors.authPlaceholder)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $text)
                    .font(AppTypography.authField)
                    .foregroundStyle(AppColors.authHeading)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 140)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.authInputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColors.authInputBorder, lineWidth: 1)
            )
            .onChange(of: text) { _, newValue in
                if newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }

            if let helperText {
                Text(helperText)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.authSubtitle)
            }

            if let minLength, text.count < minLength, !text.isEmpty {
                Text("※最低\(minLength)文字必要です")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }

            Text("\(text.count)/\(maxLength)")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.authSubtitle)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct ProfileImagePickerSection: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(AppColors.authInputBackground)
                        .frame(width: 96, height: 96)
                        .overlay {
                            if let selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppColors.authIconMuted)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(AppColors.authInputBorder, lineWidth: 1)
                        )

                    Circle()
                        .fill(AppColors.authPrimaryAction)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
            }

            Text("プロフィール画像（任意）")
                .font(AppTypography.authFieldLabel)
                .foregroundStyle(AppColors.authLabel)

            Text("マッチング率が向上します")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.authSubtitle)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}

struct ProfilePrivacyNotice: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.authPrimaryAction)

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.authSubtitle)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.authInputBackground)
        )
    }
}

struct ProfileNextButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                    Image(systemName: "arrow.right")
                }
            }
            .font(AppTypography.authPrimaryButton)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.authPrimary)
            )
        }
        .disabled(isLoading)
    }
}
