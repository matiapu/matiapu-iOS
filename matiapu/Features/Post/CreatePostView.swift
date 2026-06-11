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
                photoPreview
                titleSection
                bodySection
                tagSection
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
        .background(AppColors.postScreenBackground.ignoresSafeArea())
    }

    private var photoPreview: some View {
        Color.clear
            .aspectRatio(AppSize.postCardAspectRatio, contentMode: .fit)
            .frame(maxWidth: AppSize.postCardWidth)
            .frame(maxWidth: .infinity)
            .overlay {
                Image(uiImage: viewModel.capturedImage)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.createPostPhoto, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.createPostPhoto, style: .continuous)
                    .strokeBorder(AppColors.onImageText, lineWidth: 2)
            }
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

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
            fieldLabel("タグ")

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
            Text("投稿する")
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
        .disabled(!viewModel.canSubmit)
        .opacity(viewModel.canSubmit ? 1 : 0.55)
        .padding(.top, AppSpacing.createPostSubmitTop)
        .frame(maxWidth: .infinity)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.createPostLabel)
            .foregroundStyle(AppColors.onImageText)
    }

    private func tagButton(_ tag: MapFilter) -> some View {
        let isSelected = viewModel.selectedTag == tag

        return Button {
            viewModel.selectedTag = tag
        } label: {
            Text(tag.title)
                .font(AppTypography.createPostTag)
                .foregroundStyle(AppColors.onTagText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.createPostTagVertical)
                .padding(.horizontal, AppSpacing.createPostTagHorizontal)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                                ? AppColors.createPostTagSelected
                                : AppColors.createPostTagUnselected
                        )
                )
        }
        .buttonStyle(.plain)
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

#Preview {
    CreatePostView(viewModel: .preview())
}
