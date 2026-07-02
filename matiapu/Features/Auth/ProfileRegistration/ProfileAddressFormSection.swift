//
//  ProfileAddressFormSection.swift
//  matiapu
//

import SwiftUI

struct ProfileAddressFormSection: View {
    let title: String
    @Binding var address: UserAddress
    @State private var isSearching = false
    @State private var searchMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileFieldLabel(title: title, isRequired: true)

            postalCodeRow

            if let searchMessage {
                Text(searchMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }

            prefecturePicker

            if !address.municipality.isEmpty {
                municipalityDisplay
            }

            ProfileTextField(
                title: "番地",
                text: $address.streetAddress,
                prompt: "例：神南1-1-1",
                isRequired: true
            )

            ProfileTextField(
                title: "建物名・部屋番号（任意）",
                text: Binding(
                    get: { address.building ?? "" },
                    set: { address.building = $0.nilIfEmpty }
                ),
                prompt: "例：マチアプビル 201"
            )
        }
    }

    private var postalCodeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileFieldLabel(title: "郵便番号", isRequired: true)

            HStack(alignment: .center, spacing: 12) {
                TextField(
                    "",
                    text: $address.postalCode,
                    prompt: Text("1234567").foregroundStyle(AppColors.authPlaceholder)
                )
                .font(AppTypography.authField)
                .foregroundStyle(AppColors.authHeading)
                .keyboardType(.numberPad)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.authInputBackground)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppColors.authInputBorder, lineWidth: 1)
                )

                Button {
                    Task { await searchPostalCode() }
                } label: {
                    Group {
                        if isSearching {
                            ProgressView()
                                .tint(AppColors.authPrimaryAction)
                        } else {
                            Text("住所検索")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundStyle(AppColors.authPrimaryAction)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppColors.authInputBackground)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppColors.authInputBorder, lineWidth: 1)
                    )
                }
                .disabled(isSearching)
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var municipalityDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileFieldLabel(title: "市区町村", isRequired: true)

            Text(address.municipality)
                .font(AppTypography.authField)
                .foregroundStyle(AppColors.authHeading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.authInputBackground.opacity(0.7))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppColors.authInputBorder, lineWidth: 1)
                )
        }
    }

    private var prefecturePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileFieldLabel(title: "都道府県", isRequired: true)

            Menu {
                ForEach(Prefecture.all) { prefecture in
                    Button(prefecture.name) {
                        address.prefecture = prefecture.name
                    }
                }
            } label: {
                HStack {
                    Text(address.prefecture.isEmpty ? "選択してください" : address.prefecture)
                        .font(AppTypography.authField)
                        .foregroundStyle(
                            address.prefecture.isEmpty ? AppColors.authPlaceholder : AppColors.authHeading
                        )
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.authIconMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.authInputBackground)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppColors.authInputBorder, lineWidth: 1)
                )
            }
        }
    }

    private func searchPostalCode() async {
        isSearching = true
        searchMessage = nil
        defer { isSearching = false }

        do {
            let results = try await PostalCodeLookup.search(postalCode: address.postalCode)
            guard let first = results.first else {
                searchMessage = PostalCodeLookupError.notFound.errorDescription
                return
            }
            address.prefecture = first.prefecture
            address.municipality = first.area
        } catch let error as PostalCodeLookupError {
            searchMessage = error.errorDescription
        } catch {
            searchMessage = PostalCodeLookupError.serviceUnavailable.errorDescription
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
