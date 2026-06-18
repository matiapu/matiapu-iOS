//
//  LikedPostSortOrder.swift
//  matiapu
//

import Foundation

enum LikedPostSortOrder: String, CaseIterable, Identifiable {
  case newestFirst
  case oldestFirst

  var id: String { rawValue }

  var title: String {
    switch self {
    case .newestFirst:
      return "新しい順"
    case .oldestFirst:
      return "古い順"
    }
  }
}
