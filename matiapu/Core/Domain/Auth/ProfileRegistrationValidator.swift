//
//  ProfileRegistrationValidator.swift
//  matiapu
//

import Foundation

nonisolated enum ProfileRegistrationValidator {
    static func validateCitizen(
        lastName: String,
        firstName: String,
        lastNameKana: String,
        firstNameKana: String,
        nickname: String,
        address: UserAddress
    ) -> String? {
        guard !lastName.isEmpty, !firstName.isEmpty else {
            return "氏名を入力してください。"
        }
        guard !lastNameKana.isEmpty, !firstNameKana.isEmpty else {
            return "フリガナを入力してください。"
        }
        guard !nickname.isEmpty else {
            return "ニックネームを入力してください。"
        }
        guard address.isFilled else {
            return "住所を入力してください。"
        }
        return nil
    }

    static func validateStore(
        storeName: String,
        storeDescription: String,
        phoneNumber: String,
        address: UserAddress
    ) -> String? {
        guard !storeName.isEmpty else {
            return "店舗名を入力してください。"
        }
        guard storeDescription.count >= 50 else {
            return "店舗紹介は50文字以上で入力してください。"
        }
        guard phoneNumber.allSatisfy(\.isNumber), !phoneNumber.isEmpty, phoneNumber.count <= 15 else {
            return "店舗電話番号を半角数字15桁以内で入力してください。"
        }
        guard address.isFilled else {
            return "所在地を入力してください。"
        }
        return nil
    }

    static func validateLegislator(
        lastName: String,
        firstName: String,
        lastNameKana: String,
        firstNameKana: String,
        politicalParty: String,
        manifesto: String,
        address: UserAddress
    ) -> String? {
        guard !lastName.isEmpty, !firstName.isEmpty else {
            return "氏名を入力してください。"
        }
        guard !lastNameKana.isEmpty, !firstNameKana.isEmpty else {
            return "フリガナを入力してください。"
        }
        guard !politicalParty.isEmpty else {
            return "政党を入力してください。"
        }
        guard manifesto.count >= 50 else {
            return "公約・活動方針は50文字以上で入力してください。"
        }
        guard address.isFilled else {
            return "活動地域を入力してください。"
        }
        return nil
    }
}
