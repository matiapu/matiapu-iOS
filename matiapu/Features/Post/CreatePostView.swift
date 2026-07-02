//
//  CreatePostView.swift
//  matiapu
//

import SwiftUI

struct CreatePostView: View {
    @Bindable var viewModel: CreatePostViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case body
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.createPostSectionSpacing) {
                CreatePostPhotoPreview(
                    sourceImage: viewModel.capturedImage,
                    maxWidth: AppSize.postCardWidth,
                    maxHeight: AppSize.createPostPhotoMaxHeight
                )
                titleSection
                bodySection
                CreatePostTagSection(selectedTag: $viewModel.selectedTag)
                locationSection
                if let submitError = viewModel.submitError {
                    submitErrorSection(submitError)
                }
                submitButton
            }
            .frame(maxWidth: AppSize.postCardWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.createPostTop)
            .padding(.bottom, AppSpacing.createPostBottom)
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            await viewModel.resolveLocationIfNeeded()
        }
        .background(AppColors.postScreenBackgroundGradient.ignoresSafeArea())
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
            fieldLabel("タイトル")

            TextField("", text: $viewModel.title, prompt: titlePrompt)
                .font(AppTypography.createPostField)
                .foregroundStyle(Color.primary)
                .focused($focusedField, equals: .title)
                .padding(.horizontal, AppSpacing.createPostFieldHorizontal)
                .frame(maxWidth: .infinity)
                .frame(height: AppSize.createPostTitleFieldHeight)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.createPostFieldBackground)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
            fieldLabel("本文")

            TextField("", text: $viewModel.body, prompt: bodyPrompt, axis: .vertical)
                .font(AppTypography.createPostField)
                .foregroundStyle(Color.primary)
                .lineLimit(6...)
                .focused($focusedField, equals: .body)
                .padding(.horizontal, AppSpacing.createPostFieldHorizontal)
                .padding(.vertical, AppSpacing.createPostBodyFieldVertical)
                .frame(maxWidth: .infinity, minHeight: AppSize.createPostBodyFieldMinHeight, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.createPostBodyField, style: .continuous)
                        .fill(AppColors.createPostFieldBackground)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var locationSection: some View {
        if let message = viewModel.locationStatusMessage {
            Text(message)
                .font(AppTypography.createPostTag)
                .foregroundStyle(AppColors.createPostLocationWarning)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let location = viewModel.capturedLocation {
            Text("位置情報を取得しました（\(formattedCoordinate(location))）")
                .font(AppTypography.createPostTag)
                .foregroundStyle(AppColors.onImageText.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func submitErrorSection(_ message: String) -> some View {
        Text(message)
            .font(AppTypography.createPostTag)
            .foregroundStyle(AppColors.createPostLocationWarning)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedCoordinate(_ location: PostLocation) -> String {
        String(format: "%.5f, %.5f", location.latitude, location.longitude)
    }

    private var submitButton: some View {
        Button {
            Task {
                await viewModel.submit()
            }
        } label: {
            Group {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(AppColors.onTagText)
                } else {
                    Text("投稿する")
                }
            }
            .font(AppTypography.createPostSubmit)
            .foregroundStyle(AppColors.onTagText)
            .frame(maxWidth: .infinity)
            .frame(height: AppSize.createPostSubmitHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.createPostFieldBackground)
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit && !viewModel.isSubmitting)
        .opacity(viewModel.canSubmit || viewModel.isSubmitting ? 1 : 0.55)
        .padding(.top, AppSpacing.createPostSubmitTop)
        .frame(maxWidth: .infinity)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.createPostLabel)
            .foregroundStyle(AppColors.onImageText)
    }

    private var titlePrompt: Text {
        Text("タイトルを入力")
            .foregroundStyle(AppColors.createPostPlaceholder)
    }

    private var bodyPrompt: Text {
        Text("本文を入力")
            .foregroundStyle(AppColors.createPostPlaceholder)
    }
}

private struct CreatePostPhotoPreview: View {
    let sourceImage: UIImage
    let maxWidth: CGFloat
    let maxHeight: CGFloat

    @Environment(\.displayScale) private var displayScale
    @State private var displayImage: UIImage?

    var body: some View {
        let image = displayImage ?? sourceImage
        let fittedSize = fittedImageSize(
            image: image,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )

        Image(uiImage: image)
            .resizable()
            .frame(width: fittedSize.width, height: fittedSize.height)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.createPostPhoto, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.createPostPhoto, style: .continuous)
                    .stroke(AppColors.onImageText, lineWidth: 2)
            }
            .frame(maxWidth: .infinity)
            .task(id: downsampleTaskID) {
                let maxPixelSize = ImageDownsampler.maxPixelSize(
                    for: CGSize(width: maxWidth, height: maxHeight),
                    scale: displayScale
                )
                guard maxPixelSize > 0 else { return }

                let downsampled = ImageDownsampler.downsample(
                    image: sourceImage,
                    maxPixelSize: maxPixelSize
                )
                if let downsampled {
                    displayImage = downsampled
                }
            }
    }

    private var downsampleTaskID: String {
        "\(ObjectIdentifier(sourceImage).hashValue)-\(maxWidth)-\(maxHeight)-\(displayScale)"
    }

    private func fittedImageSize(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGSize(width: maxWidth, height: maxHeight)
        }

        let scale = min(maxWidth / imageSize.width, maxHeight / imageSize.height)
        return CGSize(
            width: floor(imageSize.width * scale),
            height: floor(imageSize.height * scale)
        )
    }
}

private struct CreatePostTagSection: View {
    @Binding var selectedTag: MapFilter

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
            Text("タグ")
                .font(AppTypography.createPostLabel)
                .foregroundStyle(AppColors.onImageText)

            HStack(spacing: AppSpacing.createPostTagSpacing) {
                ForEach(MapFilter.allCases, id: \.self) { tag in
                    tagButton(tag)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tagButton(_ tag: MapFilter) -> some View {
        let isSelected = selectedTag == tag

        return Button {
            selectedTag = tag
        } label: {
            Text(tag.title)
                .font(AppTypography.createPostTag)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.createPostTagVertical)
                .padding(.horizontal, AppSpacing.createPostTagHorizontal)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? tag.pinColor : AppColors.mapFilterUnselected)
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(tag.pinColor, lineWidth: isSelected ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreatePostView(viewModel: .preview())
}
