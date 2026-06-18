//
//  UserRole.swift
//  matiapu
//

import Foundation

enum UserRole: String, Hashable {
    case citizen
    case legislator
}

enum MockMatching {
    /// Post画面での議員いいねをシミュレートするモック議員ID（田中 太郎）
    static let demoLegislatorId = "leg-2"
    static let demoLegislatorName = "田中 太郎"
    static let demoCitizenId = "citizen-1"
}
