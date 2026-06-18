//
//  MatchResult.swift
//  matiapu
//

import Foundation

enum MatchResult: Equatable {
    case matched(ChatConversation)
    case pending
}
