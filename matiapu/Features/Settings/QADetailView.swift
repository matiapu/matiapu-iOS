//
//  QADetailView.swift
//  matiapu
//

import SwiftUI

struct QADetailView: View {
    @State private var viewModel: QADetailViewModel

    init(questionId: String, viewModel: QADetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsSectionSpacing) {
                    if viewModel.isLoading && viewModel.question == nil {
                        ProgressView()
                            .tint(AppColors.onImageText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                    } else if let question = viewModel.question {
                        questionSection(question)
                        answersSection
                    } else {
                        ContentUnavailableView(
                            "質問が見つかりません",
                            systemImage: "questionmark.circle",
                            description: Text(viewModel.errorMessage ?? "")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.profileGridLoadingVertical)
                    }
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.load()
        }
    }

    private func questionSection(_ question: QAQuestion) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
                Text(question.title)
                    .font(AppTypography.settingsHeaderTitle)
                    .foregroundStyle(AppColors.settingsCardText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(question.contentText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(AppColors.settingsCardText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(question.prefecture) · \(question.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppTypography.cardDate)
                    .foregroundStyle(AppColors.postDetailSecondaryText)
            }
            .padding(AppSpacing.settingsHeaderCardPadding)
        }
    }

    @ViewBuilder
    private var answersSection: some View {
        if viewModel.answers.isEmpty {
            SettingsCard {
                Text("まだ回答はありません")
                    .font(AppTypography.cardBody)
                    .foregroundStyle(AppColors.postDetailSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.settingsHeaderCardPadding)
            }
        } else {
            ForEach(viewModel.answers) { answer in
                SettingsCard {
                    VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
                        Text(answer.contentText)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(AppColors.settingsCardText)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(answer.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTypography.cardDate)
                            .foregroundStyle(AppColors.postDetailSecondaryText)
                    }
                    .padding(AppSpacing.settingsHeaderCardPadding)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        QADetailView(
            questionId: "mock-qa-1",
            viewModel: AppViewModelFactory.qaDetail(
                questionId: "mock-qa-1",
                dependencies: .live
            )
        )
    }
}
