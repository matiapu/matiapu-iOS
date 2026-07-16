//
//  QAListView.swift
//  matiapu
//

import SwiftUI

struct QAListView: View {
    @Bindable var viewModel: QAViewModel

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsSectionSpacing) {
                    headerCard
                    questionList
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.loadQuestions()
        }
    }

    private var headerCard: some View {
        SettingsCard {
            Text("よくある質問")
                .font(AppTypography.settingsHeaderTitle)
                .foregroundStyle(AppColors.settingsCardText)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.settingsHeaderCardPadding)
        }
    }

    @ViewBuilder
    private var questionList: some View {
        if viewModel.isLoading && viewModel.questions.isEmpty {
            ProgressView()
                .tint(AppColors.onImageText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.profileGridLoadingVertical)
        } else if viewModel.questions.isEmpty {
            ContentUnavailableView(
                "質問はありません",
                systemImage: "questionmark.circle",
                description: Text(viewModel.errorMessage ?? "まだQ&Aが登録されていません")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.profileGridLoadingVertical)
        } else {
            LazyVStack(spacing: AppSpacing.settingsCardSpacing) {
                ForEach(viewModel.questions) { question in
                    NavigationLink(value: SettingsDestination.qaDetail(questionId: question.id)) {
                        questionCard(question)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func questionCard(_ question: QAQuestion) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppSpacing.createPostLabelSpacing) {
                Text(question.title)
                    .font(AppTypography.settingsMenuTitle)
                    .foregroundStyle(AppColors.settingsCardText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(question.prefecture)
                    .font(AppTypography.cardDate)
                    .foregroundStyle(AppColors.postDetailSecondaryText)
            }
            .padding(.horizontal, AppSpacing.settingsHorizontal)
            .padding(.vertical, AppSpacing.settingsMenuRowVertical)
            .frame(minHeight: AppSize.settingsMenuRowMinHeight, alignment: .leading)
        }
    }
}
