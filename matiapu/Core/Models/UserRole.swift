//
//  UserRole.swift
//  matiapu
//

import Foundation

enum UserRole: String, Hashable, CaseIterable, Identifiable, Codable {
    case citizen
    case store
    case legislator

    var id: String { rawValue }

    var title: String {
        switch self {
        case .citizen: "市民"
        case .store: "店舗"
        case .legislator: "議員"
        }
    }

    var profileRegistrationTitle: String {
        switch self {
        case .citizen: "プロフィール情報入力"
        case .store: "プロフィール情報入力"
        case .legislator: "プロフィール情報入力"
        }
    }

    var profileRegistrationSubtitle: String {
        switch self {
        case .citizen: "あなたの基本情報を設定してください。"
        case .store: "店舗の基本情報を設定してください。"
        case .legislator: "議員活動を伝えるための詳細情報を入力してください"
        }
    }
}

enum MockMatching {
    /// Post画面での議員いいねをシミュレートするモック議員ID（田中 太郎）
    static let demoLegislatorId = "leg-2"
    static let demoLegislatorName = "田中 太郎"
    static let demoCitizenId = "citizen-1"
}
