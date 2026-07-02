//
//  ProfileRegistrationValidatorTests.swift
//  matiapuTests
//

import XCTest
@testable import matiapu

final class ProfileRegistrationValidatorTests: XCTestCase {
    private var filledAddress: UserAddress {
        UserAddress(
            postalCode: "1820000",
            prefecture: "東京都",
            municipality: "調布市",
            streetAddress: "1-1-1"
        )
    }

    func testValidateCitizen_returnsNilWhenValid() {
        let error = ProfileRegistrationValidator.validateCitizen(
            lastName: "山田",
            firstName: "太郎",
            lastNameKana: "ヤマダ",
            firstNameKana: "タロウ",
            nickname: "たろう",
            address: filledAddress
        )

        XCTAssertNil(error)
    }

    func testValidateCitizen_requiresName() {
        let error = ProfileRegistrationValidator.validateCitizen(
            lastName: "",
            firstName: "太郎",
            lastNameKana: "ヤマダ",
            firstNameKana: "タロウ",
            nickname: "たろう",
            address: filledAddress
        )

        XCTAssertEqual(error, "氏名を入力してください。")
    }

    func testValidateStore_requiresDescriptionLength() {
        let error = ProfileRegistrationValidator.validateStore(
            storeName: "店舗",
            storeDescription: String(repeating: "あ", count: 49),
            phoneNumber: "0312345678",
            address: filledAddress
        )

        XCTAssertEqual(error, "店舗紹介は50文字以上で入力してください。")
    }

    func testValidateLegislator_requiresManifestoLength() {
        let error = ProfileRegistrationValidator.validateLegislator(
            lastName: "山田",
            firstName: "太郎",
            lastNameKana: "ヤマダ",
            firstNameKana: "タロウ",
            politicalParty: "無所属",
            manifesto: String(repeating: "あ", count: 49),
            address: filledAddress
        )

        XCTAssertEqual(error, "公約・活動方針は50文字以上で入力してください。")
    }
}
