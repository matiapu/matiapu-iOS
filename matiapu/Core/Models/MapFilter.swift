//
//  MapFilter.swift
//  matiapu
//

import Foundation

enum MapFilter: CaseIterable, Hashable {
    case disaster
    case road
    case shop
    case bulletin

    var title: String {
        switch self {
        case .disaster: return "災害"
        case .road: return "道路"
        case .shop: return "お店"
        case .bulletin: return "通報"
        }
    }

    func matches(post: Post) -> Bool {
        post.tag == title
    }
}
