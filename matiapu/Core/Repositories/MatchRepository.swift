//
//  MatchRepository.swift
//  matiapu
//

import Foundation

protocol MatchRepository: Sendable {
    /// 議員が市民の投稿にいいね（Post画面）
    func recordLegislatorLike(legislatorId: String, post: Post) async throws -> MatchResult?
    /// 市民が議員にいいね（Match画面）
    func recordCitizenLike(
        citizenUserId: String,
        legislatorId: String,
        legislatorName: String
    ) async throws -> MatchResult?
    /// 市民が議員をスキップ（Match画面）
    func recordCitizenBad(citizenUserId: String, legislatorId: String) async throws
}

final class MockMatchRepository: MatchRepository, @unchecked Sendable {
    private struct Pair: Hashable {
        let legislatorId: String
        let citizenUserId: String
    }

    private let lock = NSLock()
    private let chatRepository: MockChatRepository
    private var legislatorLikes = Set<Pair>()
    private var citizenLikes = Set<Pair>()

    init(chatRepository: MockChatRepository) {
        self.chatRepository = chatRepository
        // デモ用: 田中議員がすでに市民の投稿にいいね済み
        legislatorLikes.insert(
            Pair(legislatorId: MockMatching.demoLegislatorId, citizenUserId: MockMatching.demoCitizenId)
        )
    }

    func recordLegislatorLike(legislatorId: String, post: Post) async throws -> MatchResult? {
        guard let citizenUserId = post.authorUserId else { return nil }

        return locked {
            legislatorLikes.insert(Pair(legislatorId: legislatorId, citizenUserId: citizenUserId))
            return resolveMatch(
                legislatorId: legislatorId,
                citizenUserId: citizenUserId,
                legislatorName: legislatorName(for: legislatorId)
            )
        }
    }

    func recordCitizenLike(
        citizenUserId: String,
        legislatorId: String,
        legislatorName: String
    ) async throws -> MatchResult? {
        locked {
            citizenLikes.insert(Pair(legislatorId: legislatorId, citizenUserId: citizenUserId))
            return resolveMatch(
                legislatorId: legislatorId,
                citizenUserId: citizenUserId,
                legislatorName: legislatorName
            )
        }
    }

    func recordCitizenBad(citizenUserId: String, legislatorId: String) async throws {
        locked {
            let pair = Pair(legislatorId: legislatorId, citizenUserId: citizenUserId)
            legislatorLikes.remove(pair)
            citizenLikes.remove(pair)
        }
    }

    private func resolveMatch(
        legislatorId: String,
        citizenUserId: String,
        legislatorName: String
    ) -> MatchResult? {
        let pair = Pair(legislatorId: legislatorId, citizenUserId: citizenUserId)
        let legislatorLiked = legislatorLikes.contains(pair)
        let citizenLiked = citizenLikes.contains(pair)

        guard legislatorLiked, citizenLiked else {
            return .pending
        }

        if let existing = chatRepository.existingConversation(partnerId: legislatorId) {
            return .matched(existing)
        }

        let conversation = chatRepository.createMatchedConversation(
            partnerId: legislatorId,
            partnerName: legislatorName
        )
        return .matched(conversation)
    }

    private func legislatorName(for legislatorId: String) -> String {
        switch legislatorId {
        case "leg-1": return "名前名前名前"
        case MockMatching.demoLegislatorId: return MockMatching.demoLegislatorName
        case "leg-3": return "佐藤 花子"
        case "leg-4": return "鈴木 一郎"
        default: return "議員"
        }
    }

    private func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}
