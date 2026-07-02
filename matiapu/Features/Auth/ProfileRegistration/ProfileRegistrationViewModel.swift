//
//  ProfileRegistrationViewModel.swift
//  matiapu
//

import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class ProfileRegistrationViewModel {
    private(set) var role: UserRole
    private(set) var email: String = ""
    private(set) var isProcessing = false
    private(set) var didComplete = false
    var errorMessage: String?

    // Citizen / Legislator shared
    var lastName = ""
    var firstName = ""
    var lastNameKana = ""
    var firstNameKana = ""
    var nickname = ""
    var birthYear = "1995"
    var birthMonth = "1"
    var birthDay = "1"

    // Store
    var storeName = ""
    var storeDescription = ""
    var phoneNumber = ""

    // Legislator
    var politicalParty = ""
    var manifesto = ""

    // Shared
    var address = UserAddress()
    var profileImage: UIImage?

    private let completeProfile: CompleteProfileUseCase

    init(completeProfile: CompleteProfileUseCase, role: UserRole) {
        self.completeProfile = completeProfile
        self.role = role
    }

    func loadEmail() async {
        email = await completeProfile.loadRegistrationEmail()
    }

    func updateRole(_ role: UserRole) async {
        self.role = role
        try? await completeProfile.updateRegistrationRole(role)
    }

    func submit() async {
        guard let input = buildInput() else { return }

        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try await completeProfile.completeProfile(input)
            didComplete = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildInput() -> ProfileCompletionInput? {
        switch role {
        case .citizen:
            if let validationError = ProfileRegistrationValidator.validateCitizen(
                lastName: lastName,
                firstName: firstName,
                lastNameKana: lastNameKana,
                firstNameKana: firstNameKana,
                nickname: nickname,
                address: address
            ) {
                errorMessage = validationError
                return nil
            }
            return .citizen(
                CitizenProfileInput(
                    lastName: lastName,
                    firstName: firstName,
                    lastNameKana: lastNameKana,
                    firstNameKana: firstNameKana,
                    nickname: nickname,
                    birthDate: formattedBirthDate,
                    address: address,
                    profileImage: profileImage
                )
            )
        case .store:
            if let validationError = ProfileRegistrationValidator.validateStore(
                storeName: storeName,
                storeDescription: storeDescription,
                phoneNumber: phoneNumber,
                address: address
            ) {
                errorMessage = validationError
                return nil
            }
            return .store(
                StoreProfileInput(
                    storeName: storeName,
                    storeDescription: storeDescription,
                    phoneNumber: phoneNumber,
                    address: address,
                    profileImage: profileImage
                )
            )
        case .legislator:
            if let validationError = ProfileRegistrationValidator.validateLegislator(
                lastName: lastName,
                firstName: firstName,
                lastNameKana: lastNameKana,
                firstNameKana: firstNameKana,
                politicalParty: politicalParty,
                manifesto: manifesto,
                address: address
            ) {
                errorMessage = validationError
                return nil
            }
            return .legislator(
                LegislatorProfileInput(
                    lastName: lastName,
                    firstName: firstName,
                    lastNameKana: lastNameKana,
                    firstNameKana: firstNameKana,
                    politicalParty: politicalParty,
                    manifesto: manifesto,
                    address: address,
                    profileImage: profileImage
                )
            )
        }
    }

    private var formattedBirthDate: String {
        String(format: "%04d-%02d-%02d", Int(birthYear) ?? 1995, Int(birthMonth) ?? 1, Int(birthDay) ?? 1)
    }
}

#if DEBUG
extension ProfileRegistrationViewModel {
    static var preview: ProfileRegistrationViewModel {
        let viewModel = ProfileRegistrationViewModel(
            completeProfile: CompleteProfileUseCase(authRepository: MockAuthRepository()),
            role: .citizen
        )
        viewModel.email = "yamada.t@example.com"
        return viewModel
    }
}
#endif
