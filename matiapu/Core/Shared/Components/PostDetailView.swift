//
//  PostDetailView.swift
//  matiapu
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    let display: PostCardDisplay
    let dependencies: AppDependencies

    @State private var commentViewModel: PostDetailViewModel?
    @State private var commentText = ""
    @FocusState private var isCommentFieldFocused: Bool

    private enum CommentInputScrollID: Hashable {
        case input
    }

    init(post: Post, display: PostCardDisplay, dependencies: AppDependencies) {
        self.post = post
        self.display = display
        self.dependencies = dependencies
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        heroImage(
                            maxHeight: geometry.size.height * AppSize.postDetailImageHeightRatio,
                            maxWidth: geometry.size.width
                        )
                        contentSection

                        if display.showsComments {
                            commentsSection
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onChange(of: commentViewModel?.replyingTo?.id) { _, replyTargetID in
                    guard replyTargetID != nil else { return }
                    isCommentFieldFocused = true
                    withAnimation {
                        scrollProxy.scrollTo(CommentInputScrollID.input, anchor: .center)
                    }
                }
            }
        }
        .background(AppColors.postDetailBackground)
        .task(id: post.id) {
            guard display.showsComments else { return }

            let useCases = dependencies.useCases
            let viewModel = PostDetailViewModel(
                post: post,
                loadPostComments: useCases.loadPostComments,
                submitPostComment: useCases.submitPostComment
            )
            commentViewModel = viewModel
            await viewModel.loadComments()
        }
    }

    @ViewBuilder
    private func heroImage(maxHeight: CGFloat, maxWidth: CGFloat) -> some View {
        Group {
            if post.imageData != nil || (post.imageName?.isEmpty == false) || post.imageURL != nil {
                PostImageView(
                    post: post,
                    contentMode: .fit,
                    fitBounds: CGSize(width: maxWidth, height: maxHeight)
                )
            } else {
                PostImagePlaceholder()
                    .frame(height: maxHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.postDetailImageBackground)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.postDetailSectionSpacing) {
            if display.showsAuthorName {
                authorRow
            }
            if display.showsTitle, !post.title.isEmpty {
                Text(post.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.postDetailText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if display.showsTag {
                tagLabel
            }
            Text(post.body)
                .font(AppTypography.cardBody)
                .foregroundStyle(AppColors.postDetailText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.postDetailHorizontal)
        .padding(.top, AppSpacing.postDetailTop)
        .padding(.bottom, display.showsComments ? AppSpacing.postDetailSectionSpacing : AppSpacing.postDetailBottom)
    }

    @ViewBuilder
    private var commentsSection: some View {
        if let commentViewModel {
            VStack(alignment: .leading, spacing: AppSpacing.postDetailSectionSpacing) {
                Divider()

                Text("コメント")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.postDetailText)

                commentInput(viewModel: commentViewModel)

                if commentViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if commentViewModel.rootComments.isEmpty {
                    Text("まだコメントはありません")
                        .font(AppTypography.cardBody)
                        .foregroundStyle(AppColors.postDetailSecondaryText)
                } else {
                    ForEach(commentViewModel.rootComments) { comment in
                        commentThread(comment, viewModel: commentViewModel)
                    }
                }

                if let errorMessage = commentViewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, AppSpacing.postDetailHorizontal)
            .padding(.bottom, AppSpacing.postDetailBottom)
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.postDetailSectionSpacing) {
                Divider()

                Text("コメント")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.postDetailText)

                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, AppSpacing.postDetailHorizontal)
            .padding(.bottom, AppSpacing.postDetailBottom)
        }
    }

    private func commentInput(viewModel: PostDetailViewModel) -> some View {
        let isCommentEmpty = commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return VStack(alignment: .leading, spacing: 8) {
            if let replyingTo = viewModel.replyingTo {
                HStack(spacing: 8) {
                    Text("\(replyingTo.authorDisplayName)さんに返信")
                        .font(.caption)
                        .foregroundStyle(AppColors.postDetailSecondaryText)

                    Spacer()

                    Button("キャンセル") {
                        viewModel.cancelReply()
                        isCommentFieldFocused = false
                    }
                    .font(.caption)
                    .foregroundStyle(AppColors.authPrimaryAction)
                }
            }

            HStack(spacing: 8) {
                TextField(
                    viewModel.replyingTo == nil ? "コメントを入力" : "返信を入力",
                    text: $commentText,
                    axis: .vertical
                )
                .focused($isCommentFieldFocused)
                .font(AppTypography.cardBody)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.postDetailImageBackground)
                )

                Button {
                    let text = commentText
                    Task {
                        if await viewModel.submitComment(text: text) {
                            commentText = ""
                        }
                    }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(AppColors.authPrimaryAction)
                    }
                }
                .disabled(viewModel.isSubmitting || isCommentEmpty)
            }
        }
        .id(CommentInputScrollID.input)
    }

    private func commentThread(_ rootComment: Comment, viewModel: PostDetailViewModel) -> some View {
        let replyCount = viewModel.replyCount(for: rootComment)
        let isExpanded = viewModel.isExpanded(rootComment)

        return VStack(alignment: .leading, spacing: 8) {
            commentRow(
                rootComment,
                isReplyTarget: viewModel.replyingTo?.id == rootComment.id,
                onTap: {
                    viewModel.startReply(to: rootComment)
                    isCommentFieldFocused = true
                }
            )

            if replyCount > 0 {
                if !isExpanded {
                    Button {
                        viewModel.toggleReplies(for: rootComment)
                    } label: {
                        Text("返信を見る(\(replyCount))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.authPrimaryAction)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, AppSize.avatar + AppSpacing.cardHeaderSpacing)
                } else {
                    ForEach(viewModel.replies(for: rootComment)) { reply in
                        commentRow(
                            reply,
                            isReply: true,
                            isReplyTarget: viewModel.replyingTo?.id == reply.id,
                            onTap: {
                                viewModel.startReply(to: reply)
                                isCommentFieldFocused = true
                            }
                        )
                    }

                    Button {
                        viewModel.toggleReplies(for: rootComment)
                    } label: {
                        Text("返信を隠す")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.postDetailSecondaryText)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, AppSize.avatar + AppSpacing.cardHeaderSpacing)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func commentRow(
        _ comment: Comment,
        isReply: Bool = false,
        isReplyTarget: Bool = false,
        onTap: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.cardHeaderSpacing) {
            if isReply {
                Spacer()
                    .frame(width: AppSize.avatar + AppSpacing.cardHeaderSpacing)
            }

            ProfileAvatarView(
                imageURL: comment.authorProfileImageURL,
                size: AppSize.avatar
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(comment.authorDisplayName)
                        .font(AppTypography.cardAuthorName)
                        .foregroundStyle(AppColors.postDetailText)

                    Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppColors.postDetailSecondaryText)
                }

                Text(comment.contentText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(AppColors.postDetailText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isReplyTarget ? AppColors.postDetailImageBackground : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var authorRow: some View {
        HStack(spacing: AppSpacing.cardHeaderSpacing) {
            if display.showsAvatar {
                Circle()
                    .fill(AppColors.avatarPlaceholder)
                    .overlay {
                        Circle()
                            .stroke(AppColors.postDetailAvatarBorder, lineWidth: 1)
                    }
                    .frame(width: AppSize.avatar, height: AppSize.avatar)
            }

            Text(post.authorName)
                .font(AppTypography.cardAuthorName)
                .foregroundStyle(AppColors.postDetailText)

            Spacer()

            if display.showsPostedDate {
                Text(post.formattedDate)
                    .font(AppTypography.cardDate)
                    .foregroundStyle(AppColors.postDetailSecondaryText)
            }
        }
    }

    private var tagLabel: some View {
        Text(post.tag)
            .font(AppTypography.cardTag)
            .foregroundStyle(AppColors.onTagText)
            .padding(.horizontal, AppSpacing.tagHorizontal)
            .padding(.vertical, AppSpacing.tagVertical)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.postTag)
            )
    }
}

#Preview("Post Detail") {
    PostDetailView(post: PostPreviewData.featured, display: .postDetail, dependencies: .live)
}

#Preview("Match Detail") {
    PostDetailView(post: PostPreviewData.match, display: .matchDetail, dependencies: .live)
}
