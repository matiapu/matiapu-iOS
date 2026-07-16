//
//  MunicipalitySelectionView.swift
//  matiapu
//

import SwiftUI

struct MunicipalitySelectionView: View {
    let prefectureName: String
    @Bindable var settingsViewModel: SettingsViewModel
    var onRegionSaved: () -> Void = {}

    @State private var searchText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var municipalities: [Municipality] {
        let all = MunicipalityStore.shared.municipalities(for: prefectureName)
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter { $0.name.contains(trimmed) }
    }

    var body: some View {
        SettingsScreenLayout {
            ScrollView {
                VStack(spacing: AppSpacing.settingsSectionSpacing) {
                    SettingsSearchBar(placeholder: "市区町村で検索", text: $searchText)
                    municipalityList

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
        .navigationTitle(prefectureName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var municipalityList: some View {
        LazyVStack(spacing: AppSpacing.settingsListItemSpacing) {
            ForEach(municipalities) { municipality in
                Button {
                    Task { await select(municipality) }
                } label: {
                    SettingsMenuRow(title: municipality.name)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
        }
    }

    private func select(_ municipality: Municipality) async {
        guard !isSaving else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await settingsViewModel.updateRegisteredArea(municipality.name)
            onRegionSaved()
        } catch {
            errorMessage = "地域の変更に失敗しました。もう一度お試しください。"
        }
    }
}
