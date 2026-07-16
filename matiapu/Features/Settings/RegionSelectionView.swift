//
//  RegionSelectionView.swift
//  matiapu
//

import SwiftUI

struct RegionSelectionView: View {
    @Bindable var viewModel: RegionSelectionViewModel
    @Bindable var settingsViewModel: SettingsViewModel
    var onRegionSaved: () -> Void = {}

    @State private var isSaving = false
    @State private var errorMessage: String?

    private var currentArea: String {
        settingsViewModel.profile?.registeredArea ?? "未設定"
    }

    private var filteredPrefectures: [Prefecture] {
        viewModel.filteredPrefectures(matching: viewModel.searchText)
    }

    private var municipalityMatches: [MunicipalityCatalog.MunicipalityEntry] {
        viewModel.searchMunicipalities(matching: viewModel.searchText)
    }

    private var isPostalCodeSearchActive: Bool {
        PostalCodeLookup.isPostalCodeQuery(viewModel.searchText)
    }

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsSectionSpacing) {
                    currentAreaCard
                    SettingsSearchBar(
                        placeholder: "郵便番号で検索",
                        text: $viewModel.searchText,
                        keyboardType: .numberPad
                    )

                    if isPostalCodeSearchActive {
                        postalCodeSearchSection
                    }

                    if !municipalityMatches.isEmpty {
                        municipalitySearchResults
                    }

                    if !isPostalCodeSearchActive && municipalityMatches.isEmpty {
                        prefectureList
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.createPostField)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.top, AppSpacing.settingsContentTop)
                .padding(.bottom, AppSpacing.settingsTabBarInset)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .task {
            await settingsViewModel.loadProfile()
        }
    }

    private var currentAreaCard: some View {
        SettingsCard {
            Text("現在の設定：\(currentArea)")
                .font(AppTypography.settingsRegionStatus)
                .foregroundStyle(AppColors.settingsCardText)
                .frame(maxWidth: .infinity)
                .frame(height: AppSize.settingsRegionStatusCardHeight)
        }
    }

    @ViewBuilder
    private var postalCodeSearchSection: some View {
        if viewModel.isSearchingPostalCode {
            ProgressView()
                .tint(AppColors.onImageText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.profileGridLoadingVertical)
        } else if !viewModel.postalCodeResults.isEmpty {
            LazyVStack(spacing: AppSpacing.settingsListItemSpacing) {
                ForEach(viewModel.postalCodeResults) { match in
                    postalCodeResultCard(match)
                }
            }
        } else if let message = viewModel.postalCodeMessage {
            Text(message)
                .font(AppTypography.createPostField)
                .foregroundStyle(AppColors.onImageText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func postalCodeResultCard(_ match: PostalCodeArea) -> some View {
        Button {
            Task { await select(area: match.area) }
        } label: {
            SettingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.area)
                            .font(AppTypography.settingsMenuTitle)
                            .foregroundStyle(AppColors.settingsCardText)

                        Text(match.prefecture)
                            .font(AppTypography.createPostField)
                            .foregroundStyle(AppColors.settingsChevron)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.settingsChevron)
                }
                .padding(.horizontal, AppSpacing.settingsHorizontal)
                .padding(.vertical, AppSpacing.settingsMenuRowVertical)
            }
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private var municipalitySearchResults: some View {
        LazyVStack(spacing: AppSpacing.settingsListItemSpacing) {
            ForEach(municipalityMatches, id: \.self) { entry in
                Button {
                    Task { await select(area: entry.municipality.name) }
                } label: {
                    SettingsCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.municipality.name)
                                    .font(AppTypography.settingsMenuTitle)
                                    .foregroundStyle(AppColors.settingsCardText)

                                Text(entry.prefectureName)
                                    .font(AppTypography.createPostField)
                                    .foregroundStyle(AppColors.settingsChevron)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.settingsChevron)
                        }
                        .padding(.horizontal, AppSpacing.settingsHorizontal)
                        .padding(.vertical, AppSpacing.settingsMenuRowVertical)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
        }
    }

    private var prefectureList: some View {
        LazyVStack(spacing: AppSpacing.settingsListItemSpacing) {
            ForEach(filteredPrefectures) { prefecture in
                NavigationLink(value: SettingsDestination.municipalitySelection(prefectureName: prefecture.name)) {
                    SettingsMenuRow(title: prefecture.name)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func select(area: String) async {
        guard !isSaving else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await settingsViewModel.updateRegisteredArea(area)
            onRegionSaved()
        } catch {
            errorMessage = "地域の変更に失敗しました。もう一度お試しください。"
        }
    }
}
